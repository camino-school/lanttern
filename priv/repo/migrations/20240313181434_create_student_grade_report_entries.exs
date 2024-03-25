defmodule Lanttern.Repo.Migrations.CreateStudentGradeReportEntries do
  use Ecto.Migration

  def change do
    # creating unique constraints to allow composite foreign keys.
    # this guarantees, in the database level, that the selected grades report subject
    # and cycle belongs to the same grades report
    create unique_index(:grades_report_cycles, [:id, :grades_report_id])
    create unique_index(:grades_report_subjects, [:id, :grades_report_id])

    create table(:student_grade_report_entries) do
      add :comment, :text
      add :normalized_value, :float, null: false
      add :score, :float
      add :student_id, references(:students, on_delete: :nothing), null: false
      add :grades_report_id, references(:grades_reports, on_delete: :nothing), null: false

      add :grades_report_cycle_id,
          references(:grades_report_cycles,
            with: [grades_report_id: :grades_report_id],
            on_delete: :nothing
          ),
          null: false

      add :grades_report_subject_id,
          references(:grades_report_subjects,
            with: [grades_report_id: :grades_report_id],
            on_delete: :nothing
          ),
          null: false

      add :ordinal_value_id, references(:ordinal_values, on_delete: :nothing)

      timestamps()
    end

    create index(:student_grade_report_entries, [:grades_report_cycle_id])
    create index(:student_grade_report_entries, [:grades_report_subject_id])

    create unique_index(:student_grade_report_entries, [
             :student_id,
             :grades_report_cycle_id,
             :grades_report_subject_id
           ])

    create index(:student_grade_report_entries, [:ordinal_value_id])

    create constraint(:student_grade_report_entries, :normalized_value_should_be_between_0_and_1,
             check: "normalized_value >= 0.0 AND normalized_value <= 1.0"
           )
  end
end
