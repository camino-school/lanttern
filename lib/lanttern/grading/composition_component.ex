defmodule Lanttern.Grading.CompositionComponent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "grade_composition_components" do
    field :name, :string
    field :weight, :float

    belongs_to :composition, Lanttern.Grading.Composition

    timestamps()
  end

  @doc false
  def changeset(composition_component, attrs) do
    composition_component
    |> cast(attrs, [:name, :weight, :composition_id])
    |> validate_required([:name, :weight, :composition_id])
  end
end
