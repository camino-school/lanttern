defmodule Lanttern.Repo.Migrations.AddActivityIdAndPositionToAssessmentPoints do
  use Ecto.Migration

  def up do
    alter table(:assessment_points) do
      add :position, :integer, null: false, default: 0
      add :activity_id, references(:activities)
    end

    create index(:assessment_points, [:activity_id])

    # "migrate" data from activities_assessment_points
    execute """
    UPDATE
      assessment_points
    SET
      position = activities_assessment_points.position,
      activity_id = activities_assessment_points.activity_id
    FROM activities_assessment_points
    WHERE
      assessment_points.id = activities_assessment_points.assessment_point_id;
    """

    drop table(:activities_assessment_points)
  end

  def down do
    # recreate activities_assessment_points table
    create table(:activities_assessment_points) do
      add :position, :integer, null: false, default: 0
      add :activity_id, references(:activities), null: false

      add :assessment_point_id, references(:assessment_points, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create index(:activities_assessment_points, [:activity_id])
    create unique_index(:activities_assessment_points, [:assessment_point_id])

    # rollback "migration", inserting rows in activities_assessment_points
    # (inserted_at and updated_at are not recoverable, we'll use now)
    execute """
    INSERT INTO activities_assessment_points
      (position, activity_id, assessment_point_id, inserted_at, updated_at)
    SELECT
      assessment_points.position,
      assessment_points.activity_id,
      assessment_points.id,
      now() AT time zone 'utc',
      now() AT time zone 'utc'
    FROM assessment_points
    WHERE assessment_points.activity_id IS NOT NULL;
    """

    # remove columns
    alter table(:assessment_points) do
      remove :position
      remove :activity_id
    end
  end
end
