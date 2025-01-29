defmodule Lanttern.StudentsRecords.TagRelationship do
  @moduledoc """
  The `StudentsRecords.TagRelationship` schema (join table)
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "students_records_tags" do
    belongs_to :student_record, Lanttern.StudentsRecords.StudentRecord, primary_key: true
    belongs_to :tag, Lanttern.StudentsRecords.Tag, primary_key: true
    belongs_to :school, Lanttern.Schools.School
  end

  @doc false
  def changeset(assignee, attrs) do
    assignee
    |> cast(attrs, [:student_record_id, :tag_id, :school_id])
    |> validate_required([:student_record_id, :tag_id, :school_id])
  end
end
