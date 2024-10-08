defmodule Lanttern.Repo.Migrations.AddPermissionsToProfileSettings do
  use Ecto.Migration

  def change do
    alter table(:profile_settings) do
      add :permissions, {:array, :text}, null: false, default: []
    end
  end
end
