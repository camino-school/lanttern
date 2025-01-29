defmodule Lanttern.StudentsRecords.Tag do
  @moduledoc """
  The `StudentsRecords.Tag` schema
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
          school: School.t(),
          school_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "schools_students_records_tags" do
    field :name, :string
    field :position, :integer, default: 0
    field :bg_color, :string
    field :text_color, :string

    belongs_to :school, School

    timestamps()
  end

  @doc false
  def changeset(student_record_tag, attrs) do
    student_record_tag
    |> cast(attrs, [:name, :position, :bg_color, :text_color, :school_id])
    |> validate_required([:name, :bg_color, :text_color, :school_id])
    |> check_constraint(:bg_color,
      name: :student_record_tag_bg_color_should_be_hex,
      message: gettext("Background color format not accepted. Use hex color.")
    )
    |> check_constraint(:text_color,
      name: :student_record_tag_text_color_should_be_hex,
      message: gettext("Text color format not accepted. Use hex color.")
    )
  end
end
