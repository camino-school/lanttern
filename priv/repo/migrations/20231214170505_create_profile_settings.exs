defmodule Lanttern.Repo.Migrations.CreateProfileSettings do
  use Ecto.Migration

  def change do
    create table(:profile_settings) do
      add :current_filters, :map
      add :profile_id, references(:profiles, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:profile_settings, [:profile_id])
  end
end
