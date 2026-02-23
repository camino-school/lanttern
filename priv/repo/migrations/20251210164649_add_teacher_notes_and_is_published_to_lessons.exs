defmodule Lanttern.Repo.Migrations.AddTeacherNotesAndIsPublishedToLessons do
  use Ecto.Migration

  def change do
    alter table(:lessons) do
      add :teacher_notes, :text
      add :differentiation_notes, :text
      add :is_published, :boolean, default: false, null: false
    end
  end
end
