defmodule EvercamMedia.Router do
  use EvercamMedia.Web, :router

  pipeline :browser do
    plug :accepts, ["html", "json", "jpg"]
    plug :fetch_session
    plug :fetch_flash
  end

  scope "/", EvercamMedia do
    pipe_through :browser

    get "/", PageController, :index

    post "/v1/cameras/test", SnapshotController, :test
    get "/v1/cameras/:id/live/snapshot", SnapshotController, :show
    get "/v1/cameras/:id/snapshots/:filename", SnapshotController, :show_local_file
    post "/v1/cameras/:id/recordings/snapshots", SnapshotController, :create

    get "/live/:camera_id/index.m3u8", StreamController, :hls
    get "/live/:camera_id/:filename", StreamController, :ts
    get "/on_play", StreamController, :rtmp
  end

  socket "/ws", EvercamMedia do
    channel "cameras:*", SnapshotChannel
  end
end
