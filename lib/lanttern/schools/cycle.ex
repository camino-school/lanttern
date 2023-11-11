defmodule Lanttern.Schools.Cycle do
  use Ecto.Schema
  import Ecto.Changeset

  schema "school_cycles" do
    field :name, :string
    field :start_at, :date
    field :end_at, :date
    belongs_to :school, Lanttern.Schools.School

    timestamps()
  end

  @doc false
  def changeset(cycle, attrs) do
    cycle
    |> cast(attrs, [:name, :start_at, :end_at, :school_id])
    |> validate_required([:name, :start_at, :end_at, :school_id])
    |> check_constraint(
      :end_at,
      name: :cycle_end_date_is_greater_than_start_date,
      message: "End date should be greater than start date"
    )
  end
end
