defmodule Lanttern.Schools.StaffMember do
  @moduledoc """
  The `StaffMember` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Identity.Profile
  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          profile_picture_url: String.t() | nil,
          role: String.t(),
          school: School.t(),
          school_id: pos_integer(),
          profile: Profile.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "staff" do
    field :name, :string
    field :profile_picture_url, :string
    field :role, :string, default: "Teacher"
    field :disabled_at, :utc_datetime

    # this field is used in the context of staff member form,
    # and handled by staff member create and update functions
    field :email, :string, virtual: true

    belongs_to :school, School

    has_one :profile, Profile

    timestamps()
  end

  @doc false
  def changeset(staff_member, attrs) do
    staff_member
    |> cast(attrs, [:name, :school_id, :profile_picture_url, :role, :disabled_at])
    |> validate_required([:name, :school_id, :role])
  end
end
