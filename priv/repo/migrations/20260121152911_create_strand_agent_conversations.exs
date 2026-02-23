defmodule Lanttern.Repo.Migrations.CreateStrandAgentConversations do
  use Ecto.Migration

  def change do
    create table(:strand_agent_conversations, primary_key: false) do
      add :conversation_id, references(:agent_conversations, on_delete: :delete_all), null: false
      add :strand_id, references(:strands, on_delete: :delete_all), null: false
      add :lesson_id, references(:lessons, on_delete: :delete_all)
    end

    create index(:strand_agent_conversations, [:strand_id])
    create index(:strand_agent_conversations, [:lesson_id])
    create unique_index(:strand_agent_conversations, [:conversation_id])
  end
end
