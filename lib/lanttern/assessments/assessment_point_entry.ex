defmodule Lanttern.Assessments.AssessmentPointEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "assessment_point_entries" do
    field :observation, :string
    field :score, :float

    belongs_to :assessment_point, Lanttern.Assessments.AssessmentPoint
    belongs_to :student, Lanttern.Schools.Student
    belongs_to :ordinal_value, Lanttern.Grading.OrdinalValue

    timestamps()
  end

  @doc false
  def changeset(assessment_point_entry, attrs) do
    assessment_point_entry
    |> cast(attrs, [:observation, :score, :assessment_point_id, :student_id, :ordinal_value_id])
    |> validate_required([:assessment_point_id, :student_id])
  end
end
