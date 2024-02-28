defmodule Lanttern.Repo.Migrations.AddNameGinIndexToStrands do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"

    execute """
      CREATE INDEX strands_name_gin_trgm_idx
        ON strands
        USING gin (name gin_trgm_ops);
    """
  end

  def down do
    execute "DROP INDEX strands_name_gin_trgm_idx"
  end
end
