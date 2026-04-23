defmodule Lanttern.Repo.Migrations.AddSchoolIdAndDeactivatedAtToCurricula do
  use Ecto.Migration

  def change do
    alter table(:curricula) do
      add :school_id, references(:schools, on_delete: :nothing)
      add :deactivated_at, :utc_datetime
    end

    create index(:curricula, [:school_id])
  end
end
