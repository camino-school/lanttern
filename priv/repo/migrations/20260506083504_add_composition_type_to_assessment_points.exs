defmodule Lanttern.Repo.Migrations.AddCompositionTypeToAssessmentPoints do
  use Ecto.Migration

  def change do
    alter table(:assessment_points) do
      add :composition_type, :string
    end
  end
end
