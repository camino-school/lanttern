defmodule Lanttern.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      LantternWeb.Telemetry,
      # Start the Ecto repository
      Lanttern.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Lanttern.PubSub},
      # Start Finch
      {Finch, name: Lanttern.Finch},
      # Start the Endpoint (http/https)
      LantternWeb.Endpoint,
      # Start a worker by calling: Lanttern.Worker.start_link(arg)
      # {Lanttern.Worker, arg},
      # Start Joken JWKS token strategy
      {Lanttern.GoogleTokenStrategy, time_interval: 60_000}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lanttern.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LantternWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
