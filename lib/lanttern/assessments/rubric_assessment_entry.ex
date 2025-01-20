defmodule Lanttern.Assessments.RubricAssessmentEntry do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Rubrics.AssessmentPointRubric
  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer(),
          score: float(),
          student_score: float() | nil,
          assessment_point_rubric: AssessmentPointRubric.t() | Ecto.Association.NotLoaded.t(),
          assessment_point_rubric_id: pos_integer(),
          student: Student.t() | Ecto.Association.NotLoaded.t(),
          student_id: pos_integer(),
          ordinal_value: OrdinalValue.t() | Ecto.Association.NotLoaded.t() | nil,
          ordinal_value_id: pos_integer() | nil,
          student_ordinal_value: OrdinalValue.t() | Ecto.Association.NotLoaded.t() | nil,
          student_ordinal_value_id: pos_integer() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "rubrics_assessment_entries" do
    field :score, :float
    field :student_score, :float

    belongs_to :assessment_point_rubric, AssessmentPointRubric
    belongs_to :student, Student
    belongs_to :ordinal_value, OrdinalValue
    belongs_to :student_ordinal_value, OrdinalValue

    timestamps()
  end

  @doc false
  def changeset(rubric_assessment_entry, attrs) do
    rubric_assessment_entry
    |> cast(attrs, [
      :score,
      :student_score,
      :assessment_point_rubric_id,
      :student_id,
      :ordinal_value_id,
      :student_ordinal_value_id
    ])
    |> validate_required([:assessment_point_rubric_id, :student_id])
  end
end
