defmodule Lanttern.Strands.StrandCurriculumItem do
  @moduledoc """
  The `StrandCurriculumItem` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Curricula.CurriculumItem
  alias Lanttern.LearningContext.Strand

  @type t :: %__MODULE__{
          id: pos_integer(),
          position: non_neg_integer(),
          strand: Strand.t() | Ecto.Association.NotLoaded.t(),
          strand_id: pos_integer(),
          curriculum_item: CurriculumItem.t() | Ecto.Association.NotLoaded.t(),
          curriculum_item_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "strand_curriculum_items" do
    field :position, :integer, default: 0

    belongs_to :strand, Strand
    belongs_to :curriculum_item, CurriculumItem

    timestamps()
  end

  @doc false
  def changeset(strand_curriculum_item, attrs) do
    strand_curriculum_item
    |> cast(attrs, [:position, :strand_id, :curriculum_item_id])
    |> validate_required([:position, :strand_id, :curriculum_item_id])
    |> unique_constraint([:strand_id, :curriculum_item_id],
      name: "strand_curriculum_items_curriculum_item_id_strand_id_index",
      message: gettext("Curriculum item already linked to this strand")
    )
  end
end
