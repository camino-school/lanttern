defmodule Lanttern.Repo.Migrations.FixAssessmentPointEntriesScaleIdFkey do
  @moduledoc """
  In an old migration (`AdjustAssessmentPointEntriesScaleConstraints`),
  we set the assessment point entries' scale id foreign key constraint as

  ```sql
  ALTER TABLE assessment_point_entries
  DROP CONSTRAINT assessment_point_entries_scale_id_fkey;

  ALTER TABLE assessment_point_entries
  ADD CONSTRAINT assessment_point_entries_scale_id_fkey
  FOREIGN KEY (assessment_point_id, scale_id)
  REFERENCES assessment_points(id, scale_id);
  ```

  Which does not make sense, as we're referencing the `assessment_points` table.

  This migration fixes this inconsistency, by recreating the `assessment_point_entries_scale_id_fkey`
  refrencing the `grading_scales` table, and recreating the `assessment_point_entries_assessment_point_id_fkey`
  using a composite foreign key with `scale_id`, which was the original intention.
  """

  use Ecto.Migration

  def change do
    execute """
            ALTER TABLE assessment_point_entries
              DROP CONSTRAINT assessment_point_entries_scale_id_fkey
            """,
            """
            ALTER TABLE assessment_point_entries
              ADD CONSTRAINT assessment_point_entries_scale_id_fkey
                FOREIGN KEY (assessment_point_id, scale_id)
                  REFERENCES assessment_points(id, scale_id)
            """

    execute """
            ALTER TABLE assessment_point_entries
              ADD CONSTRAINT assessment_point_entries_scale_id_fkey
                FOREIGN KEY (scale_id)
                  REFERENCES grading_scales(id)
            """,
            """
            ALTER TABLE assessment_point_entries
              DROP CONSTRAINT assessment_point_entries_scale_id_fkey
            """

    execute """
            ALTER TABLE assessment_point_entries
              DROP CONSTRAINT assessment_point_entries_assessment_point_id_fkey
            """,
            """
            ALTER TABLE assessment_point_entries
              ADD CONSTRAINT assessment_point_entries_assessment_point_id_fkey
                FOREIGN KEY (assessment_point_id)
                  REFERENCES assessment_points(id)
            """

    execute """
            ALTER TABLE assessment_point_entries
              ADD CONSTRAINT assessment_point_entries_assessment_point_id_fkey
                FOREIGN KEY (assessment_point_id, scale_id)
                  REFERENCES assessment_points(id, scale_id)
            """,
            """
            ALTER TABLE assessment_point_entries
              DROP CONSTRAINT assessment_point_entries_assessment_point_id_fkey
            """
  end
end
