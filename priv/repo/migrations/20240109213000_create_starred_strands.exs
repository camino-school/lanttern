defmodule Lanttern.Repo.Migrations.CreateStarredStrands do
  use Ecto.Migration

  def change do
    create table(:starred_strands, primary_key: false) do
      add :strand_id, references(:strands, on_delete: :delete_all), null: false
      add :profile_id, references(:profiles, on_delete: :delete_all), null: false
    end

    create index(:starred_strands, [:strand_id])
    create unique_index(:starred_strands, [:profile_id, :strand_id])
  end
end
