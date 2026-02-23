defmodule Lanttern.Repo.Migrations.AddSchoolIdToAgentConversations do
  use Ecto.Migration

  def change do
    alter table(:agent_conversations) do
      add :school_id, references(:schools, on_delete: :nothing), null: false
    end

    create index(:agent_conversations, [:school_id])
  end
end
