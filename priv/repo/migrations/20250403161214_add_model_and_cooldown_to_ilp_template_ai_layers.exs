defmodule Lanttern.Repo.Migrations.AddModelAndCooldownToIlpTemplateAiLayers do
  use Ecto.Migration

  def change do
    alter table(:ilp_template_ai_layers) do
      add :model, :text
      add :cooldown_minutes, :integer, default: 0, null: false
    end
  end
end
