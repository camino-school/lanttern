defmodule Lanttern.Repo.Migrations.AddReportInfoToAssessmentPoint do
  use Ecto.Migration

  def change do
    alter table(:assessment_points) do
      add :report_info, :text
    end
  end
end
