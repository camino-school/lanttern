defmodule Lanttern.Repo.Migrations.MigrateDiffRubricsDataToAssessmentPointEntries do
  use Ecto.Migration

  def change do
    # set differentiation rubric id for assessment point entries
    execute """
            update assessment_point_entries ape
            set differentiation_rubric_id = r.id
            from differentiation_rubrics_students drs
            join rubrics r on r.id = drs.rubric_id
            join assessment_points ap on ap.rubric_id = r.diff_for_rubric_id
            where
              ape.assessment_point_id = ap.id
              and ape.student_id = drs.student_id
            """,
            ""

    # consider rubrics as differentiation if they are linked to diff assessment points
    execute """
            update rubrics r
            set is_differentiation = true
            from assessment_points ap
            where
              not r.is_differentiation
              and ap.is_differentiation
              and ap.rubric_id = r.id
            """,
            ""
  end
end
