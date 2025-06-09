defmodule Lanttern.Quizzes.QuizItemStudentEntry do
  @moduledoc """
  The `QuizItemStudentEntry` schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Quizzes.QuizItem
  alias Lanttern.Quizzes.QuizItemAlternative
  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer(),
          answer: String.t() | nil,
          reasoning: String.t() | nil,
          score: float() | nil,
          feedback: String.t() | nil,
          quiz_item: QuizItem.t() | Ecto.Association.NotLoaded.t(),
          quiz_item_id: pos_integer(),
          student: Student.t() | Ecto.Association.NotLoaded.t(),
          student_id: pos_integer(),
          quiz_item_alternative: QuizItemAlternative.t() | Ecto.Association.NotLoaded.t() | nil,
          quiz_item_alternative_id: pos_integer() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "quiz_item_student_entries" do
    field :answer, :string
    field :reasoning, :string
    field :score, :float
    field :feedback, :string

    belongs_to :quiz_item, QuizItem
    belongs_to :student, Student
    belongs_to :quiz_item_alternative, QuizItemAlternative

    timestamps()
  end

  @doc false
  def changeset(quiz_item_student_entry, attrs) do
    quiz_item_student_entry
    |> cast(attrs, [
      :answer,
      :reasoning,
      :score,
      :feedback,
      :quiz_item_id,
      :student_id,
      :quiz_item_alternative_id
    ])
    |> validate_required([:quiz_item_id, :student_id])
    |> check_constraint(:answer,
      name: :required_input,
      message: gettext("Answer must be provided")
    )
    |> check_constraint(:quiz_item_alternative_id,
      name: :required_input,
      message: gettext("Alternative must be provided")
    )
    |> unique_constraint([:student_id, :quiz_item_id])
  end
end
