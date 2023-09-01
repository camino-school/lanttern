defmodule Lanttern.Grading.CompositionComponentItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "grade_composition_component_items" do
    field :weight, :float

    belongs_to :curriculum_item, Lanttern.Curricula.CurriculumItem
    belongs_to :component, Lanttern.Grading.CompositionComponent

    timestamps()
  end

  @doc false
  def changeset(composition_component_item, attrs) do
    composition_component_item
    |> cast(attrs, [:weight, :curriculum_item_id, :component_id])
    |> validate_required([:weight, :curriculum_item_id, :component_id])
  end
end
