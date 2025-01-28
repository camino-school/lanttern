defmodule Lanttern.StudentsRecords.Assignee do
  @moduledoc """
  The `StudentsRecords.Assignee` schema (join table)
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "students_records_assignees" do
    field :student_record_id, :id, primary_key: true
    field :school_id, :id

    belongs_to :staff_member, Lanttern.Schools.Student, primary_key: true
  end

  @doc false
  def changeset(assignee, attrs) do
    assignee
    |> cast(attrs, [:staff_member_id, :student_record_id, :school_id])
    |> validate_required([:staff_member_id, :student_record_id, :school_id])
  end
end
