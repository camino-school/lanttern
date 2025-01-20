defmodule Lanttern.Repo.Migrations.CreateAssessmentPointsRubrics do
  use Ecto.Migration

  def change do
    create table(:assessment_points_rubrics) do
      add :position, :integer, default: 0, null: false
      add :is_diff, :boolean, default: false, null: false
      add :assessment_point_id, references(:assessment_points, on_delete: :nothing), null: false
      add :rubric_id, references(:rubrics, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:assessment_points_rubrics, [:position])
    create index(:assessment_points_rubrics, [:assessment_point_id])
    create index(:assessment_points_rubrics, [:rubric_id])

    create unique_index(:assessment_points_rubrics, [:rubric_id, :assessment_point_id],
             where: "is_diff is null"
           )
  end
end
