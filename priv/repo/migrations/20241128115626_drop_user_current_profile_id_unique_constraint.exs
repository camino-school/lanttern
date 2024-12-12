defmodule Lanttern.Repo.Migrations.DropUserCurrentProfileIdUniqueConstraint do
  use Ecto.Migration

  def change do
    drop unique_index(:users, [:current_profile_id])
    create index(:users, [:current_profile_id])
  end
end
