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

  @doc false
  def changeset(component, attrs) do
    component
    |> cast(attrs, [:weight, :parent_id, :component_id])
    |> validate_required([:weight, :parent_id, :component_id])
    |> validate_number(:weight, greater_than: 0)
    |> unique_constraint([:parent_id, :component_id])
    |> check_constraint(:component_id,
      name: :parent_and_component_must_differ,
      message: gettext("Component cannot be the same as the parent assessment point")
    )
  end
end
