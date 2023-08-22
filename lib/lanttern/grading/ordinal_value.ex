defmodule Lanttern.Grading.OrdinalValue do
  use Ecto.Schema
  import Ecto.Changeset

  schema "ordinal_values" do
    field :name, :string
    field :normalized_value, :float
    field :bg_color, :string
    field :text_color, :string

    belongs_to :scale, Lanttern.Grading.Scale

    timestamps()
  end

  @doc false
  def changeset(ordinal_value, attrs) do
    ordinal_value
    |> cast(attrs, [:name, :normalized_value, :scale_id, :bg_color, :text_color])
    |> validate_required([:name, :normalized_value, :scale_id])
    |> check_constraint(:normalized_value,
      name: :normalized_value_should_be_between_0_and_1,
      message: "Normalized value should be between 0 and 1"
    )
    |> check_constraint(:bg_color,
      name: :ordinal_value_bg_color_should_be_hex,
      message: "Background color format not accepted. Use hex color."
    )
    |> check_constraint(:text_color,
      name: :ordinal_value_text_color_should_be_hex,
      message: "Text color format not accepted. Use hex color."
    )
  end
end
