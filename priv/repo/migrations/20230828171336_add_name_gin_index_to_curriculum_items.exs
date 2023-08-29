defmodule Lanttern.Repo.Migrations.AddNameGinIndexToCurriculumItems do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"

    execute """
      CREATE INDEX curriculum_items_name_gin_trgm_idx
        ON curriculum_items
        USING gin (name gin_trgm_ops);
    """
  end

  def down do
    execute "DROP INDEX curriculum_items_name_gin_trgm_idx"
  end
end
