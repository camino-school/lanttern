defmodule Lanttern.Repo.Migrations.DropAssessmentPointsClasses do
  use Ecto.Migration

  # Drop the pre-strands legacy `assessment_points_classes` join table. It has been
  # dead since assessment points moved under strands/moments; no application code
  # reads or writes it anymore.
  def up do
    drop table(:assessment_points_classes)
  end

  def down do
    create table(:assessment_points_classes, primary_key: false) do
      add :assessment_point_id, references(:assessment_points)
      add :class_id, references(:classes)
    end

    create index(:assessment_points_classes, [:assessment_point_id])
    create index(:assessment_points_classes, [:class_id])
    create unique_index(:assessment_points_classes, [:assessment_point_id, :class_id])
  end
end
