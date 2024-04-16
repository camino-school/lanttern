defmodule Lanttern.Repo.Migrations.CreateAssessmentPointEntries do
  use Ecto.Migration

  @prefix "log"

  def change do
    execute "CREATE SCHEMA IF NOT EXISTS log", ""

    create table(:assessment_point_entries, prefix: @prefix) do
      add :assessment_point_entry_id, :bigint, null: false
      add :profile_id, :bigint, null: false
      add :operation, :text, null: false
      add :observation, :text
      add :score, :float
      add :assessment_point_id, :bigint, null: false
      add :student_id, :bigint, null: false
      add :ordinal_value_id, :bigint
      add :scale_id, :bigint, null: false
      add :scale_type, :text, null: false
      add :differentiation_rubric_id, :bigint
      add :report_note, :text

      timestamps(updated_at: false)
    end

    create constraint(
             :assessment_point_entries,
             :valid_operations,
             prefix: @prefix,
             check: "operation IN ('CREATE', 'UPDATE', 'DELETE')"
           )
  end
end
