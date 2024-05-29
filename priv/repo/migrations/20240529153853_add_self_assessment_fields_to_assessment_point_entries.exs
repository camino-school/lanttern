defmodule Lanttern.Repo.Migrations.AddSelfAssessmentFieldsToAssessmentPointEntries do
  use Ecto.Migration

  def change do
    alter table(:assessment_point_entries) do
      add :student_score, :float
      add :student_report_note, :text
      add :student_ordinal_value_id, references(:ordinal_values, on_delete: :nothing)
    end

    create index(:assessment_point_entries, [:student_ordinal_value_id])
  end
end
