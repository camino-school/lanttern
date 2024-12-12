defmodule Lanttern.Repo.Migrations.DropIsParentFromSchoolCycles do
  use Ecto.Migration

  def change do
    alter table(:school_cycles) do
      remove :is_parent, :boolean, null: false, default: false
    end

    create constraint(
             :school_cycles,
             :prevent_self_reference_in_parent_cycle,
             check: "parent_cycle_id != id"
           )
  end
end
