defmodule Lanttern.StudentsRecords.StudentRecordType do
  @moduledoc """
  The `StudentRecordType` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  import LantternWeb.Gettext

  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          bg_color: String.t(),
          text_color: String.t(),
          school: School.t(),
          school_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "student_record_types" do
    field :name, :string
    field :bg_color, :string
    field :text_color, :string

    belongs_to :school, School

    timestamps()
  end

  @doc false
  def changeset(student_record_type, attrs) do
    student_record_type
    |> cast(attrs, [:name, :bg_color, :text_color, :school_id])
    |> validate_required([:name, :bg_color, :text_color, :school_id])
    |> check_constraint(:bg_color,
      name: :student_record_type_bg_color_should_be_hex,
      message: gettext("Background color format not accepted. Use hex color.")
    )
    |> check_constraint(:text_color,
      name: :student_record_type_text_color_should_be_hex,
      message: gettext("Text color format not accepted. Use hex color.")
    )
  end
end
