defmodule Lanttern.Repo.Migrations.AddIsParentAndParentCycleIdToSchoolCycles do
  use Ecto.Migration

  def change do
    alter table(:school_cycles) do
      add :is_parent, :boolean, null: false, default: false

      add :parent_cycle_id,
          references(:school_cycles, with: [school_id: :school_id], on_delete: :nilify_all)
    end

    create index(:school_cycles, [:parent_cycle_id])
  end
end
