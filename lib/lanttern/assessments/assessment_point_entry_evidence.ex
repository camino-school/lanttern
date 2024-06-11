defmodule Lanttern.Assessments.AssessmentPointEntryEvidence do
  @moduledoc """
  The `AssessmentPointEntryEvidence` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Attachments.Attachment

  @type t :: %__MODULE__{
          id: pos_integer(),
          position: non_neg_integer(),
          assessment_point_entry: AssessmentPointEntry.t(),
          assessment_point_entry_id: pos_integer(),
          attachment: Attachment.t(),
          attachment_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "assessment_point_entries_evidences" do
    field :position, :integer, default: 0

    belongs_to :assessment_point_entry, AssessmentPointEntry
    belongs_to :attachment, Attachment

    timestamps()
  end

  @doc false
  def changeset(assessment_point_entry_evidence, attrs) do
    assessment_point_entry_evidence
    |> cast(attrs, [:position, :assessment_point_entry_id, :attachment_id])
    |> validate_required([:assessment_point_entry_id, :attachment_id])
  end
end
