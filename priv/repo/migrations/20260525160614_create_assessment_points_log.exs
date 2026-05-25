defmodule Lanttern.Repo.Migrations.CreateAssessmentPointsLog do
  use Ecto.Migration

  @prefix "log"

  def change do
    create table(:assessment_points, prefix: @prefix) do
      add :assessment_point_id, :bigint, null: false
      add :profile_id, :bigint, null: false
      add :operation, :text, null: false
      add :name, :text
      add :datetime, :utc_datetime
      add :description, :text
      add :report_info, :text
      add :position, :integer
      add :is_differentiation, :boolean, default: false
      add :is_hidden, :boolean, default: false
      add :composition_type, :text
      add :curriculum_item_id, :bigint
      add :scale_id, :bigint
      add :rubric_id, :bigint
      add :lesson_id, :bigint
      add :moment_id, :bigint
      add :strand_id, :bigint

      timestamps(updated_at: false)
    end

    create constraint(
             :assessment_points,
             :valid_operations,
             prefix: @prefix,
             check: "operation IN ('CREATE', 'UPDATE', 'DELETE')"
           )

    create index(:assessment_points, [:assessment_point_id], prefix: @prefix)
  end
end
