defmodule Lanttern.StudentsInsights.Tag do
  @moduledoc """
  The `StudentsInsights.Tag` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Identity.User
  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          description: String.t() | nil,
          bg_color: String.t(),
          text_color: String.t(),
          school: School.t() | Ecto.Association.NotLoaded.t() | nil,
          school_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "student_insight_tags" do
    field :name, :string
    field :description, :string
    field :bg_color, :string
    field :text_color, :string

    belongs_to :school, School

    timestamps()
  end

  @doc false
  def changeset(tag, attrs, %User{} = current_user) do
    tag
    |> cast(attrs, [:name, :description, :bg_color, :text_color])
    |> put_change(:school_id, current_user.current_profile.school_id)
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
