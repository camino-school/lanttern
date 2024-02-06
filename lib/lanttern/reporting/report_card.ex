defmodule Lanttern.Reporting.ReportCard do
  use Ecto.Schema
  import Ecto.Changeset

  schema "report_cards" do
    field :name, :string
    field :description, :string

    belongs_to :school_cycle, Lanttern.Schools.Cycle

    has_many :strand_reports, Lanttern.Reporting.StrandReport

    timestamps()
  end

  @doc false
  def changeset(report_card, attrs) do
    report_card
    |> cast(attrs, [:name, :description, :school_cycle_id])
    |> validate_required([:name, :school_cycle_id])
  end
end
