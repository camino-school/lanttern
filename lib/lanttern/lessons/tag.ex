defmodule Lanttern.Lessons.Tag do
  @moduledoc """
  The `Lessons.Tag` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Identity.Scope
  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          agent_description: String.t(),
          position: non_neg_integer(),
          bg_color: String.t(),
          text_color: String.t(),
          school: School.t() | Ecto.Association.NotLoaded.t(),
          school_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "school_lesson_tags" do
    field :name, :string
    field :agent_description, :string
    field :bg_color, :string
    field :text_color, :string
    field :position, :integer, default: 0

    belongs_to :school, School

    timestamps()
  end

  @doc false
  def changeset(tag, attrs, %Scope{} = scope) do
    tag
    |> cast(attrs, [:name, :agent_description, :bg_color, :text_color, :position])
    |> validate_required([:name, :bg_color, :text_color, :position])
    |> put_change(:school_id, scope.school_id)
    |> check_constraint(:bg_color,
      name: :lesson_tags_bg_color_should_be_hex,
      message: gettext("Background color format not accepted. Use hex color.")
    )
    |> check_constraint(:text_color,
      name: :lesson_tags_text_color_should_be_hex,
      message: gettext("Text color format not accepted. Use hex color.")
    )
  end
end
