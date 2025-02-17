defmodule Lanttern.Repo.Migrations.CreateBoardMessages do
  use Ecto.Migration

  def change do
    create table(:board_messages) do
      add :name, :text, null: false
      add :description, :text, null: false
      add :send_to, :string, null: false
      add :archived_at, :utc_datetime
      add :school_id, references(:schools, on_delete: :nothing), null: false

      timestamps()
    end

    create unique_index(:board_messages, [:school_id, :id])

    create constraint(
             :board_messages,
             :valid_send_to,
             check: "send_to IN ('school', 'classes')"
           )
  end
end
