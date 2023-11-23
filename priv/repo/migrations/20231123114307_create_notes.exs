defmodule Lanttern.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes) do
      add :description, :text, null: false
      add :author_id, references(:profiles, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:notes, [:author_id])
  end
end
