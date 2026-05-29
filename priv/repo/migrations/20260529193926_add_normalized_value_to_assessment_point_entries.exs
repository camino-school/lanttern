defmodule Lanttern.Repo.Migrations.AddNormalizedValueToAssessmentPointEntries do
  use Ecto.Migration

  def change do
    alter table(:assessment_point_entries) do
      add :normalized_value, :float
      add :student_normalized_value, :float
    end
  end
end
