defmodule Lanttern.Repo.Migrations.AddTypeToStudentsRecords do
  use Ecto.Migration

  def change do
    # creating unique constraints to allow composite foreign keys.
    # this guarantees, in the database level, that the record and type
    # belongs to the same school

    # removing existing "student_record_type_school_id_fkey" to prevent unnecessary index
    drop index(:student_record_types, [:school_id])
    create unique_index(:student_record_types, [:school_id, :id])

    alter table(:students_records) do
      # `type_id` is `null: false`.
      # we'll add this in the execute blocks below
      # after we add a type to all records

      add :type_id,
          references(:student_record_types,
            with: [school_id: :school_id],
            on_delete: :nothing
          )
    end

    create index(:students_records, [:type_id])

    # creating one temp type to each school in the database
    execute """
            INSERT INTO student_record_types (name, bg_color, text_color, school_id, inserted_at, updated_at)
            SELECT
              'TEMP TYPE',
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
            UPDATE students_records SET type_id = student_record_types.id
            FROM student_record_types
            WHERE student_record_types.school_id = students_records.school_id
            """,
            ""

    # add not null constraints to students records' type_id
    execute "ALTER TABLE students_records ALTER COLUMN type_id SET NOT NULL", ""
  end
end
