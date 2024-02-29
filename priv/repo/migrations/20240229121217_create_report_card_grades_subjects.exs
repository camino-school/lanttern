defmodule Lanttern.Repo.Migrations.CreateReportCardGradesSubjects do
  use Ecto.Migration

  def change do
    create table(:report_card_grades_subjects) do
      add :position, :integer, null: false, default: 0
      add :subject_id, references(:subjects, on_delete: :nothing), null: false
      add :report_card_id, references(:report_cards, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:report_card_grades_subjects, [:subject_id])
    create unique_index(:report_card_grades_subjects, [:report_card_id, :subject_id])
  end
end
