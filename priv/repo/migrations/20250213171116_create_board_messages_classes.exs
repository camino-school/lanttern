defmodule Lanttern.Repo.Migrations.CreateBoardMessagesClasses do
  use Ecto.Migration

  def change do
    # use composite foreign keys to guarantee,
    # in the database level, that message and class
    # belong to the same school

    create table(:board_messages_classes, primary_key: false) do
      add :message_id,
          references(:board_messages,
            with: [school_id: :school_id],
            on_delete: :delete_all
          ),
          primary_key: true

      # in the future we will handle how to cascade class and school deletion to messages
      add :class_id, references(:classes, with: [school_id: :school_id], on_delete: :nothing),
        primary_key: true

      add :school_id, references(:schools, on_delete: :nothing), null: false
    end
  end
end
