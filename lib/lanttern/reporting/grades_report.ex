defmodule Lanttern.Reporting.GradesReport do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Grading.Scale
  alias Lanttern.Schools.Cycle
  alias Lanttern.Reporting.GradesReportCycle
  alias Lanttern.Reporting.GradesReportSubject

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          info: String.t(),
          is_differentiation: boolean(),
          school_cycle: Cycle.t(),
          school_cycle_id: pos_integer(),
          scale: Scale.t(),
          scale_id: pos_integer(),
          grades_report_cycles: [GradesReportCycle.t()],
          grades_report_subjects: [GradesReportSubject.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "grades_reports" do
    field :name, :string
    field :info, :string
    field :is_differentiation, :boolean, default: false

    belongs_to :school_cycle, Cycle
    belongs_to :scale, Scale

    has_many :grades_report_cycles, GradesReportCycle
    has_many :grades_report_subjects, GradesReportSubject

    timestamps()
  end

  @doc false
  def changeset(grades_report, attrs) do
    grades_report
    |> cast(attrs, [:name, :info, :is_differentiation, :school_cycle_id, :scale_id])
    |> validate_required([:name, :school_cycle_id, :scale_id])
  end
end
