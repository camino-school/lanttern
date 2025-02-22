defmodule Lanttern.StudentsRecords.StudentRecordRelationship do
  @moduledoc """
  The `StudentRecordRelationship` schema (join table)
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "students_students_records" do
    field :student_record_id, :id, primary_key: true
    field :school_id, :id

    belongs_to :student, Lanttern.Schools.Student, primary_key: true
  end

  @doc false
  def changeset(student_record_relationship, attrs) do
    student_record_relationship
    |> cast(attrs, [:student_id, :student_record_id, :school_id])
    |> validate_required([:student_id, :student_record_id, :school_id])
  end
end
