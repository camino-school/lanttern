defmodule Lanttern.StudentsCycleInfo.StudentCycleInfo do
  @moduledoc """
  The `StudentCycleInfo` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Schools.Cycle
  alias Lanttern.Schools.School
  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer(),
          school_info: String.t(),
          family_info: String.t(),
          profile_picture_url: String.t(),
          student: Student.t(),
          student_id: pos_integer(),
          cycle: Cycle.t(),
          cycle_id: pos_integer(),
          school: School.t(),
          school_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "students_cycle_info" do
    field :school_info, :string
    field :family_info, :string
    field :profile_picture_url, :string

    belongs_to :student, Student
    belongs_to :cycle, Cycle
    belongs_to :school, School

    timestamps()
  end

  @doc false
  def changeset(student_cycle_info, attrs) do
    student_cycle_info
    |> cast(attrs, [
      :school_info,
      :family_info,
      :profile_picture_url,
      :student_id,
      :cycle_id,
      :school_id
    ])
    |> validate_required([:student_id, :cycle_id, :school_id])
    |> foreign_key_constraint(
      :student_id,
      name: :students_cycle_info_student_id_fkey,
      message: gettext("Check the student and school relationship")
    )
    |> foreign_key_constraint(
      :cycle_id,
      name: :students_cycle_info_cycle_id_fkey,
      message: gettext("Check the cycle and school relationship")
    )
  end
end
