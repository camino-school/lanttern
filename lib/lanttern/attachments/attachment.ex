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
  alias Lanttern.ILP.ILPComment
  alias Lanttern.ILP.ILPCommentAttachment
  alias Lanttern.Lessons.Lesson
  alias Lanttern.Lessons.LessonAttachment
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
          assessment_point_entry_evidence: AssessmentPointEntryEvidence.t(),
          assessment_point_entry: AssessmentPointEntry.t(),
          student_cycle_info_attachment: StudentCycleInfoAttachment.t(),
          student_cycle_info: StudentCycleInfo.t(),
          lesson_attachment: LessonAttachment.t(),
          lesson: Lesson.t(),
          ilp_comment_attachment: ILPCommentAttachment.t(),
          ilp_comment: ILPComment.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "attachments" do
    field :name, :string
    field :link, :string
    field :description, :string
    field :is_external, :boolean, default: false

    # used for manage async presigned URL generation
    field :signed_link, :string, virtual: true
    field :signed_link_error, :boolean, default: false, virtual: true

    # used in the context of student cycle info
    field :is_shared, :boolean, virtual: true

    # used in the context of lesson attachments
    field :is_teacher_only, :boolean, virtual: true

    belongs_to :owner, Profile

    has_one :assessment_point_entry_evidence, AssessmentPointEntryEvidence

    has_one :assessment_point_entry,
      through: [:assessment_point_entry_evidence, :assessment_point_entry]

    has_one :student_cycle_info_attachment, StudentCycleInfoAttachment
    has_one :student_cycle_info, through: [:student_cycle_info_attachment, :student_cycle_info]

    has_one :lesson_attachment, LessonAttachment
    has_one :lesson, through: [:lesson_attachment, :lesson]

    has_one :ilp_comment_attachment, ILPCommentAttachment
    has_one :ilp_comment, through: [:ilp_comment_attachment, :ilp_comment]

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

        {:ok, %URI{}} ->
          []
      end
    end)
  end
end
