defmodule Lanttern.Lessons.Tag do
  @moduledoc """
  The `Lessons.Tag` schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Lanttern.SchemaHelpers, only: [validate_hex_color: 3]

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Identity.Scope
  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          agent_description: String.t() | nil,
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
    |> validate_hex_color(:bg_color, :lesson_tags_bg_color_should_be_hex)
    |> validate_hex_color(:text_color, :lesson_tags_text_color_should_be_hex)
  end
end
