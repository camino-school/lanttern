defmodule Lanttern.Grading.OrdinalValue do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ordinal_values" do
    field :name, :string
    field :order, :integer

    belongs_to :scale, Lanttern.Grading.OrdinalScale

    timestamps()
  end

  @doc false
  def changeset(ordinal_value, attrs) do
    ordinal_value
    |> cast(attrs, [:name, :order, :scale_id])
    |> validate_required([:name, :order, :scale_id])
  end
end
