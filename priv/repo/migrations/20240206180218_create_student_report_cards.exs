defmodule Lanttern.Repo.Migrations.CreateStudentReportCards do
  use Ecto.Migration

  def change do
    create table(:student_report_cards) do
      add :comment, :text
      add :footnote, :text
      add :report_card_id, references(:report_cards, on_delete: :nothing), null: false
      add :student_id, references(:students, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:student_report_cards, [:report_card_id])
    create unique_index(:student_report_cards, [:student_id, :report_card_id])
  end
end
