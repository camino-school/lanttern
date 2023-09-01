defmodule Lanttern.Repo.Migrations.AddNameComponentUniqueConstraintToCurriculumItem do
  use Ecto.Migration

  def change do
    create unique_index(:curriculum_items, [:name, :curriculum_component_id])
    create unique_index(:curriculum_items, [:code, :curriculum_component_id])
  end
end
