defmodule Lanttern.Assessments.ActivityAssessmentPoint do
  use Ecto.Schema
  import Ecto.Changeset

  schema "activities_assessment_points" do
    field :position, :integer

    belongs_to :activity, Lanttern.LearningContext.Activity
    belongs_to :assessment_point, Lanttern.Assessments.AssessmentPoint

    timestamps()
  end

  @doc false
  def changeset(activity_assessment_point, attrs) do
    activity_assessment_point
    |> cast(attrs, [:position, :activity_id, :assessment_point_id])
    |> validate_required([:position, :activity_id, :assessment_point_id])
  end
end
