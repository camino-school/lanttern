defmodule Lanttern.Repo.Migrations.CreateLessonsSubjects do
  use Ecto.Migration

  def change do
    create table(:lessons_subjects, primary_key: false) do
      add :lesson_id, references(:lessons, on_delete: :delete_all), null: false
      add :subject_id, references(:subjects, on_delete: :delete_all), null: false
    end

    create index(:lessons_subjects, [:subject_id])
    create unique_index(:lessons_subjects, [:lesson_id, :subject_id])
  end
end
