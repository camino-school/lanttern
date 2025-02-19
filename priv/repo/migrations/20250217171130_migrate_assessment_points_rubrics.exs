defmodule Lanttern.Repo.Migrations.MigrateAssessmentPointsRubrics do
  use Ecto.Migration

  def change do
    alter table(:assessment_points_rubrics) do
      # change fks to use composite foreign keys (it's ok to remove at this point, no data loss)
      remove :assessment_point_id, references(:assessment_points, on_delete: :nothing),
        null: false

      remove :rubric_id, references(:rubrics, on_delete: :nothing), null: false

      add :scale_id, references(:grading_scales, on_delete: :nothing), null: false

      add :assessment_point_id,
          references(:assessment_points, with: [scale_id: :scale_id], on_delete: :nothing),
          null: false

      add :rubric_id, references(:rubrics, with: [scale_id: :scale_id], on_delete: :nothing),
        null: false
    end

    create index(:assessment_points_rubrics, [:scale_id])
    create index(:assessment_points_rubrics, [:assessment_point_id])
    create index(:assessment_points_rubrics, [:rubric_id])

    # insert assessment_points_rubrics based on assessment_points rubric_id
    execute """
            INSERT INTO assessment_points_rubrics (
              assessment_point_id,
              rubric_id,
              scale_id,
              inserted_at,
              updated_at
            )
            SELECT
              id AS assessment_point_id,
              rubric_id,
              scale_id,
              inserted_at,
              inserted_at AS updated_at
            FROM assessment_points
            WHERE assessment_points.rubric_id IS NOT NULL
            """,
            ""

    # insert diff assessment_points_rubrics based on diff_for_rubric_id
    execute """
            INSERT INTO assessment_points_rubrics (
              assessment_point_id,
              rubric_id,
              scale_id,
              is_diff,
              inserted_at,
              updated_at
            )
            SELECT
              ap.id AS assessment_point_id,
              diff_r.id AS rubric_id,
              ap.scale_id AS scale_id,
              true AS is_diff,
              diff_r.inserted_at,
              diff_r.inserted_at AS updated_at
            FROM assessment_points ap
            JOIN rubrics r on r.id = ap.rubric_id
            JOIN rubrics diff_r on diff_r.diff_for_rubric_id = r.id
            """,
            ""

    # insert diff assessment_points_rubrics entries first based on differentiation_rubrics_students
    execute """
            INSERT INTO rubrics_assessment_entries (
              assessment_point_rubric_id,
              student_id,
              inserted_at,
              updated_at
            )
            SELECT
              apr.id AS assessment_point_rubric_id,
              ape.student_id,
              ape.inserted_at,
              ape.inserted_at AS updated_at
            FROM assessment_point_entries ape
            JOIN assessment_points_rubrics apr ON apr.assessment_point_id = ape.assessment_point_id
            JOIN differentiation_rubrics_students drs ON drs.rubric_id = apr.rubric_id AND drs.student_id = ape.student_id
            """,
            ""

    # we don't need to create rubric entries for non diff rubrics
    # (view `Assessments` moduledoc for more info)
  end
end
