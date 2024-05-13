defmodule Lanttern.Reporting.ReportCard do
  @moduledoc """
  The `ReportCard` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.GradesReports.GradesReport
  alias Lanttern.Reporting.StrandReport
  alias Lanttern.Reporting.StudentReportCard
  alias Lanttern.Schools.Cycle
  alias Lanttern.Taxonomy.Year

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          description: String.t(),
          grading_info: String.t(),
          cover_image_url: String.t(),
          school_cycle: Cycle.t(),
          school_cycle_id: pos_integer(),
          year: Year.t(),
          year_id: pos_integer(),
          grades_report: GradesReport.t(),
          grades_report_id: pos_integer(),
          strand_reports: [StrandReport.t()],
          students_report_cards: [StudentReportCard.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "report_cards" do
    field :name, :string
    field :description, :string
    field :grading_info, :string
    field :cover_image_url, :string

    belongs_to :school_cycle, Cycle
    belongs_to :year, Year
    belongs_to :grades_report, GradesReport

    has_many :strand_reports, StrandReport, preload_order: [asc: :position]
    has_many :students_report_cards, StudentReportCard

    timestamps()
  end

  @doc false
  def changeset(report_card, attrs) do
    report_card
    |> cast(attrs, [
      :name,
      :description,
      :grading_info,
      :cover_image_url,
      :school_cycle_id,
      :year_id,
      :grades_report_id
    ])
    |> validate_required([:name, :school_cycle_id, :year_id])
  end
end
