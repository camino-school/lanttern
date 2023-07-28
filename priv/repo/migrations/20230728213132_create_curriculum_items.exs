defmodule Lanttern.Repo.Migrations.CreateCurriculumItems do
  use Ecto.Migration

  def change do
    create table(:curriculum_items) do
      add :name, :text

      timestamps()
    end
  end
end
