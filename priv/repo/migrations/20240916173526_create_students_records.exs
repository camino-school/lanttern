defmodule Lanttern.Repo.Migrations.CreateStudentsRecords do
  use Ecto.Migration

  def change do
    create table(:students_records) do
      add :name, :text
      add :description, :text, null: false
      add :date, :date, null: false
      add :time, :time
      add :school_id, references(:schools, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:students_records, [:school_id])
  end
end
