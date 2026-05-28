defmodule Lanttern.Repo.Migrations.UpdateHasMarkingIncludeIsMissing do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE assessment_point_entries DROP COLUMN has_marking"

    execute """
    ALTER TABLE assessment_point_entries
    ADD COLUMN has_marking BOOLEAN NOT NULL
    GENERATED ALWAYS AS (
      ordinal_value_id IS NOT NULL
      OR score IS NOT NULL
      OR is_missing
    ) STORED
    """
  end

  def down do
    execute "ALTER TABLE assessment_point_entries DROP COLUMN has_marking"

    execute """
    ALTER TABLE assessment_point_entries
    ADD COLUMN has_marking BOOLEAN NOT NULL
    GENERATED ALWAYS AS (
      ordinal_value_id IS NOT NULL
      OR score IS NOT NULL
    ) STORED
    """
  end
end
