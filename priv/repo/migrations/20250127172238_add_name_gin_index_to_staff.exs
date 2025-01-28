defmodule Lanttern.Repo.Migrations.AddNameGinIndexToStaff do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm", ""

    execute """
              CREATE INDEX staff_name_gin_trgm_idx
                ON staff
                USING gin (name gin_trgm_ops);
            """,
            "DROP INDEX staff_name_gin_trgm_idx"
  end
end
