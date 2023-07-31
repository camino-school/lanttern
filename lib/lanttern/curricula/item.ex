defmodule Lanttern.Curricula.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "curriculum_items" do
    field :name, :string

    has_many :grade_composition_component_items, Lanttern.Grading.CompositionComponentItem,
      foreign_key: :curriculum_item_id

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
