defmodule Lanttern.Reporting.StrandReport do
  use Ecto.Schema
  import Ecto.Changeset

  import LantternWeb.Gettext

  schema "strand_reports" do
    field :description, :string
    field :position, :integer, default: 0

    belongs_to :report_card, Lanttern.Reporting.ReportCard
    belongs_to :strand, Lanttern.LearningContext.Strand

    timestamps()
  end

  @doc false
  def changeset(strand_report, attrs) do
    strand_report
    |> cast(attrs, [:description, :position, :report_card_id, :strand_id])
    |> validate_required([:position, :report_card_id, :strand_id])
    |> unique_constraint([:strand_id, :report_card_id],
      message: gettext("Strand already linked to report card")
    )
  end
end
