defmodule Lanttern.Grading.OrdinalValue do
  @moduledoc """
  The `OrdinalValue` schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Lanttern.SchemaHelpers, only: [validate_hex_color: 3]

  alias Lanttern.Grading.Scale

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          normalized_value: float(),
          bg_color: String.t(),
          text_color: String.t(),
          scale: Scale.t(),
          scale_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "ordinal_values" do
    field :name, :string
    field :normalized_value, :float
    field :bg_color, :string
    field :text_color, :string

    belongs_to :scale, Scale

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
    |> validate_hex_color(:bg_color, :ordinal_value_bg_color_should_be_hex)
    |> validate_hex_color(:text_color, :ordinal_value_text_color_should_be_hex)
  end
end
