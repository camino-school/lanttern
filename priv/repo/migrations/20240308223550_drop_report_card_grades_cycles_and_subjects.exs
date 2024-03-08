defmodule Lanttern.Repo.Migrations.DropReportCardGradesCyclesAndSubjects do
  use Ecto.Migration

  def up do
    drop table(:report_card_grades_subjects)
    drop table(:report_card_grades_cycles)
  end

  def down do
    # report card grades subjects
    create table(:report_card_grades_subjects) do
      add :position, :integer, null: false, default: 0
      add :subject_id, references(:subjects, on_delete: :nothing), null: false
      add :report_card_id, references(:report_cards, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:report_card_grades_subjects, [:subject_id])
    create unique_index(:report_card_grades_subjects, [:report_card_id, :subject_id])

    # report card grades cycles
    create table(:report_card_grades_cycles) do
      add :school_cycle_id, references(:school_cycles, on_delete: :nothing), null: false
      add :report_card_id, references(:report_cards, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:report_card_grades_cycles, [:school_cycle_id])
    create unique_index(:report_card_grades_cycles, [:report_card_id, :school_cycle_id])
  end
end
