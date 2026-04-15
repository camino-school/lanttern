defmodule Lanttern.Curricula.Curriculum do
  @moduledoc """
  The `Curriculum` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Curricula.CurriculumComponent
  alias Lanttern.Identity.Scope
  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          code: String.t() | nil,
          description: String.t() | nil,
          school: School.t() | Ecto.Association.NotLoaded.t(),
          school_id: pos_integer() | nil,
          curriculum_components: [CurriculumComponent.t()] | Ecto.Association.NotLoaded.t(),
          deactivated_at: DateTime.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "curricula" do
    field :name, :string
    field :code, :string
    field :description, :string
    field :deactivated_at, :utc_datetime

    belongs_to :school, School
    has_many :curriculum_components, CurriculumComponent

    timestamps()
  end

  @doc false
  def changeset(curriculum, attrs, %Scope{} = scope) do
    curriculum
    |> cast(attrs, [:name, :code, :description, :deactivated_at])
    |> validate_required([:name])
    |> put_change(:school_id, scope.school_id)
  end

  def activate_changeset(curriculum) do
    curriculum
    |> cast(%{}, [])
    |> put_change(:deactivated_at, nil)
  end

  def deactivate_changeset(curriculum) do
    curriculum
    |> cast(%{}, [])
    |> put_change(:deactivated_at, DateTime.utc_now(:second))
  end
end
