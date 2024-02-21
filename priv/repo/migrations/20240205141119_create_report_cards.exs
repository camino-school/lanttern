defmodule Lanttern.Repo.Migrations.CreateReportCards do
  use Ecto.Migration

  def change do
    create table(:report_cards) do
      add :name, :text, null: false
      add :description, :text
      add :school_cycle_id, references(:school_cycles, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:report_cards, [:school_cycle_id])
  end
end
