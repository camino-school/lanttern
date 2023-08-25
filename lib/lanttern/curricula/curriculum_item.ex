defmodule Lanttern.Curricula.CurriculumItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "curriculum_items" do
    field :name, :string
    field :code, :string

    has_many :grade_composition_component_items, Lanttern.Grading.CompositionComponentItem
    belongs_to :curriculum_component, Lanttern.Curricula.CurriculumComponent

    timestamps()
  end

  @doc false
  def changeset(curriculum_item, attrs) do
    curriculum_item
    |> cast(attrs, [:name, :code, :curriculum_component_id])
    |> validate_required([:name, :curriculum_component_id])
  end
end
