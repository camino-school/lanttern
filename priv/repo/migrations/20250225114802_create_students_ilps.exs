defmodule Lanttern.Repo.Migrations.CreateStudentsIlps do
  use Ecto.Migration

  def change do
    create table(:students_ilps) do
      add :teacher_notes, :text

      add :template_id,
          references(:ilp_templates, with: [school_id: :school_id], on_delete: :nothing),
          null: false

      add :student_id, references(:students, with: [school_id: :school_id], on_delete: :nothing),
        null: false

      add :cycle_id,
          references(:school_cycles, with: [school_id: :school_id], on_delete: :nothing),
          null: false

      add :school_id, references(:schools, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:students_ilps, [:template_id])
    create index(:students_ilps, [:cycle_id])
    create unique_index(:students_ilps, [:student_id, :id])
    create index(:students_ilps, [:school_id])

    # add update_of_ilp_id after setting student_id id unique index
    alter table(:students_ilps) do
      add :update_of_ilp_id,
          references(:students_ilps, with: [student_id: :student_id], on_delete: :nothing)
    end

    # we can't have more than one update from the same ilp
    create unique_index(:students_ilps, [:update_of_ilp_id])

    # we can't have more than one "base" ILP (not update) for the same student/template/cycle
    create unique_index(:students_ilps, [:student_id, :template_id, :cycle_id, :update_of_ilp_id],
             nulls_distinct: false
           )
  end
end
