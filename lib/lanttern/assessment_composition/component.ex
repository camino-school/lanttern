defmodule Lanttern.AssessmentComposition.Component do
  @moduledoc """
  The `AssessmentComposition.Component` schema.

  Represents a single component (child assessment point) contributing to a
  composed (parent) assessment point. The `weight` field scales the component's
  value when computing sum or average compositions.
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Repo

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
    |> validate_component_not_composed()
    |> unique_constraint([:parent_id, :component_id])
    |> check_constraint(:component_id,
      name: :parent_and_component_must_differ,
      message: gettext("Component cannot be the same as the parent assessment point")
    )
  end

  # A composed assessment point cannot itself be a component of another
  # composition (cascading composition is intentionally not supported).
  defp validate_component_not_composed(changeset) do
    case get_field(changeset, :component_id) do
      nil ->
        changeset

      component_id ->
        composed? =
          Repo.exists?(
            from ap in AssessmentPoint,
              where: ap.id == ^component_id and ap.uses_composition == true
          )

        if composed? do
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
end
