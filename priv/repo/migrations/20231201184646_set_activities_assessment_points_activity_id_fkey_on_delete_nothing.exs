defmodule Lanttern.Repo.Migrations.SetActivitiesAssessmentPointsActivityIdFkeyOnDeleteNothing do
  use Ecto.Migration

  def change do
    execute """
            ALTER TABLE activities_assessment_points
              DROP CONSTRAINT activities_assessment_points_activity_id_fkey,
              ADD CONSTRAINT activities_assessment_points_activity_id_fkey FOREIGN KEY (activity_id)
                REFERENCES activities (id);
            """,
            """
            ALTER TABLE activities_assessment_points
              DROP CONSTRAINT activities_assessment_points_activity_id_fkey,
              ADD CONSTRAINT activities_assessment_points_activity_id_fkey FOREIGN KEY (activity_id)
                REFERENCES activities (id) ON DELETE CASCADE;
            """
  end
end
