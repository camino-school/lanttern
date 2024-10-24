defmodule Lanttern.Repo.Migrations.CreateStudentsGradesReportsFinalEntries do
  use Ecto.Migration

  def change do
    create table(:students_grades_reports_final_entries) do
      add :comment, :text
      add :score, :float
      add :ordinal_value_id, references(:ordinal_values, on_delete: :nothing)

      add :student_id, references(:students, on_delete: :nothing), null: false
      add :grades_report_id, references(:grades_reports, on_delete: :nothing), null: false

      add :grades_report_subject_id,
          references(:grades_report_subjects,
            with: [grades_report_id: :grades_report_id],
            on_delete: :nothing
          ),
          null: false

      # pre retake fields
      add :pre_retake_score, :float
      add :pre_retake_ordinal_value_id, references(:ordinal_values, on_delete: :nothing)

      # composition fields
      add :composition, :map
      add :composition_normalized_value, :float, null: false
      add :composition_datetime, :utc_datetime
      add :composition_score, :float
      add :composition_ordinal_value_id, references(:ordinal_values, on_delete: :nothing)

      timestamps()
    end

    create index(:students_grades_reports_final_entries, [:grades_report_id])
    create index(:students_grades_reports_final_entries, [:grades_report_subject_id])

    create unique_index(:students_grades_reports_final_entries, [
             :student_id,
             :grades_report_subject_id
           ])

    create constraint(
             :students_grades_reports_final_entries,
             :normalized_value_should_be_between_0_and_1,
             check: "composition_normalized_value >= 0.0 AND composition_normalized_value <= 1.0"
           )

    create index(:students_grades_reports_final_entries, [:ordinal_value_id])
    create index(:students_grades_reports_final_entries, [:pre_retake_ordinal_value_id])
    create index(:students_grades_reports_final_entries, [:composition_ordinal_value_id])
  end
end
