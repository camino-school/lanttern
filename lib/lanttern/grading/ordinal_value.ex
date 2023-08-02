defmodule Lanttern.Grading.OrdinalValue do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ordinal_values" do
    field :name, :string
    field :normalized_value, :float

    belongs_to :scale, Lanttern.Grading.Scale

    timestamps()
  end

  @doc false
  def changeset(ordinal_value, attrs) do
    ordinal_value
    |> cast(attrs, [:name, :normalized_value, :scale_id])
    |> validate_required([:name, :normalized_value, :scale_id])
    |> check_constraint(:normalized_value,
      name: :normalized_value_should_be_between_0_and_1,
      message: "Normalized value should be between 0 and 1"
    )
  end
end
