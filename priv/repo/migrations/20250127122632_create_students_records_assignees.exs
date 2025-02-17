defmodule Lanttern.Repo.Migrations.CreateStudentsRecordsAssignees do
  use Ecto.Migration

  @prefix "log"

  def change do
    # use composite foreign keys to guarantee,
    # in the database level, that record and assignee
    # belong to the same school

    create table(:students_records_assignees, primary_key: false) do
      # in the future we will handle how to cascade staff and school deletion to ss records
      add :staff_member_id,
          references(:staff, with: [school_id: :school_id], on_delete: :nothing),
          primary_key: true

      add :student_record_id,
          references(:students_records, with: [school_id: :school_id], on_delete: :delete_all),
          primary_key: true

      add :school_id, references(:schools, on_delete: :nothing), null: false
    end

    # also add assignees field to student records log
    alter table(:students_records, prefix: @prefix) do
      add :assignees_ids, {:array, :bigint}
    end
  end
end
