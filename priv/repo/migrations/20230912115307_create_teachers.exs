defmodule Lanttern.Repo.Migrations.CreateTeachers do
  use Ecto.Migration

  def change do
    create table(:teachers) do
      add :name, :text, null: false
      add :school_id, references(:schools, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:teachers, [:school_id])
  end
end
