defmodule Lanttern.Schools.School do
  @moduledoc """
  The `School` schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Lanttern.SchemaHelpers, only: [validate_hex_color: 3]

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          logo_image_url: String.t(),
          bg_color: String.t(),
          text_color: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "schools" do
    field :name, :string
    field :logo_image_url, :string
    field :bg_color, :string
    field :text_color, :string

    timestamps()
  end

  @doc false
  def changeset(school, attrs) do
    school
    |> cast(attrs, [:name, :logo_image_url, :bg_color, :text_color])
    |> validate_required([:name])
    |> validate_hex_color(:bg_color, :school_bg_color_should_be_hex)
    |> validate_hex_color(:text_color, :school_text_color_should_be_hex)
  end
end
