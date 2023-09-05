defmodule Lanttern.Repo.Migrations.AddSearchableToCurriculumItems do
  use Ecto.Migration

  def up do
    execute """
      ALTER TABLE curriculum_items
        ADD COLUMN searchable text
        GENERATED ALWAYS AS (
          coalesce('#' || id::text, '') || coalesce(' (' || code || ') ', ' ') || coalesce(name, '')
        ) STORED;
    """

    execute """
      CREATE INDEX curriculum_items_searchable_gin_trgm_idx
        ON curriculum_items
        USING gin (searchable gin_trgm_ops);
    """

    execute "DROP INDEX curriculum_items_name_gin_trgm_idx"
  end

  def down do
    execute """
      CREATE INDEX curriculum_items_name_gin_trgm_idx
        ON curriculum_items
        USING gin (name gin_trgm_ops);
    """

    execute "DROP INDEX curriculum_items_searchable_gin_trgm_idx"

    alter table(:curriculum_items) do
      remove :searchable
    end
  end
end
