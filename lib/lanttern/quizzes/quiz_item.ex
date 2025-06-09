defmodule Lanttern.Quizzes.QuizItem do
  @moduledoc """
  The `QuizItem` schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Quizzes.Quiz

  @type t :: %__MODULE__{
          id: pos_integer(),
          position: non_neg_integer(),
          type: String.t(),
          description: String.t(),
          quiz: Quiz.t() | Ecto.Association.NotLoaded.t(),
          quiz_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "quiz_items" do
    field :position, :integer, default: 0
    field :type, :string
    field :description, :string

    belongs_to :quiz, Quiz

    timestamps()
  end

  @doc false
  def changeset(quiz_item, attrs) do
    quiz_item
    |> cast(attrs, [:position, :description, :type, :quiz_id])
    |> validate_required([:description, :type, :quiz_id])
    |> check_constraint(:type,
      name: :valid_types,
      message: gettext(~s(Invalid question type \(should be "multiple choice" or "text"\)))
    )
  end
end
