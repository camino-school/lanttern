defmodule Lanttern.Schools.StaffMember do
  @moduledoc """
  The `StaffMember` schema
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

  schema "staff" do
    field :name, :string

    belongs_to :school, School

    timestamps()
  end

  @doc false
  def changeset(staff_member, attrs) do
    staff_member
    |> cast(attrs, [:name, :school_id])
    |> validate_required([:name, :school_id])
  end
end
