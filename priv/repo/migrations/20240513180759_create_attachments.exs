defmodule Lanttern.Repo.Migrations.CreateAttachments do
  use Ecto.Migration

  def change do
    create table(:attachments) do
      add :name, :text, null: false
      add :description, :text
      add :link, :text, null: false
      add :is_external, :boolean, default: false, null: false
      add :owner_id, references(:profiles, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:attachments, [:owner_id])
  end
end
