defmodule Lanttern.Repo.Migrations.AdjustStudentGradeReportEntriesCompositionFields do
  use Ecto.Migration

  # 1. rename normalized_value to composition_normalized_value
  # 2. replace composition_ordinal_value_name with composition_ordinal_value_id

  def change do
    rename table(:student_grade_report_entries), :normalized_value,
      to: :composition_normalized_value

    alter table(:student_grade_report_entries) do
      remove :composition_ordinal_value_name, :string
      add :composition_ordinal_value_id, references(:ordinal_values, on_delete: :nothing)
    end

    create index(:student_grade_report_entries, [:composition_ordinal_value_id])
  end
end
