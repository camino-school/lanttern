defmodule Lanttern.StudentsRecords.AssigneeRelationship do
  @moduledoc """
  The `StudentsRecords.AssigneeRelationship` schema (join table)
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "students_records_assignees" do
    belongs_to :student_record, Lanttern.StudentsRecords.StudentRecord, primary_key: true
    belongs_to :staff_member, Lanttern.Schools.StaffMember, primary_key: true
    belongs_to :school, Lanttern.Schools.School
  end

  @doc false
  def changeset(assignee, attrs) do
    assignee
    |> cast(attrs, [:staff_member_id, :student_record_id, :school_id])
    |> validate_required([:staff_member_id, :student_record_id, :school_id])
  end
end
