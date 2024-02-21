defmodule Lanttern.Repo.Migrations.CreateStrandReports do
  use Ecto.Migration

  def change do
    create table(:strand_reports) do
      add :report_card_id, references(:report_cards, on_delete: :nothing), null: false
      add :strand_id, references(:strands, on_delete: :nothing), null: false
      add :position, :integer, null: false, default: 0
      add :description, :text

      timestamps()
    end

    create index(:strand_reports, [:report_card_id])
    create unique_index(:strand_reports, [:strand_id, :report_card_id])
  end
end
