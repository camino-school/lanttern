defmodule Lanttern.Repo.Migrations.CreateReportCardGradesCycles do
  use Ecto.Migration

  def change do
    create table(:report_card_grades_cycles) do
      add :school_cycle_id, references(:school_cycles, on_delete: :nothing), null: false
      add :report_card_id, references(:report_cards, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:report_card_grades_cycles, [:school_cycle_id])
    create unique_index(:report_card_grades_cycles, [:report_card_id, :school_cycle_id])
  end
end
