# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :lanttern,
  ecto_repos: [Lanttern.Repo]

query_args = ["SET pg_trgm.word_similarity_threshold = 0.4", []]

config :lanttern, Lanttern.Repo, after_connect: {Postgrex, :query!, query_args}

# Configures the endpoint
config :lanttern, LantternWeb.Endpoint,
  url: [host: "localhost"],
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
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
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
  metadata: [:request_id],
  handle_otp_reports: true,
  handle_sasl_reports: true

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Git hooks
if Mix.env() == :dev do
  config :git_hooks,
    auto_install: true,
    verbose: true,
    hooks: [
      pre_commit: [
        tasks: [
          {:cmd, "mix clean"},
          {:cmd, "mix compile --warnings-as-errors"},
          {:cmd, "mix test"}
        ]
      ]
    ]
end

# Authentication config
config :lanttern, LantternWeb.UserAuth, google_client_id: System.get_env("GOOGLE_CLIENT_ID")

# Flop
config :flop, repo: Lanttern.Repo

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
