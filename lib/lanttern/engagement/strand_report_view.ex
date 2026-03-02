defmodule Lanttern.Engagement.StrandReportView do
  @moduledoc """
  Schema for tracking strand report tab views.

  Records one row per profile per strand report per tab per day,
  allowing analysis of which tabs are visited and how often.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @schema_prefix "analytics"

  @navigation_contexts ~w(strand_report report_card)
  @tabs ~w(overview rubrics assessment ongoing_assessment)

  schema "strand_report_views" do
    field :profile_id, :integer
    field :strand_report_id, :integer
    field :student_report_card_id, :integer
    field :navigation_context, :string
    field :tab, :string
    field :date, :date

    timestamps(updated_at: false)
  end

  @type t :: %__MODULE__{
          id: pos_integer() | nil,
          profile_id: pos_integer(),
          strand_report_id: pos_integer(),
          student_report_card_id: pos_integer() | nil,
          navigation_context: String.t(),
          tab: String.t(),
          date: Date.t(),
          inserted_at: NaiveDateTime.t() | nil
        }

  def changeset(strand_report_view, attrs) do
    strand_report_view
    |> cast(attrs, [
      :profile_id,
      :strand_report_id,
      :student_report_card_id,
      :navigation_context,
      :tab,
      :date
    ])
    |> validate_required([:profile_id, :strand_report_id, :navigation_context, :tab, :date])
    |> validate_inclusion(:navigation_context, @navigation_contexts)
    |> validate_inclusion(:tab, @tabs)
  end
end
