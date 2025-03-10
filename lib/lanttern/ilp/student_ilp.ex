defmodule Lanttern.ILP.StudentILP do
  @moduledoc """
  The `StudentILP` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.ILP.ILPEntry
  alias Lanttern.ILP.ILPTemplate
  alias Lanttern.Schools.Cycle
  alias Lanttern.Schools.School
  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer(),
          notes: String.t() | nil,
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
          entries: [ILPEntry.t()] | Ecto.Association.NotLoaded.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "students_ilps" do
    field :notes, :string
    field :teacher_notes, :string

    belongs_to :template, ILPTemplate
    belongs_to :student, Student
    belongs_to :cycle, Cycle
    belongs_to :school, School
    belongs_to :update_of_ilp, __MODULE__

    has_many :entries, ILPEntry, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(student_ilp, attrs) do
    student_ilp
    |> cast(attrs, [
      :notes,
      :teacher_notes,
      :template_id,
      :student_id,
      :cycle_id,
      :school_id,
      :update_of_ilp_id
    ])
    |> validate_required([:template_id, :student_id, :cycle_id, :school_id])
    |> cast_assoc(:entries)
    # we don't use it to actually update the template, just to chain
    # cast_assocs to entries (template > section > component > entry)
    |> cast_assoc(:template)
  end
end
