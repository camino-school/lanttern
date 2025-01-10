defmodule Lanttern.Repo.Migrations.CreateStudentsCycleInfo do
  use Ecto.Migration

  def change do
    # we'll use unique constraints to allow composite foreign keys.
    # this guarantees, in the database level, that student and cycle
    # belong to the same school

    create table(:students_cycle_info) do
      add :school_info, :text
      add :family_info, :text
      add :profile_picture_url, :text

      add :student_id, references(:students, with: [school_id: :school_id], on_delete: :nothing),
        # null constraint fixed in Lanttern.Repo.Migrations.FixStudentsCycleInfoNullConstraints
        required: true

      add :cycle_id,
          references(:school_cycles, with: [school_id: :school_id], on_delete: :nothing),
          # null constraint fixed in Lanttern.Repo.Migrations.FixStudentsCycleInfoNullConstraints
          required: true

      add :school_id, references(:schools, on_delete: :nothing),
        # null constraint fixed in Lanttern.Repo.Migrations.FixStudentsCycleInfoNullConstraints
        required: true

      timestamps()
    end

    create index(:students_cycle_info, [:student_id])
    create unique_index(:students_cycle_info, [:cycle_id, :student_id])
    create index(:students_cycle_info, [:school_id])
  end
end
