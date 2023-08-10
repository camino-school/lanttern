defmodule Lanttern.Repo.Migrations.AddIsRootAdminToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_root_admin, :boolean, null: false, default: false
    end
  end
end
