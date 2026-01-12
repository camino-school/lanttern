defmodule Lanttern.Repo.Migrations.CreateLessonTemplates do
  use Ecto.Migration

  def change do
    create table(:lesson_templates) do
      add :name, :text, null: false
      add :about, :text
      add :template, :text
      add :school_id, references(:schools, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:lesson_templates, [:school_id])
  end
end
