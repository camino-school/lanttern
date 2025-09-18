defmodule Lanttern.MixProject do
  use Mix.Project

  def project do
    [
      app: :lanttern,
      version: "2025.8.22-alpha.72",
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test,
        "test.drop": :test
      ],
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Lanttern.Application, []},
      extra_applications: [:logger, :runtime_tools, :ssl]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.8.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.12"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1.3"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.2"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3.0", runtime: Mix.env() == :dev},
      {:swoosh, "~> 1.19"},
      {:finch, "~> 0.20"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},
      {:timex, "~> 3.0"},
      {:joken, "~> 2.5"},
      {:joken_jwks, "~> 1.6.0"},
      {:benchee, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.27", runtime: false},
      {:earmark, "~> 1.4"},
      {:nimble_csv, "~> 1.2"},
      {:supabase_potion, "~> 0.6"},
      {:supabase_storage, "~> 0.4"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:slugify, "~> 1.3"},
      {:image, "~> 0.37"},
      {:ex_openai, "~> 1.8.0-beta"},
      {:tidewave, "~> 0.1.10", only: :dev},
      {:excoveralls, "~> 0.18", only: :test},
      {:phoenix_test, "~> 0.7.1", only: :test, runtime: false},
      {:ex_machina, "~> 2.8.0", only: :test},
      {:ex_cldr, "~> 2.37"},
      {:ex_cldr_dates_times, "~> 2.0"},
      {:mimic, "~> 1.12", only: :test},
      {:multipart, "~> 0.4.0"},
      {:usage_rules, "~> 0.1", only: [:dev]},
      {:igniter, "~> 0.6", only: [:dev]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "setup.no-ecto": ["deps.get", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test --cover"],
      "test.drop": ["ecto.drop", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["cmd --cd assets npm i", "tailwind lanttern", "esbuild lanttern"],
      "assets.deploy": [
        "cmd --cd assets npm ci --only=prod",
        "tailwind lanttern --minify",
        "esbuild lanttern --minify",
        "phx.digest"
      ],
      precommit: [
        "compile --warning-as-errors",
        "deps.unlock --unused",
        "format",
        "credo --strict",
        "test"
      ]
    ]
  end
end
