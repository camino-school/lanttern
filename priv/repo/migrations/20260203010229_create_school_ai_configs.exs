defmodule Lanttern.Repo.Migrations.CreateSchoolAiConfigs do
  use Ecto.Migration

  def change do
    create table(:school_ai_configs) do
      add :base_model, :text
      add :knowledge, :text
      add :guardrails, :text
      add :school_id, references(:schools, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:school_ai_configs, [:school_id])
  end
end
