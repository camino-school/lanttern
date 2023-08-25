defmodule Lanttern.Curricula.CurriculumRelationship do
  use Ecto.Schema
  import Ecto.Changeset

  schema "curriculum_relationships" do
    field :type, :string

    belongs_to :curriculum_item_a, Lanttern.Curricula.CurriculumItem
    belongs_to :curriculum_item_b, Lanttern.Curricula.CurriculumItem

    timestamps()
  end

  @doc false
  def changeset(curriculum_relationship, attrs) do
    curriculum_relationship
    |> cast(attrs, [:curriculum_item_a_id, :curriculum_item_b_id, :type])
    |> validate_required([:curriculum_item_a_id, :curriculum_item_b_id, :type])
    |> check_constraint(
      :curriculum_item_b_id,
      name: :curriculum_item_a_and_b_should_be_different,
      message: "Relationships require two different curriculum items"
    )
    |> validate_format(
      :type,
      ~r/cross|hierarchical/,
      message: "Relatioship type should be cross or hierarchical"
    )
  end
end
