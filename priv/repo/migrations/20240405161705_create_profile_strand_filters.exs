defmodule Lanttern.Repo.Migrations.CreateProfileStrandFilters do
  use Ecto.Migration

  def change do
    create table(:profile_strand_filters) do
      add :profile_id, references(:profiles, on_delete: :delete_all), null: false
      add :strand_id, references(:strands, on_delete: :delete_all), null: false
      add :class_id, references(:classes, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:profile_strand_filters, [:profile_id])
    create index(:profile_strand_filters, [:strand_id])
    create unique_index(:profile_strand_filters, [:class_id, :strand_id, :profile_id])
  end
end
