defmodule Lanttern.Repo.Migrations.AddRubricToAssessmentPoints do
  use Ecto.Migration

  def change do
    alter table(:assessment_points) do
      add :rubric_id, references(:rubrics, with: [scale_id: :scale_id], on_delete: :delete_all)
    end
  end
end
