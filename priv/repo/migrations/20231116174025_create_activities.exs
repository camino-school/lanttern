defmodule Lanttern.Repo.Migrations.CreateActivities do
  use Ecto.Migration

  def change do
    create table(:activities) do
      add :name, :text, null: false
      add :description, :text, null: false
      add :position, :integer, null: false, default: 0
      add :strand_id, references(:strands, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:activities, [:strand_id])
  end
end
