defmodule EvercamMedia.Endpoint do
  use Phoenix.Endpoint, otp_app: :evercam_media

  socket "/ws", EvercamMedia.UserSocket

  # Serve at "/" the given assets from "priv/static" directory
  plug Plug.Static,
    at: "/", from: :evercam_media, gzip: false,
    only: ~w(css images js favicon.ico robots.txt)

  plug Plug.Logger

  # Code reloading will only work if the :code_reloader key of
  # the :phoenix application is set to true in your config file.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  plug Plug.Session,
    store: :cookie,
    key: "_media_key",
    signing_salt: "sZRQyVW1"

  plug EvercamMedia.Router  
end
