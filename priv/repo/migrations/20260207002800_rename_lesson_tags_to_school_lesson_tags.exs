defmodule Lanttern.Repo.Migrations.RenameLessonTagsToSchoolLessonTags do
  use Ecto.Migration

  def change do
    rename table(:lesson_tags), to: table(:school_lesson_tags)
  end
end
