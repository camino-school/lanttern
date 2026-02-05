defmodule Lanttern.Repo.Migrations.AddGuardiansTable do
  use Ecto.Migration

  def change do
    create table(:guardians) do
      add :name, :string, null: false

      timestamps()
    end

    # create relationship many to many in table students_guardians
    create table(:students_guardians, primary_key: false) do
      add :student_id,
          references(:students, with: [school_id: :school_id], on_delete: :delete_all),
          primary_key: true
      add :guardian_id,
          references(:guardians, on_delete: :delete_all),
          primary_key: true
      add :school_id, references(:schools, on_delete: :nothing), null: false
    end
  end

  def down do
    drop table(:students_guardians)
    drop table(:guardians)
  end
end
