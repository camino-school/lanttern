defmodule Lanttern.Repo.Migrations.AddIsDiffToAssessmentPoints do
  use Ecto.Migration

  def change do
    alter table(:assessment_points) do
      add :is_differentiation, :boolean, null: false, default: false
    end
  end
end
