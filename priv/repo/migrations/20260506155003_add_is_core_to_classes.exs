defmodule Lanttern.Repo.Migrations.AddIsCoreToClasses do
  use Ecto.Migration

  def change do
    alter table(:classes) do
      add :is_core, :boolean, null: false, default: true
    end
  end
end
