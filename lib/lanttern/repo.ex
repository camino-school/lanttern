defmodule Lanttern.Repo do
  use Ecto.Repo,
    otp_app: :lanttern,
    adapter: Ecto.Adapters.Postgres
end
