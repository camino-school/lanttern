defmodule Lanttern.Repo.Migrations.AddSchoolIdToClasses do
  use Ecto.Migration

  def change do
    alter table(:classes) do
      add :school_id, references(:schools, on_delete: :nothing), null: false
    end

    create index(:classes, [:school_id])
  end
end
