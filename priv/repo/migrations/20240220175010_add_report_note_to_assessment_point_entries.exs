defmodule Lanttern.Repo.Migrations.AddReportNoteToAssessmentPointEntries do
  use Ecto.Migration

  def change do
    alter table(:assessment_point_entries) do
      add :report_note, :text
    end
  end
end
