defmodule Lanttern.Repo.Migrations.AddCompositionToStudentGradeReportEntries do
  use Ecto.Migration

  def change do
    alter table(:student_grade_report_entries) do
      add :composition, :map
      add :composition_ordinal_value_name, :string
      add :composition_score, :float
      add :composition_datetime, :utc_datetime
    end
  end
end
