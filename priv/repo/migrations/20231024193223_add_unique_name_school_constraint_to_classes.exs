defmodule Lanttern.Repo.Migrations.AddUniqueNameSchoolConstraintToClasses do
  use Ecto.Migration

  def change do
    create unique_index(:classes, [:name, :school_id])
  end
end
