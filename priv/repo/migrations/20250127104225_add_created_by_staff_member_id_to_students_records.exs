defmodule Lanttern.Repo.Migrations.AddCreatedByStaffMemberIdToStudentsRecords do
  use Ecto.Migration

  @prefix "log"

  def change do
    # creating unique constraints to allow composite foreign keys.
    # this guarantees, in the database level, that staff member
    # and student record belong to the same school

    # removing existing "staff_school_id_index" to prevent unnecessary index
    drop index(:staff, [:school_id])
    create unique_index(:staff, [:school_id, :id])

    alter table(:students_records) do
      add :created_by_staff_member_id,
          references(:staff, with: [school_id: :school_id], on_delete: :nothing)
    end

    alter table(:students_records, prefix: @prefix) do
      add :created_by_staff_member_id, :bigint
    end

    # update all existing records with a staff member id
    # based on the students records logs:

    execute """
            update students_records sr
            set created_by_staff_member_id = subquery.staff_member_id
            from (
              select
                sr_log.student_record_id,
                s.id staff_member_id
              from log.students_records sr_log
              join profiles p on p.id = sr_log.profile_id
              join staff s on s.id = p.staff_member_id
              where sr_log.operation = 'CREATE'
            ) as subquery
            where subquery.student_record_id = sr.id
            """,
            ""

    # then make the column not null

    execute "ALTER TABLE students_records ALTER COLUMN created_by_staff_member_id SET NOT NULL",
            ""
  end
end
