defmodule Lanttern.Repo.Migrations.CreateClasses do
  use Ecto.Migration

  def change do
    create table(:classes) do
      add :name, :text, null: false

      timestamps()
    end
  end
end
