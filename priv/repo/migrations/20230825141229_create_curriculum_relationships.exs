defmodule Lanttern.Repo.Migrations.CreateCurriculumRelationships do
  use Ecto.Migration

  def change do
    create table(:curriculum_relationships) do
      add :type, :text, null: false
      add :curriculum_item_a_id, references(:curriculum_items, on_delete: :nothing), null: false
      add :curriculum_item_b_id, references(:curriculum_items, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:curriculum_relationships, [:curriculum_item_a_id])
    create index(:curriculum_relationships, [:curriculum_item_b_id])
    create unique_index(:curriculum_relationships, [:curriculum_item_a_id, :curriculum_item_b_id])

    create constraint(
             :curriculum_relationships,
             :curriculum_item_a_and_b_should_be_different,
             check: "curriculum_item_a_id <> curriculum_item_b_id"
           )
  end
end
