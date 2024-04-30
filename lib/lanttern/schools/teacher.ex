defmodule Lanttern.Schools.Teacher do
  @moduledoc """
  The `Teacher` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          school: School.t(),
          school_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "teachers" do
    field :name, :string

    belongs_to :school, School

    timestamps()
  end

  @doc false
  def changeset(teacher, attrs) do
    teacher
    |> cast(attrs, [:name, :school_id])
    |> validate_required([:name, :school_id])
  end
end
