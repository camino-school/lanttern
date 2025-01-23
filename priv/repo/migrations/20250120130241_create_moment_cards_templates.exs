defmodule Lanttern.Repo.Migrations.CreateMomentCardsTemplates do
  use Ecto.Migration

  def change do
    create table(:moment_cards_templates) do
      add :name, :text, null: false
      add :template, :text, null: false
      add :instructions, :text
      add :position, :integer, default: 0, null: false
      add :school_id, references(:schools, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:moment_cards_templates, [:school_id])
    create index(:moment_cards_templates, [:position])
  end
end
