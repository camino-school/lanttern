defmodule Lanttern.Attachments.Attachment do
  @moduledoc """
  The `Attachment` schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Assessments.AssessmentPointEntryEvidence
  alias Lanttern.Identity.Profile
  alias Lanttern.LearningContext.MomentCard
  alias Lanttern.LearningContext.MomentCardAttachment
  alias Lanttern.Notes.Note
  alias Lanttern.Notes.NoteAttachment
  alias Lanttern.StudentsCycleInfo.StudentCycleInfo
  alias Lanttern.StudentsCycleInfo.StudentCycleInfoAttachment

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          description: String.t(),
          link: String.t(),
          is_external: boolean(),
          owner: Profile.t(),
          owner_id: pos_integer(),
          note_attachment: NoteAttachment.t(),
          note: Note.t(),
          assessment_point_entry_evidence: AssessmentPointEntryEvidence.t(),
          assessment_point_entry: AssessmentPointEntry.t(),
          student_cycle_info_attachment: StudentCycleInfoAttachment.t(),
          student_cycle_info: StudentCycleInfo.t(),
          moment_card_attachment: MomentCardAttachment.t(),
          moment_card: MomentCard.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "attachments" do
    field :name, :string
    field :link, :string
    field :description, :string
    field :is_external, :boolean, default: false

    # used in the context of moment card attachments
    field :is_shared, :boolean, virtual: true

    belongs_to :owner, Profile

    has_one :note_attachment, NoteAttachment
    has_one :note, through: [:note_attachment, :note]

    has_one :assessment_point_entry_evidence, AssessmentPointEntryEvidence

    has_one :assessment_point_entry,
      through: [:assessment_point_entry_evidence, :assessment_point_entry]

    has_one :student_cycle_info_attachment, StudentCycleInfoAttachment
    has_one :student_cycle_info, through: [:student_cycle_info_attachment, :student_cycle_info]

    has_one :moment_card_attachment, MomentCardAttachment
    has_one :moment_card, through: [:moment_card_attachment, :moment_card]

    timestamps()
  end

  @doc false
  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [:name, :description, :link, :is_external, :owner_id])
    |> validate_required([:name, :link, :owner_id])
    |> validate_change(:link, fn :link, link ->
      case URI.new(link) do
        {:error, _} ->
          [link: gettext("Invalid link format")]

        {:ok, %URI{scheme: scheme}} when scheme not in ["https", "http"] ->
          [link: gettext(~s(Links should start with "https://" or "http://"))]

        {:ok, _} ->
          []
      end
    end)
  end
end
