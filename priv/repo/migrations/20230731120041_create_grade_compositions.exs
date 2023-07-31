defmodule Lanttern.Repo.Migrations.CreateGradeCompositions do
  use Ecto.Migration

  def change do
    create table(:grade_compositions) do
      add :name, :text

      timestamps()
    end
  end
end
