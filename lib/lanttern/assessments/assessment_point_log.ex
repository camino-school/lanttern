defmodule Lanttern.Assessments.AssessmentPointLog do
  @moduledoc """
  The `AssessmentPointLog` schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @behaviour Lanttern.AuditLog

  @schema_prefix "log"
  schema "assessment_points" do
    field :assessment_point_id, :integer
    field :profile_id, :integer
    field :operation, :string
    field :name, :string
    field :datetime, :utc_datetime
    field :description, :string
    field :report_info, :string
    field :position, :integer
    field :is_differentiation, :boolean
    field :is_hidden, :boolean
    field :uses_composition, :boolean
    field :curriculum_item_id, :integer
    field :scale_id, :integer
    field :rubric_id, :integer
    field :lesson_id, :integer
    field :moment_id, :integer
    field :strand_id, :integer

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(assessment_point_log, attrs) do
    assessment_point_log
    |> cast(attrs, [
      :assessment_point_id,
      :profile_id,
      :operation,
      :name,
      :datetime,
      :description,
      :report_info,
      :position,
      :is_differentiation,
      :is_hidden,
      :uses_composition,
      :curriculum_item_id,
      :scale_id,
      :rubric_id,
      :lesson_id,
      :moment_id,
      :strand_id
    ])
    |> validate_required([:assessment_point_id, :profile_id, :operation])
  end

  @impl Lanttern.AuditLog
  def build_log_attrs(%Lanttern.Assessments.AssessmentPoint{} = assessment_point) do
    assessment_point = Lanttern.Repo.preload(assessment_point, [:classes])

    %{
      assessment_point_id: assessment_point.id,
      name: assessment_point.name,
      datetime: assessment_point.datetime,
      description: assessment_point.description,
      report_info: assessment_point.report_info,
      position: assessment_point.position,
      is_differentiation: assessment_point.is_differentiation,
      is_hidden: assessment_point.is_hidden,
      uses_composition: assessment_point.uses_composition,
      curriculum_item_id: assessment_point.curriculum_item_id,
      scale_id: assessment_point.scale_id,
      rubric_id: assessment_point.rubric_id,
      lesson_id: assessment_point.lesson_id,
      moment_id: assessment_point.moment_id,
      strand_id: assessment_point.strand_id
    }
  end
end
