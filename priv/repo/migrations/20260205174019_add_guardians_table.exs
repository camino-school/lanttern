defmodule Lanttern.Repo.Migrations.AddGuardiansTable do
  use Ecto.Migration

  def up do
    create table(:guardians) do
      add :name, :string, null: false
      add :school_id, references(:schools, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:guardians, [:school_id])

    # create relationship many to many in table students_guardians
    create table(:students_guardians, primary_key: false) do
      add :student_id,
          references(:students, on_delete: :delete_all),
          primary_key: true
      add :guardian_id,
          references(:guardians, on_delete: :delete_all),
          primary_key: true
    end

    create index(:students_guardians, [:student_id])
    create index(:students_guardians, [:guardian_id])
    create unique_index(:students_guardians, [:student_id, :guardian_id])
  end

  def down do
    drop table(:students_guardians)
    drop table(:guardians)
  end
end
