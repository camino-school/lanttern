defmodule Lanttern.Repo.Migrations.AdjustAssessmentPointEntriesScaleConstraints do
  use Ecto.Migration

  def change do
    # creating unique constraints to allow composite foreign keys.
    # this guarantees, in the database level, that the entry and parent
    # assessment point scales are in sync

    # removing existing "assessment_points_scale_id_fkey" to prevent unnecessary index
    drop index(:assessment_points, [:scale_id])
    create unique_index(:assessment_points, [:scale_id, :id])

    # drop assessment_point_entries_scale_id_fkey and recreate it using composite fks

    execute """
            ALTER TABLE assessment_point_entries
              DROP CONSTRAINT assessment_point_entries_scale_id_fkey
            """,
            """
            ALTER TABLE assessment_point_entries
              ADD CONSTRAINT assessment_point_entries_scale_id_fkey
                FOREIGN KEY (scale_id)
                  REFERENCES grading_scales(id)
            """

    execute """
            ALTER TABLE assessment_point_entries
              ADD CONSTRAINT assessment_point_entries_scale_id_fkey
                FOREIGN KEY (assessment_point_id, scale_id)
                  REFERENCES assessment_points(id, scale_id)
            """,
            """
            ALTER TABLE assessment_point_entries
              DROP CONSTRAINT assessment_point_entries_scale_id_fkey
            """
  end
end
