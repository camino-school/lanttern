defmodule Lanttern.Repo.Migrations.AddHasMarkingToAssessmentPointEntries do
  use Ecto.Migration

  def change do
    alter table(:assessment_point_entries) do
      add :has_marking, :boolean,
        null: false,
        generated: """
          ALWAYS AS (
            ordinal_value_id IS NOT NULL
            OR score IS NOT NULL
          ) STORED
        """
    end
  end
end
