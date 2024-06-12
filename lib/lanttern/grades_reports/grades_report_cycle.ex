defmodule Lanttern.GradesReports.GradesReportCycle do
  @moduledoc """
  The `GradesReportCycle` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  import LantternWeb.Gettext

  alias Lanttern.GradesReports.GradesReport
  alias Lanttern.Schools.Cycle

  @type t :: %__MODULE__{
          id: pos_integer(),
          weight: float(),
          is_visible: boolean(),
          school_cycle: Cycle.t(),
          school_cycle_id: pos_integer(),
          grades_report: GradesReport.t(),
          grades_report_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "grades_report_cycles" do
    field :weight, :float, default: 1.0
    field :is_visible, :boolean, default: true

    belongs_to :school_cycle, Cycle
    belongs_to :grades_report, GradesReport

    timestamps()
  end

  @doc false
  def changeset(grades_report_cycle, attrs) do
    grades_report_cycle
    |> cast(attrs, [:weight, :is_visible, :school_cycle_id, :grades_report_id])
    |> validate_required([:school_cycle_id, :grades_report_id])
    |> unique_constraint(:school_cycle_id,
      name: "grades_report_cycles_grades_report_id_school_cycle_id_index",
      message: gettext("Cycle already added to this grade report")
    )
  end
end
