defmodule Lanttern.Lessons.LessonLog do
  @moduledoc """
  The `LessonLog` schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @behaviour Lanttern.AuditLog

  @schema_prefix "log"
  schema "lessons" do
    field :lesson_id, :integer
    field :profile_id, :integer
    field :operation, :string
    field :name, :string
    field :description, :string
    field :teacher_notes, :string
    field :differentiation_notes, :string
    field :is_published, :boolean
    field :position, :integer
    field :strand_id, :integer
    field :moment_id, :integer
    field :subjects_ids, {:array, :integer}
    field :tags_ids, {:array, :integer}
    field :is_ai_agent, :boolean, default: false

    timestamps(updated_at: false)
  end

  @doc false
  def changeset(lesson_log, attrs) do
    lesson_log
    |> cast(attrs, [
      :lesson_id,
      :profile_id,
      :operation,
      :name,
      :description,
      :teacher_notes,
      :differentiation_notes,
      :is_published,
      :position,
      :strand_id,
      :moment_id,
      :subjects_ids,
      :tags_ids,
      :is_ai_agent
    ])
    |> validate_required([
      :lesson_id,
      :profile_id,
      :operation,
      :name,
      :position,
      :strand_id
    ])
  end

  @impl Lanttern.AuditLog
  def build_log_attrs(%Lanttern.Lessons.Lesson{} = lesson) do
    lesson = Lanttern.Repo.preload(lesson, [:subjects, :tags])

    %{
      lesson_id: lesson.id,
      name: lesson.name,
      description: lesson.description,
      teacher_notes: lesson.teacher_notes,
      differentiation_notes: lesson.differentiation_notes,
      is_published: lesson.is_published,
      position: lesson.position,
      strand_id: lesson.strand_id,
      moment_id: lesson.moment_id,
      subjects_ids: Enum.map(lesson.subjects, & &1.id),
      tags_ids: Enum.map(lesson.tags, & &1.id)
    }
  end
end
