defmodule Lanttern.Repo.Migrations.AdjustClassesNameUniqueNameConstraint do
  use Ecto.Migration

  def change do
    drop unique_index(:classes, [:name, :school_id])
    create unique_index(:classes, [:name, :school_id, :cycle_id])
  end
end
