import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

config :lanttern,
  content_security_policy: "self",
  default_timezone: "America/Sao_Paulo",
  supabase_api_key: "eyKbGciOiJua25XVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsnZpY2VfQ.ORhZAo0J1nNc",
  supabase_project_url: "https://example.supabase.co"

static_url_path =
  try do
    {windows_static_path, 0} = System.cmd("wslpath", ["-aw", "priv/static"])

    windows_static_path
    |> String.trim()
    |> String.trim_leading("\\")
    |> String.replace("\\", "/")
    |> then(&Kernel.<>("file://", &1))
  rescue
    # revert to default path if command not found, else re-raise the error
    e in ErlangError -> if e.original == :enoent, do: "/", else: reraise(e, __STACKTRACE__)
  end

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :lanttern, Lanttern.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "lanttern_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :lanttern, LantternWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "3ROrxoxhmKjx77ulZ7KoLqR9z59v1nN0fizIVaIhqMf9O6NRZAdUYuYhOM9Bmln/",
  server: false,
  static_url: [host: "localhost", path: static_url_path]

# In test we don't send emails.
config :lanttern, Lanttern.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :phoenix_test, :endpoint, LantternWeb.Endpoint
