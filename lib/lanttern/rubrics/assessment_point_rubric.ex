defmodule Lanttern.Rubrics.AssessmentPointRubric do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Assessments.RubricAssessmentEntry
  alias Lanttern.Grading.Scale
  alias Lanttern.Rubrics.Rubric
  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer(),
          position: integer(),
          is_diff: boolean(),
          assessment_point: AssessmentPoint.t() | Ecto.Association.NotLoaded.t(),
          assessment_point_id: pos_integer(),
          rubric: Rubric.t() | Ecto.Association.NotLoaded.t(),
          rubric_id: pos_integer(),
          scale: Scale.t() | Ecto.Association.NotLoaded.t(),
          scale_id: pos_integer(),
          rubric_assessment_entries: [RubricAssessmentEntry.t()] | Ecto.Association.NotLoaded.t(),
          students: [Student.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "assessment_points_rubrics" do
    field :position, :integer, default: 0
    field :is_diff, :boolean, default: false

    belongs_to :assessment_point, AssessmentPoint
    belongs_to :rubric, Rubric
    belongs_to :scale, Scale

    has_many :rubric_assessment_entries, RubricAssessmentEntry
    has_many :students, through: [:rubric_assessment_entries, :student], preload_order: :name

    timestamps()
  end

  @doc false
  def changeset(assessment_point_rubric, attrs) do
    assessment_point_rubric
    |> cast(attrs, [:position, :is_diff, :assessment_point_id, :rubric_id, :scale_id])
    |> validate_required([:position, :is_diff, :assessment_point_id, :rubric_id, :scale_id])
  end
end
