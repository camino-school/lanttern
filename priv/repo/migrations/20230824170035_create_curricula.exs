defmodule Lanttern.Repo.Migrations.CreateCurricula do
  use Ecto.Migration

  def change do
    create table(:curricula) do
      add :name, :text, null: false
      add :code, :text

      timestamps()
    end
  end
end
