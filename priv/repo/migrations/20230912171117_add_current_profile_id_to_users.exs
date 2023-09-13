defmodule Lanttern.Repo.Migrations.AddCurrentProfileIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :current_profile_id, references(:profiles, on_delete: :nilify_all)
    end

    create unique_index(:users, [:current_profile_id])
  end
end
