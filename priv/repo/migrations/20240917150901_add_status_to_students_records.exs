defmodule Lanttern.Repo.Migrations.AddStatusToStudentsRecords do
  use Ecto.Migration

  def change do
    # creating unique constraints to allow composite foreign keys.
    # this guarantees, in the database level, that the record and status
    # belongs to the same school

    # obs: unique school_id / id index already exists in student_record_statuses

    alter table(:students_records) do
      # `status_id` is `null: false`.
      # we'll add this in the execute blocks below
      # after we add a status to all records

      add :status_id,
          references(:student_record_statuses,
            with: [school_id: :school_id],
            on_delete: :nothing
          )
    end

    create index(:students_records, [:status_id])

    # creating one temp type to each school in the database
    execute """
            INSERT INTO student_record_statuses (name, bg_color, text_color, school_id, inserted_at, updated_at)
            SELECT
              'TEMP STATUS',
              '#000000',
              '#ffffff',
              students_records.school_id,
              now() AT time zone 'utc',
              now() AT time zone 'utc'
            FROM students_records
            """,
            ""

    # link temp types to existing students records
    execute """
            UPDATE students_records SET status_id = student_record_statuses.id
            FROM student_record_statuses
            WHERE student_record_statuses.school_id = students_records.school_id
            """,
            ""

    # add not null constraints to students records' status_id
    execute "ALTER TABLE students_records ALTER COLUMN status_id SET NOT NULL", ""
  end
end
