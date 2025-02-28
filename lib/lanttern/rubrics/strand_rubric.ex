defmodule Lanttern.Rubrics.StrandRubric do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Curricula.CurriculumItem
  alias Lanttern.Grading.Scale
  alias Lanttern.LearningContext.Strand
  alias Lanttern.Rubrics.Rubric

  @type t :: %__MODULE__{
          id: pos_integer(),
          position: non_neg_integer(),
          is_differentiation: boolean(),
          strand_id: pos_integer(),
          strand: Strand.t() | Ecto.Association.NotLoaded.t(),
          rubric_id: pos_integer(),
          rubric: Rubric.t() | Ecto.Association.NotLoaded.t(),
          scale_id: pos_integer(),
          scale: Scale.t() | Ecto.Association.NotLoaded.t(),
          curriculum_item_id: pos_integer(),
          curriculum_item: CurriculumItem.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "strands_rubrics" do
    field :position, :integer, default: 0
    field :is_differentiation, :boolean, default: false

    belongs_to :strand, Strand
    belongs_to :rubric, Rubric
    belongs_to :scale, Scale
    belongs_to :curriculum_item, CurriculumItem

    timestamps()
  end

  @doc false
  def changeset(strand_rubric, attrs) do
    strand_rubric
    |> cast(attrs, [
      :is_differentiation,
      :position,
      :strand_id,
      :rubric_id,
      :scale_id,
      :curriculum_item_id
    ])
    |> validate_required([:strand_id, :rubric_id, :scale_id, :curriculum_item_id])
  end
end
