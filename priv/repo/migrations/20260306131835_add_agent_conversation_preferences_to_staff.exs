defmodule Lanttern.Repo.Migrations.AddAgentConversationPreferencesToStaff do
  use Ecto.Migration

  def change do
    alter table(:staff) do
      add :agent_conversation_preferences, :text
    end
  end
end
