defmodule Lanttern.Rubrics.Rubric do
  @moduledoc """
  The `Rubric` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Curricula.CurriculumItem
  alias Lanttern.Grading.Scale
  alias Lanttern.LearningContext.Strand
  alias Lanttern.Rubrics.RubricDescriptor
  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer(),
          criteria: String.t(),
          is_differentiation: boolean(),
          position: non_neg_integer(),
          scale_id: pos_integer(),
          scale: Scale.t() | Ecto.Association.NotLoaded.t(),
          strand_id: pos_integer(),
          strand: Strand.t() | Ecto.Association.NotLoaded.t(),
          curriculum_item_id: pos_integer(),
          curriculum_item: CurriculumItem.t() | Ecto.Association.NotLoaded.t(),
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
    field :is_differentiation, :boolean, default: false
    field :position, :integer, default: 0

    belongs_to :scale, Scale
    belongs_to :strand, Strand
    belongs_to :curriculum_item, CurriculumItem
    belongs_to :parent_rubric, __MODULE__, foreign_key: :diff_for_rubric_id

    has_many :descriptors, RubricDescriptor, on_replace: :delete
    has_many :differentiation_rubrics, __MODULE__, foreign_key: :diff_for_rubric_id
    has_many :assessment_points, AssessmentPoint

    many_to_many :students, Student, join_through: "differentiation_rubrics_students"

    timestamps()
  end

  @doc false
  def changeset(rubric, attrs) do
    rubric
    |> cast(attrs, [
      :criteria,
      :is_differentiation,
      :position,
      :diff_for_rubric_id,
      :scale_id,
      :strand_id,
      :curriculum_item_id
    ])
    |> validate_required([
      :criteria,
      :is_differentiation,
      :scale_id,
      :strand_id,
      :curriculum_item_id
    ])
    |> cast_assoc(:descriptors)
    |> foreign_key_constraint(
      :diff_for_rubric_id,
      name: :rubrics_diff_for_rubric_id_fkey,
      message:
        "This rubric has linked differentiation rubrics. Deleting it is not allowed, as it would cause data loss."
    )
  end
end
