defmodule Lanttern.StudentRecordReports.StudentRecordReport do
  @moduledoc """
  The `StudentRecordReport` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer(),
          description: String.t(),
          private_description: String.t() | nil,
          student: Student.t() | Ecto.Association.NotLoaded.t(),
          student_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "student_record_reports" do
    field :description, :string
    field :private_description, :string

    belongs_to :student, Student

    timestamps()
  end

  @doc false
  def changeset(student_record_report, attrs) do
    student_record_report
    |> cast(attrs, [
      :description,
      :private_description,
      :student_id
    ])
    |> validate_required([:description, :student_id])
  end
end
