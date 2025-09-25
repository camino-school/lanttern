defmodule Lanttern.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :name, :text, null: false
      add :description, :text, null: false
      add :send_to, :string, null: false
      add :archived_at, :utc_datetime
      add :school_id, references(:schools, on_delete: :nothing), null: false
      add :subtitle, :string
      add :color, :string
      add :cover, :string
      add :position, :integer, default: 0, null: false

      add :section_id, references(:sections, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:messages, [:school_id, :id])

    create constraint(:messages, :valid_send_to, check: "send_to IN ('school', 'classes')")

    create table(:messages_classes) do
      add :message_id,
          references(:messages, with: [school_id: :school_id], on_delete: :delete_all),
          primary_key: true

      # in the future we will handle how to cascade class and school deletion to messages
      add :class_id, references(:classes, with: [school_id: :school_id], on_delete: :nothing),
        primary_key: true

      add :school_id, references(:schools, on_delete: :nothing), null: false
    end
  end
end
