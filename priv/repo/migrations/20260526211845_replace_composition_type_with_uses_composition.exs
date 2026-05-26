defmodule Lanttern.Repo.Migrations.ReplaceCompositionTypeWithUsesComposition do
  use Ecto.Migration

  @log_prefix "log"

  def up do
    alter table(:assessment_points) do
      add :uses_composition, :boolean, default: false, null: false
    end

    execute(
      "UPDATE assessment_points SET uses_composition = true WHERE composition_type IS NOT NULL"
    )

    alter table(:assessment_points) do
      remove :composition_type
    end

    alter table(:assessment_points, prefix: @log_prefix) do
      add :uses_composition, :boolean
    end

    execute("UPDATE log.assessment_points SET uses_composition = (composition_type IS NOT NULL)")

    alter table(:assessment_points, prefix: @log_prefix) do
      remove :composition_type
    end
  end

  def down do
    alter table(:assessment_points) do
      add :composition_type, :string
    end

    execute("UPDATE assessment_points SET composition_type = 'sum' WHERE uses_composition = true")

    alter table(:assessment_points) do
      remove :uses_composition
    end

    alter table(:assessment_points, prefix: @log_prefix) do
      add :composition_type, :text
    end

    execute(
      "UPDATE log.assessment_points SET composition_type = CASE WHEN uses_composition THEN 'sum' ELSE NULL END"
    )

    alter table(:assessment_points, prefix: @log_prefix) do
      remove :uses_composition
    end
  end
end
