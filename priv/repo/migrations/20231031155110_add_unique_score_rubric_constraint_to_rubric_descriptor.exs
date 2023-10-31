defmodule Lanttern.Repo.Migrations.AddUniqueScoreRubricConstraintToRubricDescriptor do
  use Ecto.Migration

  def change do
    create unique_index(:rubric_descriptors, [:score, :rubric_id])
  end
end
