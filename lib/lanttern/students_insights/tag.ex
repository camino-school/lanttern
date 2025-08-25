defmodule Lanttern.StudentsInsights.Tag do
  @moduledoc """
  The `StudentsInsights.Tag` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          bg_color: String.t(),
          text_color: String.t(),
          school: School.t() | Ecto.Association.NotLoaded.t() | nil,
          school_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "student_insight_tags" do
    field :name, :string
    field :bg_color, :string
    field :text_color, :string

    belongs_to :school, School

    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name, :bg_color, :text_color, :school_id])
    |> validate_required([:name, :bg_color, :text_color, :school_id])
    |> validate_hex_color(:bg_color)
    |> validate_hex_color(:text_color)
  end

  @doc """
  Validates that a field contains a valid hex color in the format #RRGGBB.
  """
  def validate_hex_color(changeset, field) do
    validate_format(changeset, field, ~r/^#[0-9a-fA-F]{6}$/,
      message: gettext("must be a valid hex color (e.g., #FF0000)")
    )
  end
end
