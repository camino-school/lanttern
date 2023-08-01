defmodule Lanttern.Grading.NumericScale do
  use Ecto.Schema
  import Ecto.Changeset

  schema "numeric_scales" do
    field :name, :string
    field :start, :float
    field :stop, :float

    timestamps()
  end

  @doc false
  def changeset(numeric_scale, attrs) do
    numeric_scale
    |> cast(attrs, [:name, :start, :stop])
    |> validate_required([:name, :start, :stop])
  end
end
