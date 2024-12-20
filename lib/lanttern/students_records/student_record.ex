defmodule Lanttern.StudentsRecords.StudentRecord do
  @moduledoc """
  The `StudentRecord` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  import LantternWeb.Gettext

  alias Lanttern.StudentsRecords.StudentRecordClassRelationship
  alias Lanttern.StudentsRecords.StudentRecordRelationship
  alias Lanttern.StudentsRecords.StudentRecordStatus
  alias Lanttern.StudentsRecords.StudentRecordType
  alias Lanttern.Schools.Class
  alias Lanttern.Schools.School
  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          description: String.t(),
          date: Date.t(),
          time: Time.t(),
          students: [Student.t()],
          students_ids: [pos_integer()],
          classes: [Class.t()],
          classes_ids: [pos_integer()],
          school_id: pos_integer(),
          school: School.t(),
          status_id: pos_integer(),
          status: StudentRecordStatus.t(),
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
    field :students_ids, {:array, :id}, virtual: true
    field :classes_ids, {:array, :id}, virtual: true

    belongs_to :school, School
    belongs_to :status, StudentRecordStatus
    belongs_to :type, StudentRecordType

    has_many :students_relationships, StudentRecordRelationship, on_replace: :delete
    has_many :classes_relationships, StudentRecordClassRelationship, on_replace: :delete

    many_to_many :students, Student,
      join_through: "students_students_records",
      preload_order: [asc: :name]

    many_to_many :classes, Class, join_through: "students_records_classes"

    timestamps()
  end

  @doc false
  def changeset(student_record, attrs) do
    student_record
    |> cast(attrs, [
      :name,
      :description,
      :date,
      :time,
      :students_ids,
      :classes_ids,
      :school_id,
      :type_id,
      :status_id
    ])
    |> validate_required([:description, :date, :school_id, :type_id, :status_id])
    |> cast_and_validate_students()
    |> cast_classes()
  end

  def cast_and_validate_students(changeset) do
    changeset =
      cast_students(
        changeset,
        get_change(changeset, :students_ids)
      )

    case get_field(changeset, :students_relationships) do
      [] ->
        add_error(changeset, :students_ids, gettext("At least 1 student is required"))

      _ ->
        changeset
    end
  end

  defp cast_students(changeset, students_ids) when is_list(students_ids) do
    school_id = get_field(changeset, :school_id)

    students_relationships_params =
      Enum.map(students_ids, &%{student_id: &1, school_id: school_id})

    changeset
    |> put_change(:students_relationships, students_relationships_params)
    |> cast_assoc(:students_relationships)
  end

  defp cast_students(changeset, _), do: changeset

  defp cast_classes(changeset) do
    case get_change(changeset, :classes_ids) do
      classes_ids when is_list(classes_ids) ->
        school_id = get_field(changeset, :school_id)

        classes_relationships_params =
          Enum.map(classes_ids, &%{class_id: &1, school_id: school_id})

        changeset
        |> put_change(:classes_relationships, classes_relationships_params)
        |> cast_assoc(:classes_relationships)

      _ ->
        changeset
    end
  end
end
