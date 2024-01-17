defmodule Lanttern.Repo.Migrations.DropStrandCurriculumItems do
  use Ecto.Migration

  def up do
    drop table(:strand_curriculum_items)
  end

  def down do
    create table(:strand_curriculum_items) do
      add :position, :integer, null: false, default: 0
      add :strand_id, references(:strands, on_delete: :delete_all), null: false
      add :curriculum_item_id, references(:curriculum_items, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:strand_curriculum_items, [:strand_id])
    create unique_index(:strand_curriculum_items, [:curriculum_item_id, :strand_id])
  end
end
