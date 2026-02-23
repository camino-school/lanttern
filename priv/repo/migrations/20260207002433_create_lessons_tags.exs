defmodule Lanttern.Repo.Migrations.CreateLessonsTags do
  use Ecto.Migration

  def change do
    create table(:lessons_tags, primary_key: false) do
      add :lesson_id, references(:lessons, on_delete: :delete_all), null: false
      add :tag_id, references(:lesson_tags, on_delete: :delete_all), null: false
    end

    create index(:lessons_tags, [:tag_id])
    create unique_index(:lessons_tags, [:lesson_id, :tag_id])
  end
end
