defmodule Lanttern.Repo.Migrations.AddNameGinIndexToClasses do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"

    execute """
      CREATE INDEX classes_name_gin_trgm_idx
        ON classes
        USING gin (name gin_trgm_ops);
    """
  end

  def down do
    execute "DROP INDEX classes_name_gin_trgm_idx"
  end
end
