defmodule Lanttern.Grading.ConversionRule do
  use Ecto.Schema
  import Ecto.Changeset

  schema "conversion_rules" do
    field :name, :string
    field :conversions, :map

    belongs_to :from_scale, Lanttern.Grading.Scale
    belongs_to :to_scale, Lanttern.Grading.Scale

    timestamps()
  end

  @doc false
  def changeset(conversion_rule, attrs) do
    conversion_rule
    |> cast(attrs, [:name, :conversions, :from_scale_id, :to_scale_id])
    |> validate_required([:name, :from_scale_id, :to_scale_id])
    |> unique_constraint([:from_scale_id, :to_scale_id], message: "conversion already exists")
    |> check_constraint(:from_scale_id,
      name: :from_and_to_scales_should_be_different,
      message: "from and to scales should be different"
    )
  end
end
