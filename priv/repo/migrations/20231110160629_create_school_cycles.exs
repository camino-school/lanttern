defmodule Lanttern.Repo.Migrations.CreateSchoolCycles do
  use Ecto.Migration

  def change do
    create table(:school_cycles) do
      add :name, :text, null: false
      add :start_at, :date, null: false
      add :end_at, :date, null: false
      add :school_id, references(:schools, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:school_cycles, [:school_id])

    create constraint(
             :school_cycles,
             :cycle_end_date_is_greater_than_start_date,
             check: "start_at < end_at"
           )
  end
end
