defmodule Lanttern.StudentsRecords.StudentRecordClassRelationship do
  @moduledoc """
  The `StudentRecordClassRelationship` schema (join table)
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "students_records_classes" do
    field :student_record_id, :id, primary_key: true
    field :school_id, :id

    belongs_to :class, Lanttern.Schools.Class, primary_key: true
  end

  @doc false
  def changeset(student_record_class_relationship, attrs) do
    student_record_class_relationship
    |> cast(attrs, [:class_id, :student_record_id, :school_id])
    |> validate_required([:class_id, :student_record_id, :school_id])
  end
end
