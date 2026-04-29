defmodule Lanttern.Lessons.LessonCurriculumItem do
  @moduledoc """
  The `LessonCurriculumItem` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Curricula.CurriculumItem
  alias Lanttern.Lessons.Lesson

  @type t :: %__MODULE__{
          id: pos_integer(),
          position: non_neg_integer(),
          lesson: Lesson.t() | Ecto.Association.NotLoaded.t(),
          lesson_id: pos_integer(),
          curriculum_item: CurriculumItem.t() | Ecto.Association.NotLoaded.t(),
          curriculum_item_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "lesson_curriculum_items" do
    field :position, :integer, default: 0

    belongs_to :lesson, Lesson
    belongs_to :curriculum_item, CurriculumItem

    timestamps()
  end

  @doc false
  def changeset(lesson_curriculum_item, attrs) do
    lesson_curriculum_item
    |> cast(attrs, [:position, :lesson_id, :curriculum_item_id])
    |> validate_required([:position, :lesson_id, :curriculum_item_id])
    |> unique_constraint([:curriculum_item_id, :lesson_id],
      name: "lesson_curriculum_items_curriculum_item_id_lesson_id_index",
      message: gettext("Curriculum item already linked to this lesson")
    )
  end
end
