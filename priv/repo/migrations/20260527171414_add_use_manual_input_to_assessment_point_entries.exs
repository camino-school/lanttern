defmodule Lanttern.Repo.Migrations.AddUseManualInputToAssessmentPointEntries do
  use Ecto.Migration

  def change do
    alter table(:assessment_point_entries) do
      add :use_manual_input, :boolean, null: false, default: false
    end

    alter table(:assessment_point_entries, prefix: "log") do
      add :use_manual_input, :boolean, null: false, default: false
    end
  end
end
