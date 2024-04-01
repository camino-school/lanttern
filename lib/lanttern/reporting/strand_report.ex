defmodule Lanttern.Reporting.StrandReport do
  use Ecto.Schema
  import Ecto.Changeset

  import LantternWeb.Gettext

  alias Lanttern.Reporting.ReportCard
  alias Lanttern.LearningContext.Strand

  @type t :: %__MODULE__{
          id: pos_integer(),
          description: String.t(),
          cover_image_url: String.t(),
          position: non_neg_integer(),
          report_card: ReportCard.t(),
          report_card_id: pos_integer(),
          strand: Strand.t(),
          strand_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "strand_reports" do
    field :description, :string
    field :cover_image_url, :string
    field :position, :integer, default: 0

    belongs_to :report_card, ReportCard
    belongs_to :strand, Strand

    timestamps()
  end

  @doc false
  def changeset(strand_report, attrs) do
    strand_report
    |> cast(attrs, [:description, :cover_image_url, :position, :report_card_id, :strand_id])
    |> validate_required([:report_card_id, :strand_id])
    |> unique_constraint([:strand_id, :report_card_id],
      message: gettext("Strand already linked to report card")
    )
  end
end
