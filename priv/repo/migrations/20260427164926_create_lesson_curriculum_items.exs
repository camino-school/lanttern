defmodule Lanttern.Repo.Migrations.CreateLessonCurriculumItems do
  use Ecto.Migration

  def change do
    create table(:lesson_curriculum_items) do
      add :position, :integer, default: 0, null: false
      add :lesson_id, references(:lessons, on_delete: :delete_all), null: false
      add :curriculum_item_id, references(:curriculum_items, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:lesson_curriculum_items, [:lesson_id])
    create unique_index(:lesson_curriculum_items, [:curriculum_item_id, :lesson_id])
  end
end
