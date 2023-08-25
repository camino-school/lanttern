defmodule Lanttern.Curricula.CurriculumItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "curriculum_items" do
    field :name, :string

    has_many :grade_composition_component_items, Lanttern.Grading.CompositionComponentItem

    timestamps()
  end

  @doc false
  def changeset(curriculum_item, attrs) do
    curriculum_item
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
