defmodule Lanttern.Repo.Migrations.CreateNotesAttachments do
  use Ecto.Migration

  def change do
    # creating unique constraints to allow composite foreign keys.
    # this guarantees, in the database level, that attachments
    # belongs to note author
    create unique_index(:notes, [:id, :author_id])
    create unique_index(:attachments, [:id, :owner_id])

    create table(:notes_attachments) do
      add :position, :integer, default: 0, null: false
      add :owner_id, references(:profiles, on_delete: :delete_all), null: false

      add :note_id, references(:notes, with: [owner_id: :author_id], on_delete: :delete_all),
        null: false

      add :attachment_id,
          references(:attachments, with: [owner_id: :owner_id], on_delete: :delete_all),
          null: false

      timestamps()
    end

    create index(:notes_attachments, [:owner_id])
    create index(:notes_attachments, [:note_id])
    create unique_index(:notes_attachments, [:attachment_id])
  end
end
