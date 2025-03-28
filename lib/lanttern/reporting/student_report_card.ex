defmodule Lanttern.Reporting.StudentReportCard do
  @moduledoc """
  The `StudentReportCard` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Reporting.ReportCard
  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer(),
          comment: String.t(),
          footnote: String.t(),
          cover_image_url: String.t(),
          allow_student_access: boolean(),
          allow_guardian_access: boolean(),
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
    field :allow_student_access, :boolean, default: false
    field :allow_guardian_access, :boolean, default: false

    belongs_to :report_card, ReportCard
    belongs_to :student, Student

    timestamps()
  end

  @doc false
  def changeset(student_report_card, attrs) do
    student_report_card
    |> cast(attrs, [
      :comment,
      :footnote,
      :cover_image_url,
      :allow_student_access,
      :allow_guardian_access,
      :report_card_id,
      :student_id
    ])
    |> validate_required([:report_card_id, :student_id])
    |> unique_constraint([:student_id, :report_card_id],
      message: gettext("Student already linked to report card")
    )
  end
end
