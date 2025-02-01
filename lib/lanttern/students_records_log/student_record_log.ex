defmodule Lanttern.StudentsRecordsLog.StudentRecordLog do
  @moduledoc """
  The `StudentRecordLog` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "log"
  schema "students_records" do
    field :student_record_id, :id
    field :profile_id, :id
    field :operation, :string
    field :name, :string
    field :description, :string
    field :internal_notes, :string
    field :date, :date
    field :time, :time
    field :closed_at, :utc_datetime
    field :students_ids, {:array, :id}
    field :classes_ids, {:array, :id}
    field :created_by_staff_member_id, :id
    field :closed_by_staff_member_id, :id
    field :assignees_ids, {:array, :id}
    field :school_id, :id
    field :tags_ids, {:array, :id}
    field :status_id, :id

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(student_record_log, attrs) do
    student_record_log
    |> cast(attrs, [
      :student_record_id,
      :profile_id,
      :operation,
      :name,
      :description,
      :internal_notes,
      :date,
      :time,
      :closed_at,
      :students_ids,
      :classes_ids,
      :created_by_staff_member_id,
      :closed_by_staff_member_id,
      :assignees_ids,
      :school_id,
      :tags_ids,
      :status_id
    ])
    |> validate_required([
      :student_record_id,
      :profile_id,
      :operation,
      :description,
      :date,
      :students_ids,
      :created_by_staff_member_id,
      :school_id,
      :tags_ids,
      :status_id
    ])
  end
end
