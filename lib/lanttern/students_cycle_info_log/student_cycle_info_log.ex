defmodule Lanttern.StudentsCycleInfoLog.StudentCycleInfoLog do
  @moduledoc """
  The `StudentCycleInfoLog` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "log"
  schema "students_cycle_info" do
    field :student_cycle_info_id, :id
    field :profile_id, :id
    field :operation, :string

    field :student_id, :id
    field :cycle_id, :id
    field :school_id, :id
    field :school_info, :string
    field :family_info, :string
    field :profile_picture_url, :string

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(student_cycle_info_log, attrs) do
    student_cycle_info_log
    |> cast(attrs, [
      :student_cycle_info_id,
      :profile_id,
      :operation,
      :student_id,
      :cycle_id,
      :school_id,
      :school_info,
      :family_info,
      :profile_picture_url
    ])
    |> validate_required([
      :student_cycle_info_id,
      :profile_id,
      :operation,
      :student_id,
      :cycle_id,
      :school_id
    ])
  end
end
