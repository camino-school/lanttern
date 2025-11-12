defmodule Lanttern.Repo.Migrations.CreateMessageAttachments do
  use Ecto.Migration

  def change do
    create table(:message_attachments) do
      add :position, :integer, default: 0, null: false

      add :owner_id, references(:profiles, on_delete: :delete_all), null: false
      add :message_id, references(:messages, on_delete: :delete_all), null: false

      add :attachment_id,
          references(:attachments, with: [owner_id: :owner_id], on_delete: :delete_all),
          null: false

      timestamps()
    end

    create index(:message_attachments, [:owner_id])
    create index(:message_attachments, [:attachment_id])
    create index(:message_attachments, [:message_id])
  end
end
