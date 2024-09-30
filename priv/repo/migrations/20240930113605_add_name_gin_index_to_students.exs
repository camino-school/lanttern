defmodule Lanttern.Repo.Migrations.AddNameGinIndexToStudents do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"

    execute """
      CREATE INDEX students_name_gin_trgm_idx
        ON students
        USING gin (name gin_trgm_ops);
    """
  end

  def down do
    execute "DROP INDEX students_name_gin_trgm_idx"
  end
end
