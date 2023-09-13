defmodule Lanttern.Repo.Migrations.CreateSchools do
  use Ecto.Migration

  def change do
    create table(:schools) do
      add :name, :text, null: false

      timestamps()
    end
  end
end
