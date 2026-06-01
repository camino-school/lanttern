defmodule Lanttern.AssessmentComposition.Component do
  @moduledoc """
  The `AssessmentComposition.Component` schema.

  Represents a single component (child assessment point) contributing to a
  composed (parent) assessment point. The `weight` field scales the component's
  value when computing sum or average compositions.
  """

  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Assessments.AssessmentPoint

  @type t :: %__MODULE__{
          id: pos_integer(),
          weight: float(),
          parent_id: pos_integer(),
          parent: AssessmentPoint.t() | Ecto.Association.NotLoaded.t(),
          component_id: pos_integer(),
          component: AssessmentPoint.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "assessment_point_components" do
    field :weight, :float, default: 1.0

    belongs_to :parent, AssessmentPoint
    belongs_to :component, AssessmentPoint

    timestamps()
  end

  @doc """
  Component changeset.

  `composed_component_ids` is the list of component ids the caller has already
  determined (via a context query) to be composed assessment points. A composed
  assessment point cannot itself be a component of another composition (cascading
  composition is intentionally not supported), so the changeset rejects a
  `component_id` found in that list.
  """
  def changeset(component, attrs, composed_component_ids \\ []) do
    component
    |> cast(attrs, [:weight, :parent_id, :component_id])
    |> validate_required([:weight, :parent_id, :component_id])
    |> validate_number(:weight, greater_than: 0)
    |> validate_component_not_composed(composed_component_ids)
    |> unique_constraint([:parent_id, :component_id])
    |> check_constraint(:component_id,
      name: :parent_and_component_must_differ,
      message: gettext("Component cannot be the same as the parent assessment point")
    )
  end

  defp validate_component_not_composed(changeset, composed_component_ids) do
    component_id = get_field(changeset, :component_id)

    if not is_nil(component_id) and component_id in composed_component_ids do
      add_error(
        changeset,
        :component_id,
        gettext("A composed assessment point cannot be used as a component")
      )
    else
      changeset
    end
  end
end
