defmodule Lanttern.Repo.Migrations.CreateSubjects do
  use Ecto.Migration

  def change do
    create table(:subjects) do
      add :name, :text, null: false

      timestamps()
    end
  end
end
