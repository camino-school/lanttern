defmodule Lanttern.Repo.Migrations.AddCurrentSchoolCycleToProfileSettings do
  use Ecto.Migration

  def change do
    alter table(:profile_settings) do
      add :current_school_cycle_id, references(:school_cycles, on_delete: :nilify_all)
    end

    create index(:profile_settings, [:current_school_cycle_id])
  end
end
