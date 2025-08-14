defmodule Lanttern.Repo.Migrations.CreateSections do
  use Ecto.Migration

  def change do
    create table(:sections) do
      add :name, :string
      add :position, :integer, default: 0, null: false
      add :school_id, references(:schools, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:sections, [:name, :school_id])
  end
end
