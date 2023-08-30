defmodule Lanttern.Repo.Migrations.AddNameAndCodeCurriculumUniqueConstraintToCurriculumComponent do
  use Ecto.Migration

  def change do
    create unique_index(:curriculum_components, [:name, :curriculum_id])
    create unique_index(:curriculum_components, [:code, :curriculum_id])
  end
end
