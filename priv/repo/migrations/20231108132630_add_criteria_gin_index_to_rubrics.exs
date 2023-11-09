defmodule Lanttern.Repo.Migrations.AddCriteriaGinIndexToRubrics do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"

    execute """
      CREATE INDEX rubrics_criteria_gin_trgm_idx
        ON rubrics
        USING gin (criteria gin_trgm_ops);
    """
  end

  def down do
    execute "DROP INDEX rubrics_criteria_gin_trgm_idx"
  end
end
