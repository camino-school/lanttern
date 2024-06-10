defmodule Lanttern.Repo.Migrations.AddSelfAssessmentFieldsToAssessmentPointEntriesLog do
  use Ecto.Migration

  @prefix "log"

  def change do
    alter table(:assessment_point_entries, prefix: @prefix) do
      add :student_score, :float
      add :student_report_note, :text
      add :student_ordinal_value_id, :bigint
    end
  end
end
