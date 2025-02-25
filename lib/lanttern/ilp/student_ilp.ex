defmodule Lanttern.ILP.StudentILP do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.ILP.ILPTemplate
  alias Lanttern.Schools.Cycle
  alias Lanttern.Schools.School
  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer(),
          teacher_notes: String.t() | nil,
          template_id: pos_integer(),
          template: ILPTemplate.t() | Ecto.Association.NotLoaded.t(),
          student_id: pos_integer(),
          student: Student.t() | Ecto.Association.NotLoaded.t(),
          cycle_id: pos_integer(),
          cycle: Cycle.t() | Ecto.Association.NotLoaded.t(),
          school_id: pos_integer(),
          school: School.t() | Ecto.Association.NotLoaded.t(),
          update_of_ilp_id: pos_integer(),
          update_of_ilp: __MODULE__.t() | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "students_ilps" do
    field :teacher_notes, :string

    belongs_to :template, ILPTemplate
    belongs_to :student, Student
    belongs_to :cycle, Cycle
    belongs_to :school, School
    belongs_to :update_of_ilp, __MODULE__

    timestamps()
  end

  @doc false
  def changeset(student_ilp, attrs) do
    student_ilp
    |> cast(attrs, [
      :teacher_notes,
      :template_id,
      :student_id,
      :cycle_id,
      :school_id,
      :update_of_ilp_id
    ])
    |> validate_required([:template_id, :student_id, :cycle_id, :school_id])
  end
end
