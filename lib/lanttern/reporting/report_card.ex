defmodule Lanttern.Reporting.ReportCard do
  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Reporting.StrandReport
  alias Lanttern.Schools.Cycle

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          description: String.t(),
          school_cycle: Cycle.t(),
          school_cycle_id: pos_integer(),
          strand_reports: [StrandReport.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "report_cards" do
    field :name, :string
    field :description, :string

    belongs_to :school_cycle, Cycle

    has_many :strand_reports, StrandReport, preload_order: [asc: :position]

    timestamps()
  end

  @doc false
  def changeset(report_card, attrs) do
    report_card
    |> cast(attrs, [:name, :description, :school_cycle_id])
    |> validate_required([:name, :school_cycle_id])
  end
end
