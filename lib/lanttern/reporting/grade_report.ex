defmodule Lanttern.Reporting.GradeReport do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Grading.Scale
  alias Lanttern.Schools.Cycle
  alias Lanttern.Taxonomy.Subject
  alias Lanttern.Taxonomy.Year

  @type t :: %__MODULE__{
          id: pos_integer(),
          info: String.t(),
          is_differentiation: boolean(),
          school_cycle: Cycle.t(),
          school_cycle_id: pos_integer(),
          subject: Subject.t(),
          subject_id: pos_integer(),
          year: Year.t(),
          year_id: pos_integer(),
          scale: Scale.t(),
          scale_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "grade_reports" do
    field :info, :string
    field :is_differentiation, :boolean, default: false

    belongs_to :school_cycle, Cycle
    belongs_to :subject, Subject
    belongs_to :year, Year
    belongs_to :scale, Scale

    timestamps()
  end

  @doc false
  def changeset(grade_report, attrs) do
    grade_report
    |> cast(attrs, [
      :info,
      :is_differentiation,
      :school_cycle_id,
      :subject_id,
      :year_id,
      :scale_id
    ])
    |> validate_required([:school_cycle_id, :subject_id, :year_id, :scale_id])
  end
end
