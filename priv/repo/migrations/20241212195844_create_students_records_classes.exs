defmodule Lanttern.Repo.Migrations.CreateStudentsRecordsClasses do
  use Ecto.Migration

  def change do
    # creating unique constraints to allow composite foreign keys.
    # this guarantees, in the database level, that record and class
    # belong to the same school

    # removing existing "classes_school_id_index" to prevent unnecessary index
    drop index(:classes, [:school_id])
    create unique_index(:classes, [:school_id, :id])

    create table(:students_records_classes, primary_key: false) do
      # in the future we will handle how to cascade class and school deletion to ss records
      add :class_id, references(:classes, with: [school_id: :school_id], on_delete: :nothing),
        null: false

      add :student_record_id,
          references(:students_records, with: [school_id: :school_id], on_delete: :delete_all),
          null: false

      add :school_id, references(:schools, on_delete: :nothing), null: false
    end

    create index(:students_records_classes, [:class_id])
    create unique_index(:students_records_classes, [:student_record_id, :class_id])
  end
end
