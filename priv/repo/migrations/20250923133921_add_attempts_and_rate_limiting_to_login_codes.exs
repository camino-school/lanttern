defmodule Lanttern.Repo.Migrations.AddAttemptsAndRateLimitingToLoginCodes do
  use Ecto.Migration

  def change do
    # Clear existing login_codes to avoid constraint issues with new NOT NULL fields
    execute("DELETE FROM login_codes", "")

    alter table(:login_codes) do
      add :attempts, :integer, null: false, default: 0
      add :rate_limited_until, :utc_datetime, null: false
    end
  end
end
