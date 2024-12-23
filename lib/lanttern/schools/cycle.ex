defmodule Lanttern.Schools.Cycle do
  @moduledoc """
  The `Cycle` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  import LantternWeb.Gettext
  alias Lanttern.Schools.Class
  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          start_at: Date.t(),
          end_at: Date.t(),
          school: School.t(),
          school_id: pos_integer(),
          classes: [Class.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "school_cycles" do
    field :name, :string
    field :start_at, :date
    field :end_at, :date

    belongs_to :school, School
    belongs_to :parent_cycle, __MODULE__

    has_many :subcycles, __MODULE__, foreign_key: :parent_cycle_id
    has_many :classes, Class

    timestamps()
  end

  @doc false
  def changeset(cycle, attrs) do
    cycle
    |> cast(attrs, [:name, :start_at, :end_at, :school_id, :parent_cycle_id])
    |> validate_required([:name, :start_at, :end_at, :school_id])
    |> check_constraint(
      :end_at,
      name: :cycle_end_date_is_greater_than_start_date,
      message: gettext("End date should be greater than start date")
    )
    |> check_constraint(
      :parent_cycle_id,
      name: :prevent_self_reference_in_parent_cycle,
      message: gettext("A cycle can't be the parent of itself")
    )
    |> foreign_key_constraint(
      :parent_cycle_id,
      name: :school_cycles_parent_cycle_id_fkey,
      message: gettext("Using a parent cycle from a different school is not allowed")
    )
  end
end
