defmodule Lanttern.Repo.Migrations.CreateMomentCards do
  use Ecto.Migration

  def change do
    create table(:moment_cards) do
      add :name, :text, null: false
      add :description, :text, null: false
      add :position, :integer, default: 0, null: false
      add :moment_id, references(:moments, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:moment_cards, [:moment_id])
  end
end
