defmodule Lanttern.Repo.Migrations.CreateStrandsNotesAndActivitiesNotesTables do
  use Ecto.Migration

  def change do
    # creating unique constraints to allow composite foreign keys.
    # this guarantees, in the database level, that we have only one note
    # per user per strand/activity

    # removing existing "notes_author_id_index" to prevent unnecessary index
    drop index(:notes, [:author_id])
    create unique_index(:notes, [:author_id, :id])

    create table(:strands_notes, primary_key: false) do
      add :strand_id, references(:strands, on_delete: :delete_all), null: false

      add :note_id, references(:notes, with: [author_id: :author_id], on_delete: :delete_all),
        null: false

      add :author_id, references(:profiles, on_delete: :delete_all), null: false
    end

    create index(:strands_notes, [:strand_id])
    create index(:strands_notes, [:note_id])
    create unique_index(:strands_notes, [:author_id, :strand_id])

    create table(:activities_notes, primary_key: false) do
      add :activity_id, references(:activities, on_delete: :delete_all), null: false

      add :note_id, references(:notes, with: [author_id: :author_id], on_delete: :delete_all),
        null: false

      add :author_id, references(:profiles, on_delete: :delete_all), null: false
    end

    create index(:activities_notes, [:activity_id])
    create index(:activities_notes, [:note_id])
    create unique_index(:activities_notes, [:author_id, :activity_id])
  end
end
