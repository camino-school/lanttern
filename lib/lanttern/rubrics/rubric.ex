defmodule Lanttern.Rubrics.Rubric do
  @moduledoc """
  The `Rubric` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Assessments.AssessmentPointEntry
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
          descriptors: [RubricDescriptor.t()],
          assessment_points: [AssessmentPoint.t()],
          diff_entries: [AssessmentPointEntry.t()],
          diff_students: [Student.t()],
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

    has_many :descriptors, RubricDescriptor, on_replace: :delete
    has_many :assessment_points, AssessmentPoint
    has_many :diff_entries, AssessmentPointEntry, foreign_key: :differentiation_rubric_id

    many_to_many :diff_students, Student,
      join_through: AssessmentPointEntry,
      join_keys: [differentiation_rubric_id: :id, student_id: :id]

    timestamps()
  end

  @doc false
  def changeset(rubric, attrs) do
    rubric
    |> cast(attrs, [
      :criteria,
      :is_differentiation,
      :position,
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
  end
end
