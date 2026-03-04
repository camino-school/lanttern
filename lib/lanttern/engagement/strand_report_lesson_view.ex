defmodule Lanttern.Engagement.StrandReportLessonView do
  @moduledoc """
  Schema for tracking strand report lesson views.

  Records one row per profile per lesson per day,
  allowing analysis of lesson engagement within strand reports.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @schema_prefix "analytics"

  schema "strand_report_lesson_views" do
    field :profile_id, :integer
    field :strand_report_id, :integer
    field :lesson_id, :integer
    field :student_report_card_id, :integer
    field :date, :date

    timestamps(updated_at: false)
  end

  @type t :: %__MODULE__{
          id: pos_integer() | nil,
          profile_id: pos_integer(),
          strand_report_id: pos_integer(),
          lesson_id: pos_integer(),
          student_report_card_id: pos_integer() | nil,
          date: Date.t(),
          inserted_at: NaiveDateTime.t() | nil
        }

  def changeset(strand_report_lesson_view, attrs) do
    strand_report_lesson_view
    |> cast(attrs, [:profile_id, :strand_report_id, :lesson_id, :student_report_card_id, :date])
    |> validate_required([:profile_id, :strand_report_id, :lesson_id, :date])
  end
end
