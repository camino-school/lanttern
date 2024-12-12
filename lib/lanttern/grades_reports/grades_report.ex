defmodule Lanttern.GradesReports.GradesReport do
  @moduledoc """
  The `GradesReport` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  import LantternWeb.Gettext

  alias Lanttern.GradesReports.GradesReportCycle
  alias Lanttern.GradesReports.GradesReportSubject
  alias Lanttern.Grading.Scale
  alias Lanttern.Reporting.ReportCard
  alias Lanttern.Schools.Cycle
  alias Lanttern.Taxonomy.Year

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          info: String.t(),
          final_is_visible: boolean(),
          is_differentiation: boolean(),
          school_cycle: Cycle.t(),
          school_cycle_id: pos_integer(),
          year: Year.t(),
          year_id: pos_integer(),
          scale: Scale.t(),
          scale_id: pos_integer(),
          grades_report_cycles: [GradesReportCycle.t()],
          grades_report_subjects: [GradesReportSubject.t()],
          report_cards: [ReportCard.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "grades_reports" do
    field :name, :string
    field :info, :string
    field :final_is_visible, :boolean, default: false
    field :is_differentiation, :boolean, default: false

    belongs_to :school_cycle, Cycle
    belongs_to :year, Year
    belongs_to :scale, Scale

    has_many :grades_report_cycles, GradesReportCycle
    has_many :grades_report_subjects, GradesReportSubject
    has_many :report_cards, ReportCard

    timestamps()
  end

  @doc false
  def changeset(grades_report, attrs) do
    grades_report
    |> cast(attrs, [
      :name,
      :info,
      :final_is_visible,
      :is_differentiation,
      :school_cycle_id,
      :year_id,
      :scale_id
    ])
    |> validate_required([:name, :school_cycle_id, :year_id, :scale_id])
    |> unique_constraint(:school_cycle_id,
      name: "grades_reports_year_id_school_cycle_id_index",
      message: gettext("A grades report for the same cycle and year already exists")
    )
  end
end
