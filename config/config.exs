# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :lanttern,
  ecto_repos: [Lanttern.Repo],
  content_security_policy: System.get_env("CONTENT_SECURITY_POLICY"),
  default_timezone: System.get_env("TIMEZONE", "America/Sao_Paulo"),
  supabase_api_key: System.get_env("SUPABASE_PROJECT_API_KEY"),
  supabase_project_url: System.get_env("SUPABASE_PROJECT_URL")

query_args = ["SET pg_trgm.word_similarity_threshold = 0.4", []]

config :lanttern, Lanttern.Repo,
  after_connect: {Postgrex, :query!, query_args},
  types: Lanttern.PostgrexTypes

# Configures the endpoint
config :lanttern, LantternWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: LantternWeb.ErrorHTML, json: LantternWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Lanttern.PubSub,
  live_view: [signing_salt: "Oqn9jf/6"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :lanttern, Lanttern.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  lanttern: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/*  --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (use npm version)
config :tailwind,
  version: "4.1.11",
  lanttern: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  handle_otp_reports: true,
  handle_sasl_reports: true

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Authentication config
config :lanttern, LantternWeb.UserAuth, google_client_id: System.get_env("GOOGLE_CLIENT_ID")

# ex_openai config
config :ex_openai,
  api_key: System.get_env("OPENAI_API_KEY"),
  organization_key: System.get_env("OPENAI_ORGANIZATION_KEY"),
  http_options: [
    # 60 seconds timeout
    recv_timeout: 60_000
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
