defmodule Lanttern.StudentRecordReports.StudentRecordReportAIConfig do
  @moduledoc """
  The `StudentRecordReportAIConfig` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Schools.School

  @type t :: %__MODULE__{
          id: pos_integer(),
          summary_instructions: String.t() | nil,
          update_instructions: String.t() | nil,
          model: String.t() | nil,
          cooldown_minutes: non_neg_integer(),
          school: School.t() | Ecto.Association.NotLoaded.t(),
          school_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "student_record_reports_ai_config" do
    field :summary_instructions, :string
    field :update_instructions, :string
    field :model, :string
    field :cooldown_minutes, :integer, default: 0

    belongs_to :school, School

    timestamps()
  end

  @doc false
  def changeset(student_record_report_ai_config, attrs) do
    student_record_report_ai_config
    |> cast(attrs, [
      :summary_instructions,
      :update_instructions,
      :model,
      :cooldown_minutes,
      :school_id
    ])
    |> validate_required([:school_id])
  end
end
