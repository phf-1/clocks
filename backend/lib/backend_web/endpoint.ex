defmodule BackendWeb.Endpoint do
  @moduledoc """
  [[id:a1c93ee0-a90d-46a7-8845-9dfb488082e8][Id]]
  """

  # [[id:4bb3a68e-3d65-4335-b09e-324d55d6f2ef]]
  use Phoenix.Endpoint, otp_app: :backend

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_backend_key",
    signing_salt: "t/hoaokm",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # TODO(de80): in prod
  # plug CORSPlug,
  #      origin: ["https://your-frontend-origin.com"],
  #      methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  #      headers: ["Content-Type", "Authorization", "Accept"]

  # TODO(de80): in dev
  plug CORSPlug,
       origin: "*",
       methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
       headers: ["Content-Type", "Authorization", "Accept"]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :backend,
    gzip: false,
    only: BackendWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :backend
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  # [[id:b37be485-dd68-4c57-9bb4-76b62a6dd2dc][Id]]
  # https://hexdocs.pm/plug/Plug.Parsers.html
  plug Plug.Parsers,
    pass: ["text/html", "application/pdf", "image/jpeg", "application/json"],
    parsers: [
      :urlencoded,

      # [[id:f51fabe4-4846-4903-988e-32c7dbab4966][Id]]
      {:multipart, length: 10_000_000},
      :json
    ],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  # [[id:b95d3d95-cbf1-442c-bf52-0b049373a9fe][router]]
  plug BackendWeb.Router
end
