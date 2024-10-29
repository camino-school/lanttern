defmodule Lanttern.Repo.Migrations.AddNormalizedValueToStudentGradeReportEntries do
  use Ecto.Migration

  def change do
    # 1. create empty normalized_value field
    # 2. copy values from composition_normalized_value to normalized_value
    # 3. make normalized_value not null

    # 1
    alter table(:student_grade_report_entries) do
      add :normalized_value, :float
    end

    # 2
    execute """
            UPDATE student_grade_report_entries
            SET normalized_value=composition_normalized_value
            """,
            ""

    # 3
    execute "ALTER TABLE student_grade_report_entries ALTER COLUMN normalized_value SET NOT NULL",
            ""
  end
end
