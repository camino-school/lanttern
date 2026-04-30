defmodule Lanttern.Repo.Migrations.AddIsMissingToAssessmentPointEntriesLog do
  use Ecto.Migration

  def change do
    alter table(:assessment_point_entries, prefix: "log") do
      add :is_missing, :boolean, null: false, default: false
    end
  end
end
