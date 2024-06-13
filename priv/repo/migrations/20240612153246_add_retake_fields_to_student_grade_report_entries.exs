defmodule Lanttern.Repo.Migrations.AddRetakeFieldsToStudentGradeReportEntries do
  use Ecto.Migration

  def change do
    alter table(:student_grade_report_entries) do
      add :pre_retake_score, :float
      add :pre_retake_ordinal_value_id, references(:ordinal_values, on_delete: :nothing)
    end

    create index(:student_grade_report_entries, [:pre_retake_ordinal_value_id])
  end
end
