defmodule Lanttern.Curricula.StrandCurriculumItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "strand_curriculum_items" do
    field :position, :integer

    belongs_to :strand, Lanttern.LearningContext.Strand
    belongs_to :curriculum_item, Lanttern.Curricula.CurriculumItem

    timestamps()
  end

  @doc false
  def changeset(strand_curriculum_item, attrs) do
    strand_curriculum_item
    |> cast(attrs, [:position, :strand_id, :curriculum_item_id])
    |> validate_required([:position, :strand_id, :curriculum_item_id])
  end
end
