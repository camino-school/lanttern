defmodule Lanttern.Repo.Migrations.CreateAiAgents do
  use Ecto.Migration

  def change do
    create table(:ai_agents) do
      add :name, :text, null: false
      add :knowledge, :text
      add :personality, :text
      add :guardrails, :text
      add :instructions, :text
      add :school_id, references(:schools, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:ai_agents, [:school_id])
  end
end
