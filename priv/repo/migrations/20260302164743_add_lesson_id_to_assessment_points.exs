defmodule Lanttern.Repo.Migrations.AddLessonIdToAssessmentPoints do
  use Ecto.Migration

  def change do
    alter table(:assessment_points) do
      add :lesson_id, references(:lessons, on_delete: :delete_all)
    end

    create index(:assessment_points, [:lesson_id])
  end
end
