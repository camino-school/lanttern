defmodule Lanttern.Reporting.StudentReportCard do
  use Ecto.Schema
  import Ecto.Changeset

  import LantternWeb.Gettext

  alias Lanttern.Reporting.ReportCard
  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer(),
          comment: String.t(),
          footnote: String.t(),
          cover_image_url: String.t(),
          report_card: ReportCard.t(),
          report_card_id: pos_integer(),
          student: Student.t(),
          student_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "student_report_cards" do
    field :comment, :string
    field :footnote, :string
    field :cover_image_url, :string

    belongs_to :report_card, ReportCard
    belongs_to :student, Student

    timestamps()
  end

  @doc false
  def changeset(student_report_card, attrs) do
    student_report_card
    |> cast(attrs, [:comment, :footnote, :cover_image_url, :report_card_id, :student_id])
    |> validate_required([:report_card_id, :student_id])
    |> unique_constraint([:student_id, :report_card_id],
      message: gettext("Student already linked to report card")
    )
  end
end
