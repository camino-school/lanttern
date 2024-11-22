defmodule Lanttern.Schools.Cycle do
  @moduledoc """
  The `Cycle` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          start_at: Date.t(),
          end_at: Date.t(),
          is_parent: boolean(),
          school: School.t(),
          school_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "school_cycles" do
    field :name, :string
    field :start_at, :date
    field :end_at, :date
    field :is_parent, :boolean, default: false

    belongs_to :school, School
    belongs_to :parent_cycle, __MODULE__

    has_many :children_cycles, __MODULE__

    timestamps()
  end

  @doc false
  def changeset(cycle, attrs) do
    cycle
    |> cast(attrs, [:name, :start_at, :end_at, :is_parent, :school_id, :parent_cycle_id])
    |> validate_required([:name, :start_at, :end_at, :school_id])
    |> check_constraint(
      :end_at,
      name: :cycle_end_date_is_greater_than_start_date,
      message: "End date should be greater than start date"
    )
  end
end
