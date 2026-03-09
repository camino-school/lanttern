defmodule Lanttern.Schools.ClassStaffMember do
  @moduledoc """
    The `ClassStaffMember` schema
  """
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: pos_integer(),
          class_id: pos_integer(),
          staff_member_id: pos_integer(),
          position: integer(),
          role: String.t() | nil,
          class: Lanttern.Schools.Class.t() | Ecto.Association.NotLoaded.t(),
          staff_member: Lanttern.Schools.StaffMember.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "classes_staff_members" do
    belongs_to :class, Lanttern.Schools.Class
    belongs_to :staff_member, Lanttern.Schools.StaffMember

    field :position, :integer, default: 0
    field :role, :string

    timestamps()
  end

  def changeset(class_staff_member, attrs) do
    class_staff_member
    |> cast(attrs, [:class_id, :staff_member_id, :position, :role])
    |> validate_required([:class_id, :staff_member_id, :position])
    |> unique_constraint([:class_id, :staff_member_id])
  end
end
