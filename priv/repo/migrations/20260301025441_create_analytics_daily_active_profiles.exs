defmodule Lanttern.Repo.Migrations.CreateAnalyticsDailyActiveProfiles do
  use Ecto.Migration

  @prefix "analytics"

  def change do
    create table(:daily_active_profiles, prefix: @prefix) do
      add :profile_id, :bigint, null: false
      add :date, :date, null: false

      timestamps(updated_at: false)
    end

    create unique_index(:daily_active_profiles, [:profile_id, :date], prefix: @prefix)
  end
end
