defmodule Lanttern.Repo.Migrations.CreateAnalyticsSchema do
  use Ecto.Migration

  def up do
    execute "CREATE SCHEMA IF NOT EXISTS analytics"
  end

  def down do
    execute "DROP SCHEMA IF EXISTS analytics CASCADE"
  end
end
