defmodule Lanttern.Lessons.LessonAttachment do
  @moduledoc """
  The `LessonAttachment` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Attachments.Attachment
  alias Lanttern.Lessons.Lesson

  @type t :: %__MODULE__{
          id: pos_integer(),
          position: non_neg_integer(),
          is_teacher_only_resource: boolean(),
          lesson: Lesson.t() | Ecto.Association.NotLoaded.t(),
          lesson_id: pos_integer(),
          attachment: Attachment.t() | Ecto.Association.NotLoaded.t(),
          attachment_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "lessons_attachments" do
    field :position, :integer, default: 0
    field :is_teacher_only_resource, :boolean, default: true

    belongs_to :lesson, Lesson
    belongs_to :attachment, Attachment

    timestamps()
  end

  @doc false
  def changeset(lesson_attachment, attrs) do
    lesson_attachment
    |> cast(attrs, [:position, :is_teacher_only_resource, :lesson_id, :attachment_id])
    |> validate_required([:position, :is_teacher_only_resource, :lesson_id, :attachment_id])
    |> unique_constraint([:attachment_id, :lesson_id])
  end
end
