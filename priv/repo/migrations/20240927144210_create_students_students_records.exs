defmodule Lanttern.Repo.Migrations.CreateStudentsStudentsRecords do
  use Ecto.Migration

  def change do
    # creating unique constraints to allow composite foreign keys.
    # this guarantees, in the database level, that record and student
    # belong to the same school

    # removing existing "students_school_id_index" to prevent unnecessary index
    drop index(:students, [:school_id])
    create unique_index(:students, [:school_id, :id])

    # removing existing "students_records_school_id_index" to prevent unnecessary index
    drop index(:students_records, [:school_id])
    create unique_index(:students_records, [:school_id, :id])

    create table(:students_students_records, primary_key: false) do
      # in the future we will handle how to cascade student and school deletion to ss records
      add :student_id, references(:students, with: [school_id: :school_id], on_delete: :nothing),
        null: false

      add :student_record_id,
          references(:students_records, with: [school_id: :school_id], on_delete: :delete_all),
          null: false

      add :school_id, references(:schools, on_delete: :nothing), null: false
    end

    create index(:students_students_records, [:student_id])
    create unique_index(:students_students_records, [:student_record_id, :student_id])
  end
end
