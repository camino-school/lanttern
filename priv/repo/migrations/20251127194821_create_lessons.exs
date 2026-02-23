defmodule Lanttern.Repo.Migrations.CreateLessons do
  use Ecto.Migration

  def change do
    create table(:lessons) do
      add :name, :text, null: false
      add :description, :text
      add :strand_id, references(:strands, on_delete: :nothing), null: false
      add :moment_id, references(:moments, on_delete: :nothing)
      add :position, :integer, default: 0, null: false

      timestamps()
    end

    create index(:lessons, [:strand_id])
    create index(:lessons, [:moment_id])
  end
end
