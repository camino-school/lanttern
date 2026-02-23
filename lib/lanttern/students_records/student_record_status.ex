defmodule Lanttern.StudentsRecords.StudentRecordStatus do
  @moduledoc """
  The `StudentRecordStatus` schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Lanttern.SchemaHelpers, only: [validate_hex_color: 3]

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          position: non_neg_integer(),
          bg_color: String.t(),
          text_color: String.t(),
          is_closed: boolean(),
          school: School.t(),
          school_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "student_record_statuses" do
    field :name, :string
    field :position, :integer, default: 0
    field :bg_color, :string
    field :text_color, :string
    field :is_closed, :boolean, default: false

    belongs_to :school, School

    timestamps()
  end

  @doc false
  def changeset(student_record_status, attrs) do
    student_record_status
    |> cast(attrs, [:name, :position, :bg_color, :text_color, :is_closed, :school_id])
    |> validate_required([:name, :bg_color, :text_color, :school_id])
    |> validate_hex_color(:bg_color, :student_record_status_bg_color_should_be_hex)
    |> validate_hex_color(:text_color, :student_record_status_text_color_should_be_hex)
  end
end
