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
    field :date, :date
    field :time, :time
    field :students_ids, {:array, :id}
    field :classes_ids, {:array, :id}
    field :school_id, :id
    field :type_id, :id
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
      :date,
      :time,
      :students_ids,
      :classes_ids,
      :school_id,
      :type_id,
      :status_id
    ])
    |> validate_required([
      :student_record_id,
      :profile_id,
      :operation,
      :description,
      :date,
      :students_ids,
      :school_id,
      :type_id,
      :status_id
    ])
  end
end
