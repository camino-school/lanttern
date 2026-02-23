defmodule Lanttern.Repo.Migrations.CreateAgentMessages do
  use Ecto.Migration

  def change do
    create table(:agent_messages) do
      add :role, :string, null: false
      add :content, :text
      add :conversation_id, references(:agent_conversations, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:agent_messages, [:conversation_id])
  end
end
