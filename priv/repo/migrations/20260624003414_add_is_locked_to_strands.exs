defmodule Lanttern.Repo.Migrations.AddIsLockedToStrands do
  use Ecto.Migration

  def change do
    alter table(:strands) do
      add :is_locked, :boolean, null: false, default: false
    end
  end
end
