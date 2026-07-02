defmodule Lanttern.Repo.Migrations.CreateAssessmentPointsLessons do
  use Ecto.Migration

  @log_prefix "log"

  def up do
    # Many-to-many link between assessment points and lessons. Replaces the single
    # `assessment_points.lesson_id` FK so an assessment point can be linked to any
    # number of lessons (bare join table, no schema module, no ordering column).
    create table(:assessment_points_lessons) do
      add :assessment_point_id, references(:assessment_points, on_delete: :delete_all),
        null: false

      add :lesson_id, references(:lessons, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:assessment_points_lessons, [:assessment_point_id])
    create index(:assessment_points_lessons, [:lesson_id])
    create unique_index(:assessment_points_lessons, [:assessment_point_id, :lesson_id])

    # Backfill the join from the existing single-lesson FK.
    execute("""
    INSERT INTO assessment_points_lessons (assessment_point_id, lesson_id, inserted_at, updated_at)
    SELECT id, lesson_id, now(), now()
    FROM assessment_points
    WHERE lesson_id IS NOT NULL
    """)

    # Drop the now-superseded single-lesson FK (its index and constraint go with it).
    alter table(:assessment_points) do
      remove :lesson_id
    end

    # Intentional data loss: the per-AP link history now lives in the lesson log via
    # `assessment_points_ids`. Old `lesson_id` log values are retained in backups only.
    alter table(:assessment_points, prefix: @log_prefix) do
      remove :lesson_id
    end

    alter table(:lessons, prefix: @log_prefix) do
      add :assessment_points_ids, {:array, :integer}
    end
  end

  def down do
    alter table(:lessons, prefix: @log_prefix) do
      remove :assessment_points_ids
    end

    alter table(:assessment_points, prefix: @log_prefix) do
      add :lesson_id, :bigint
    end

    alter table(:assessment_points) do
      add :lesson_id, references(:lessons, on_delete: :nilify_all)
    end

    create index(:assessment_points, [:lesson_id])

    # Repopulate the single-lesson FK from the join, keeping the lowest linked lesson
    # per assessment point (lossy — multi-lesson links collapse to one).
    execute("""
    UPDATE assessment_points ap
    SET lesson_id = sub.min_lesson_id
    FROM (
      SELECT assessment_point_id, MIN(lesson_id) AS min_lesson_id
      FROM assessment_points_lessons
      GROUP BY assessment_point_id
    ) sub
    WHERE ap.id = sub.assessment_point_id
    """)

    drop table(:assessment_points_lessons)
  end
end
