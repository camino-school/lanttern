defmodule Lanttern.Curricula.Curriculum do
  @moduledoc """
  The `Curriculum` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          code: String.t() | nil,
          description: String.t() | nil,
          school: School.t() | Ecto.Association.NotLoaded.t(),
          school_id: pos_integer() | nil,
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

    timestamps()
  end

  @doc false
  def changeset(curriculum, attrs) do
    curriculum
    |> cast(attrs, [:name, :code, :description, :deactivated_at])
    |> validate_required([:name])
  end
end
