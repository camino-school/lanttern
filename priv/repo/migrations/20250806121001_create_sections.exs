defmodule Lanttern.Repo.Migrations.CreateSections do
  use Ecto.Migration

  def change do
    create table(:sections) do
      add :name, :string
      add :position, :integer, default: 0, null: false

      timestamps()
    end
  end
end
