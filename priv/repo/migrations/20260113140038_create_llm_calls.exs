defmodule Lanttern.Repo.Migrations.CreateLlmCalls do
  use Ecto.Migration

  def change do
    create table(:llm_calls) do
      add :prompt_tokens, :integer, default: 0
      add :completion_tokens, :integer, default: 0
      add :model, :string
      add :message_id, references(:agent_messages, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:llm_calls, [:message_id])
  end
end
