defmodule Lanttern.StudentsRecords.StudentRecord do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.StudentsRecords.StudentRecordType
  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          description: String.t(),
          date: Date.t(),
          time: Time.t(),
          school_id: pos_integer(),
          school: School.t(),
          type_id: pos_integer(),
          type: StudentRecordType.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "students_records" do
    field :name, :string
    field :description, :string
    field :date, :date
    field :time, :time

    belongs_to :school, School
    belongs_to :type, StudentRecordType

    timestamps()
  end

  @doc false
  def changeset(student_record, attrs) do
    student_record
    |> cast(attrs, [:name, :description, :date, :time, :school_id, :type_id])
    |> validate_required([:description, :date, :school_id, :type_id])
  end
end
