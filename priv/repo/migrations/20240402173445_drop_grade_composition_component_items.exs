defmodule Lanttern.Repo.Migrations.DropGradeCompositionComponentItems do
  use Ecto.Migration

  def up do
    drop table(:grade_composition_component_items)
  end

  def down do
    create table(:grade_composition_component_items) do
      add :weight, :float, null: false
      add :curriculum_item_id, references(:curriculum_items, on_delete: :nothing), null: false

      add :component_id,
          references(:grade_composition_components, on_delete: :delete_all),
          null: false

      timestamps()
    end

    create index(:grade_composition_component_items, [:curriculum_item_id])
    create index(:grade_composition_component_items, [:component_id])
  end
end
