defmodule Lanttern.Repo.Migrations.AddAssessmentPointsClassesRelationships do
  use Ecto.Migration

  def change do
    create table(:assessment_points_classes, primary_key: false) do
      add :assessment_point_id, references(:assessment_points)
      add :class_id, references(:classes)
    end

    create index(:assessment_points_classes, [:assessment_point_id])
    create index(:assessment_points_classes, [:class_id])
    create unique_index(:assessment_points_classes, [:assessment_point_id, :class_id])
  end
end
