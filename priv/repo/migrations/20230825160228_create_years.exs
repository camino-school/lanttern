defmodule Lanttern.Repo.Migrations.CreateYears do
  use Ecto.Migration

  def change do
    create table(:years) do
      add :name, :text, null: false

      timestamps()
    end
  end
end
