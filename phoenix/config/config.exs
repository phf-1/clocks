# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :clocks,
  ecto_repos: [Clocks.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :clocks, ClocksWeb.Endpoint,
  url: [host: "localhost"],

  # [[id:eb404cfc-7d96-4a09-bc36-d27597e937f1]]
  adapter: Bandit.PhoenixAdapter,

  # [[id:4f602ea4-697e-47d2-befb-dcd3ff79f212]]
  render_errors: [
    formats: [html: ClocksWeb.ErrorHTML, json: ClocksWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Clocks.PubSub,
  live_view: [signing_salt: "VPAwCmpr"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :clocks, Clocks.GenServer.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  clocks: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  clocks: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
         ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :clocks, Clocks.Auth.Token,
  secret: System.get_env("JWT_SECRET") || "dev-secret-change-in-prod"

# [[id:1228a3b7-6b81-4698-b046-cf657657d079]]
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
