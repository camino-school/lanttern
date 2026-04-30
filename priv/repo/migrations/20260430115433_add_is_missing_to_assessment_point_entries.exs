defmodule Lanttern.Repo.Migrations.AddIsMissingToAssessmentPointEntries do
  use Ecto.Migration

  def change do
    alter table(:assessment_point_entries) do
      add :is_missing, :boolean, null: false, default: false
    end
  end
end
