defmodule Lanttern.Repo.Migrations.CreateIlpTemplateAiLayers do
  use Ecto.Migration

  def change do
    create table(:ilp_template_ai_layers, primary_key: false) do
      add :template_id, references(:ilp_templates, on_delete: :delete_all), primary_key: true
      add :revision_instructions, :text

      timestamps()
    end
  end
end
