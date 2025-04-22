defmodule Lanttern.StudentTags.Tag do
  @moduledoc """
  The `StudentTags.Tag` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          position: non_neg_integer(),
          bg_color: String.t(),
          text_color: String.t(),
          school: School.t() | Ecto.Association.NotLoaded.t(),
          school_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "schools_student_tags" do
    field :name, :string
    field :position, :integer, default: 0
    field :bg_color, :string
    field :text_color, :string

    belongs_to :school, School

    timestamps()
  end

  @doc false
  def changeset(student_tag, attrs) do
    student_tag
    |> cast(attrs, [:name, :position, :bg_color, :text_color, :school_id])
    |> validate_required([:name, :bg_color, :text_color, :school_id])
    |> check_constraint(:bg_color,
      name: :schools_student_tags_bg_color_should_be_hex,
      message: gettext("Background color format not accepted. Use hex color.")
    )
    |> check_constraint(:text_color,
      name: :schools_student_tags_text_color_should_be_hex,
      message: gettext("Text color format not accepted. Use hex color.")
    )
  end
end
