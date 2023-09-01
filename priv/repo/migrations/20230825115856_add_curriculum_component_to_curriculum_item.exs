defmodule Lanttern.Repo.Migrations.AddCurriculumComponentToCurriculumItem do
  use Ecto.Migration

  def change do
    alter table(:curriculum_items) do
      add :code, :text

      add :curriculum_component_id, references(:curriculum_components, on_delete: :nothing),
        null: false
    end

    create index(:curriculum_items, [:curriculum_component_id])
  end
end
