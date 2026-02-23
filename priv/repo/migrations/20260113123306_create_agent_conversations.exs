defmodule Lanttern.Repo.Migrations.CreateAgentConversations do
  use Ecto.Migration

  def change do
    create table(:agent_conversations) do
      add :name, :text
      add :profile_id, references(:profiles, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:agent_conversations, [:profile_id])
  end
end
