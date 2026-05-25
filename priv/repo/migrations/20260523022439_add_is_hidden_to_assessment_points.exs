defmodule Lanttern.Repo.Migrations.AddIsHiddenToAssessmentPoints do
  use Ecto.Migration

  def change do
    alter table(:assessment_points) do
      add :is_hidden, :boolean, null: false, default: false
    end
  end
end
