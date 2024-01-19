defmodule Lanttern.Repo.Migrations.AdjustAssessmentPointsRubricIdFkeyConstraint do
  use Ecto.Migration

  def change do
    execute """
            ALTER TABLE assessment_points
              DROP CONSTRAINT assessment_points_rubric_id_fkey,
              ADD CONSTRAINT assessment_points_rubric_id_fkey FOREIGN KEY (rubric_id)
                REFERENCES rubrics (id) ON DELETE SET NULL;
            """,
            """
            ALTER TABLE assessment_points
              DROP CONSTRAINT assessment_points_rubric_id_fkey,
              ADD CONSTRAINT assessment_points_rubric_id_fkey FOREIGN KEY (rubric_id)
                REFERENCES rubrics (id) ON DELETE CASCADE;
            """
  end
end
