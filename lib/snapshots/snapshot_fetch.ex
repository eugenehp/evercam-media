defmodule EvercamMedia.Snapshot do
  alias EvercamMedia.Repo
  alias EvercamMedia.S3
  alias EvercamMedia.HTTPClient
  alias EvercamMedia.Motiondetection
  require Logger

  def fetch(url, ":") do
    HTTPotion.get(url).body
  end

  def fetch(url, auth) do
    [username, password] = String.split(auth, ":")
    request = HTTPotion.get(url, [basic_auth: {username, password}])
    if request.status_code == 401 do
      digest_request = Porcelain.shell("curl --max-time 15 --digest --user '#{auth}' #{url}")
      digest_request.out
    else
      request.body
    end
  end

  def fallback do
    path = Application.app_dir(:evercam_media)
    path = Path.join path, "priv/static/images/unavailable.jpg"
    File.read! path
  end

  def check_camera(args, retry \\ true) do
    try do
      [username, password] = String.split(args[:auth], ":")
      vendor_exid = Camera.get_vendor_exid_by_camera_exid(args[:camera_id])
      response = case vendor_exid do
        "samsung" -> HTTPClient.get(:digest_auth, args[:url], username, password)
        "ubiquiti" -> HTTPClient.get(:cookie_auth, args[:url], username, password)
        _ -> HTTPClient.get(:basic_auth, args[:url], username, password)
      end
      response = response.body
      check_jpg(response)
      broadcast_snapshot(args[:camera_id], response)
      store(args[:camera_id], response, "Evercam Proxy")
    rescue
      error in [FunctionClauseError] ->
        error_handler(error)
      error in [SnapshotError] ->
        Logger.info "#{error.message} for camera '#{args[:camera_id]}'"
      error in [HTTPotion.HTTPError] ->
        case error.message do
          "req_timedout" ->
            if retry do
              check_camera(args, false)
            end
          _message ->
            timestamp = Ecto.DateTime.utc
            update_camera_status(args[:camera_id], timestamp, false)
        end
      _error ->
        error_handler(_error)
    end
  end

  def store(camera_id, image, notes \\ "", count \\ 1) do
    try do
      snap_timestamp = Ecto.DateTime.utc
      file_timestamp = Timex.Date.convert Timex.Date.now, :secs
      file_path = "/#{camera_id}/snapshots/#{file_timestamp}.jpg"

      directory_path  = "/tmp/#{camera_id}"
      last_file_path  = "#{directory_path}/last.jpg"
      tmp_path        = "#{directory_path}/#{file_timestamp}.jpg"

      if File.exists? directory_path  do
        Logger.info "Already created #{directory_path}"
      else
        File.mkdir! directory_path
      end
      
      File.write! tmp_path, image
      Logger.info "File written to #{tmp_path} "

      if File.exists? last_file_path do
        motiondetection_rate = motion_detection(tmp_path, last_file_path)
      else
        motiondetection_rate = 0
      end

      update_camera_status(camera_id, snap_timestamp, true)

      if System.get_env("EVERCAM_LOCAL") do
        save_snapshot_record(camera_id, notes, snap_timestamp, file_timestamp, File.exists?(tmp_path), file_path, "local", motiondetection_rate)
      else
        if File.exists? tmp_path do
          File.rm! tmp_path
        end
        S3.upload(camera_id, image, file_path, file_timestamp)
        save_snapshot_record(camera_id, notes, snap_timestamp, file_timestamp, S3.exists?(file_path), file_path, "S3", motiondetection_rate)
      end

      if File.exists? last_file_path do
        File.rm! last_file_path
      end
      File.write! last_file_path, image

      ConCache.put(:cache, camera_id, %{image: image, timestamp: file_timestamp, notes: notes})
      Logger.info "Uploaded snapshot '#{file_timestamp}' for camera '#{camera_id}' into '#{tmp_path}'"
      %{camera_id: camera_id, image: image, timestamp: file_timestamp, notes: notes}
    rescue
      error in [Postgrex.Error] ->
        Logger.warn "Postgrex Error: #{error.postgres[:message]}"
      _error ->
        :timer.sleep 1_000
        error_handler(_error)
        Logger.warn "Retrying S3 upload for camera '#{camera_id}', try ##{count}"
        if count < 10 do
          store(camera_id, image, notes, count+1)
        end
    end
  end

  def motion_detection(current_image, previous_image) do
    {:ok,image1} =  File.read previous_image
    {:ok,image2} =  File.read current_image

    {:ok,{width1,height1,bytes1}} = Motiondetection.load(image1)
    {:ok,{_width2,_height2,bytes2}} = Motiondetection.load(image2)

    # use this to parallel the process, and play with the quality and performance
    position  = width1*height1*3 # end position for a process
    minPosition = 0 # start position for a process in a binary list of pixesl {R,G,B}
    step    = 2 # check each 2nd pixel
    min     = 30 # change between previous and current image should be at least
 
    md = Motiondetection.compare(bytes1, bytes2, position, minPosition, step, min)
    float = Elixir.Float.ceil(100 * md)
    string = Elixir.Float.to_string float
    {result,_} = Elixir.Integer.parse string

    IO.puts "Comparison result of motion_detection is #{result}"
    result
  end

  def check_jpg(response) do
    if String.valid?(response) do
      raise SnapshotError
    end
  end

  def error_handler(error) do
    Logger.error inspect(error)
    Logger.error Exception.format_stacktrace System.stacktrace
  end

  def save_snapshot_record(camera_id, _, _, file_timestamp, _, _, _, _, count) when count >= 10 do
    Logger.error "Snapshot '#{file_timestamp}' for '#{camera_id}' not found on S3, aborting."
  end

  def save_snapshot_record(camera_id, notes, snap_timestamp, file_timestamp, true, file_path, type, motiondetection_rate, _) do
    camera = Repo.one! Camera.by_exid(camera_id)
    Repo.insert %Snapshot{camera_id: camera.id, data: type, notes: notes, created_at: snap_timestamp, motiondetection: motiondetection_rate}
    update_thumbnail_url(camera_id, file_path, type)
  end

  def save_snapshot_record(camera_id, notes, snap_timestamp, file_timestamp, false, file_path, type, motiondetection_rate, count \\ 0) when count < 10 do
    Logger.warn "Snapshot '#{file_timestamp}' for '#{camera_id}' not found on #{type}, try ##{count}"
    :timer.sleep 1000
    save_snapshot_record(camera_id, notes, snap_timestamp, file_timestamp, S3.exists?(file_path), file_path, type, motiondetection_rate, count + 1)
  end

  def update_thumbnail_url(camera_id, file_path, type) do
    camera = Repo.one! Camera.by_exid(camera_id)

    if type == "S3" do
      camera = %{camera | thumbnail_url: S3.file_url(file_path)}
    else
      # http://localhost:4000/v1/cameras/phony_camera/snapshots/something_else.jpg returns /tmp/phony_camera/something_else.jpg
      camera = %{camera | thumbnail_url: "http://localhost:4000/v1/cameras#{file_path}"}
    end
    Repo.update camera
  end

  def update_camera_status(camera_id, timestamp, status) do
    camera = Repo.one! Camera.by_exid(camera_id)
    camera_is_online = camera.is_online
    camera = construct_camera(camera, timestamp, status, camera_is_online == status)
    Repo.update camera

    unless camera_is_online == status do
      try do
        log_camera_status(camera.id, status, timestamp)
      rescue
        _error ->
          error_handler(_error)
      end
      invalidate_cache(camera_id)
    end
  end

  def invalidate_cache(camera_id) do
    Exq.Enqueuer.enqueue(
      :exq_enqueuer,
      "cache",
      "Evercam::CacheInvalidationWorker",
      camera_id
    )
  end

  def broadcast_snapshot(camera_id, image) do
    EvercamMedia.Endpoint.broadcast(
      "cameras:#{camera_id}",
      "snapshot-taken",
      %{image: Base.encode64(image)}
    )
  end

  def log_camera_status(camera_id, true, timestamp) do
    Repo.insert %CameraActivity{camera_id: camera_id, action: "online", done_at: timestamp}
  end

  def log_camera_status(camera_id, false, timestamp) do
    Repo.insert %CameraActivity{camera_id: camera_id, action: "offline", done_at: timestamp}
  end

  defp construct_camera(camera, timestamp, _, true) do
    %{camera | last_polled_at: timestamp}
  end

  defp construct_camera(camera, timestamp, false, false) do
    %{camera | last_polled_at: timestamp, is_online: false}
  end

  defp construct_camera(camera, timestamp, true, false) do
    %{camera | last_polled_at: timestamp, is_online: true, last_online_at: timestamp}
  end

  def decode_request_token(token) do
    {_, encrypted_message} = Base.url_decode64(token)
    message = :crypto.block_decrypt(
      :aes_cbc256,
      System.get_env["SNAP_KEY"],
      System.get_env["SNAP_IV"],
      encrypted_message
    )
    String.split(message, "|")
  end
end

defmodule SnapshotError do
  defexception message: "Response isn't an image"
end
