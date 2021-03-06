defmodule EvercamMedia.CameraController do
  use Phoenix.Controller
  alias EvercamMedia.Snapshot.WorkerSupervisor
  alias EvercamMedia.Snapshot.Worker
  alias EvercamMedia.Repo
  import EvercamMedia.Snapshot
  require Logger

  def update(conn, %{"id" => exid, "token" => token}) do
    try do
      [_, _, _, _, _] = decode_request_token(token)
      Logger.info "Camera update for #{exid}"
      camera = Camera.by_exid(exid) |> Repo.one
      worker = exid |> String.to_atom |> Process.whereis

      case worker do
        nil ->
          start_worker(camera)
        _ ->
          update_worker(worker, camera)
      end
      conn
      |> send_resp(200, "Camera update request received.")
    rescue
      e ->
        Logger.info "Camera update for #{exid} requested with invalid token."
        conn
        |> send_resp(500, "error.")
    end
  end


  defp start_worker(camera) do
    WorkerSupervisor.start_worker(camera)
  end

  defp update_worker(worker, camera) do
    case WorkerSupervisor.get_config(camera) do
      {:ok, settings} ->
        Logger.info "Updating worker for #{settings.config.camera_exid}"
        Worker.update_config(worker, settings)
      {:error, message} ->
        Logger.info "Skipping camera worker update as the host is invalid"
    end
  end

end
