defmodule Lanttern.Repo.Migrations.CreateGradesReportCyclesAndSubjects do
  use Ecto.Migration

  def change do
    create table(:grades_report_cycles) do
      add :weight, :float, null: false, default: 1.0
      add :school_cycle_id, references(:school_cycles, on_delete: :nothing), null: false
      add :grades_report_id, references(:grades_reports, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:grades_report_cycles, [:school_cycle_id])
    create unique_index(:grades_report_cycles, [:grades_report_id, :school_cycle_id])

    create table(:grades_report_subjects) do
      add :position, :integer, null: false, default: 0
      add :subject_id, references(:subjects, on_delete: :nothing), null: false
      add :grades_report_id, references(:grades_reports, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:grades_report_subjects, [:subject_id])
    create unique_index(:grades_report_subjects, [:grades_report_id, :subject_id])
  end
end
