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

# Configure Phoenix scopes
config :lanttern, :scopes,
  school: [
    default: true,
    module: Lanttern.Identity.Scope,
    assign_key: :current_scope,
    access_path: [:school_id],
    schema_key: :school_id,
    schema_type: :id,
    schema_table: :schools
  ],
  user: [
    module: Lanttern.Identity.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users
  ]

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
  version_check: false,
  lanttern: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ],
  path: Path.expand("../assets/node_modules/.bin/tailwindcss", __DIR__)

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
  organization_key: System.get_env("OPENAI_ORG_ID"),
  http_options: [
    # 60 seconds timeout
    recv_timeout: 60_000
  ]

# LangChain config
config :langchain, openai_key: System.get_env("OPENAI_API_KEY")
config :langchain, openai_org_id: System.get_env("OPENAI_ORG_ID")

# Oban config
config :lanttern, Oban,
  engine: Oban.Engines.Basic,
  queues: [cleanup: 1, ai: 10],
  repo: Lanttern.Repo,
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron,
     crontab: [
       # Run login code cleanup every hour
       {"0 * * * *", Lanttern.Workers.LoginCodeCleanupWorker}
     ]}
  ]

# Upload config
default_profile_picture_accept = ".jpg .jpeg .png .webp"
default_profile_picture_size = "3000000"
default_cover_accept = ".jpg .jpeg .png .webp"
default_cover_size = "5000000"
default_attachment_accept = "*"
default_attachment_size = "20000000"

profile_picture_accept_str =
  System.get_env("UPLOAD_PROFILE_PICTURE_ACCEPT", default_profile_picture_accept)

profile_picture_accept =
  if profile_picture_accept_str == "*", do: :any, else: String.split(profile_picture_accept_str)

cover_accept_str = System.get_env("UPLOAD_COVER_ACCEPT", default_cover_accept)

cover_accept =
  if cover_accept_str == "*", do: :any, else: String.split(cover_accept_str)

attachment_accept_str = System.get_env("UPLOAD_ATTACHMENT_ACCEPT", default_attachment_accept)

attachment_accept =
  if attachment_accept_str == "*", do: :any, else: String.split(attachment_accept_str)

config :lanttern, :uploads,
  profile_picture: [
    max_file_size:
      String.to_integer(
        System.get_env("UPLOAD_PROFILE_PICTURE_MAX_FILE_SIZE", default_profile_picture_size)
      ),
    accept: profile_picture_accept
  ],
  cover: [
    max_file_size:
      String.to_integer(System.get_env("UPLOAD_COVER_MAX_FILE_SIZE", default_cover_size)),
    accept: cover_accept
  ],
  attachment: [
    max_file_size:
      String.to_integer(
        System.get_env("UPLOAD_ATTACHMENT_MAX_FILE_SIZE", default_attachment_size)
      ),
    accept: attachment_accept
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
