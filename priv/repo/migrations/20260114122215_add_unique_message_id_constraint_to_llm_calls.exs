defmodule Lanttern.Repo.Migrations.AddUniqueMessageIdConstraintToLlmCalls do
  use Ecto.Migration

  def change do
    drop index(:llm_calls, [:message_id])
    create unique_index(:llm_calls, [:message_id])
  end
end
