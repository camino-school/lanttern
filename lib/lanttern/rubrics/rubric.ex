defmodule Lanttern.Rubrics.Rubric do
  @moduledoc """
  The `Rubric` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Grading.Scale
  alias Lanttern.Rubrics.AssessmentPointRubric
  alias Lanttern.Rubrics.RubricDescriptor
  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer(),
          criteria: String.t(),
          is_differentiation: boolean(),
          scale: Scale.t(),
          scale_id: pos_integer(),
          parent_rubric: __MODULE__.t(),
          diff_for_rubric_id: pos_integer(),
          descriptors: [RubricDescriptor.t()],
          differentiation_rubrics: [__MODULE__.t()],
          assessment_points: [AssessmentPoint.t()],
          students: [Student.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "rubrics" do
    field :criteria, :string
    # to do: remove, we're not using it
    field :is_differentiation, :boolean, default: false

    # use this to preload curriculum info in strand rubric context
    # (curriculum item info comes from relationship with assessment point)
    field :curriculum_item, :map, virtual: true

    # use this to keep track of assessment point rubric flag
    # without preloading the full assessment point rubric
    field :is_diff, :boolean, virtual: true

    # used to keep track of the assessment point in some queries
    # without preloading assessment point rubric
    field :assessment_point_id, :id, virtual: true

    belongs_to :scale, Scale
    belongs_to :parent_rubric, __MODULE__, foreign_key: :diff_for_rubric_id

    has_many :descriptors, RubricDescriptor, on_replace: :delete
    has_many :differentiation_rubrics, __MODULE__, foreign_key: :diff_for_rubric_id
    has_many :assessment_points_rubrics, AssessmentPointRubric
    has_many :assessment_points, through: [:assessment_points_rubrics, :assessment_point]

    # to do: adjust to use the new assessment point rubric entries
    many_to_many :students, Student, join_through: "differentiation_rubrics_students"

    timestamps()
  end

  @doc false
  def changeset(rubric, attrs) do
    rubric
    |> cast(attrs, [:criteria, :is_differentiation, :diff_for_rubric_id, :scale_id])
    |> validate_required([:criteria, :is_differentiation, :scale_id])
    |> cast_assoc(:descriptors)
    |> foreign_key_constraint(
      :diff_for_rubric_id,
      name: :rubrics_diff_for_rubric_id_fkey,
      message:
        "This rubric has linked differentiation rubrics. Deleting it is not allowed, as it would cause data loss."
    )
  end
end
