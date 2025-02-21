defmodule Lanttern.Repo.Migrations.CreateIlpComponents do
  use Ecto.Migration

  def change do
    create table(:ilp_components) do
      add :name, :text, null: false
      add :position, :integer, default: 0, null: false

      add :section_id,
          references(:ilp_sections, with: [template_id: :template_id], on_delete: :delete_all),
          null: false

      add :template_id, references(:ilp_templates, on_delete: :delete_all), null: false

      timestamps()
    end

    # create as unique index with id to allow composite foreign keys
    create unique_index(:ilp_components, [:template_id, :id])
    create index(:ilp_components, [:section_id])
    create index(:ilp_components, [:position])
  end
end
