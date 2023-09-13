defmodule Lanttern.Repo.Migrations.AddSchoolIdToStudents do
  use Ecto.Migration

  def change do
    alter table(:students) do
      add :school_id, references(:schools, on_delete: :nothing), null: false
    end

    create index(:students, [:school_id])
  end
end
