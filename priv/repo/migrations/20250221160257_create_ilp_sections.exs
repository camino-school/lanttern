defmodule Lanttern.Repo.Migrations.CreateIlpSections do
  use Ecto.Migration

  def change do
    create table(:ilp_sections) do
      add :name, :text, null: false
      add :position, :integer, default: 0, null: false
      add :template_id, references(:ilp_templates, on_delete: :delete_all), null: false

      timestamps()
    end

    # create as unique index with id to allow composite foreign keys
    create unique_index(:ilp_sections, [:template_id, :id])
    create index(:ilp_sections, [:position])
  end
end
