defmodule Lanttern.Repo.Migrations.AddStatusToAgentConversations do
  use Ecto.Migration

  def change do
    alter table(:agent_conversations) do
      add :status, :string, default: "idle", null: false
      add :last_error, :string
    end
  end
end
