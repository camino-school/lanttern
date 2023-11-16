defmodule Lanttern.Repo.Migrations.CreateStrands do
  use Ecto.Migration

  def change do
    create table(:strands) do
      add :name, :text, null: false
      add :description, :text, null: false

      timestamps()
    end
  end
end
