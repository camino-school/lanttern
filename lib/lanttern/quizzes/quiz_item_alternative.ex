defmodule Lanttern.Quizzes.QuizItemAlternative do
  @moduledoc """
  The `QuizItemAlternative` schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Quizzes.QuizItem

  @type t :: %__MODULE__{
          id: pos_integer(),
          position: non_neg_integer(),
          description: String.t(),
          is_correct: boolean(),
          quiz_item: QuizItem.t() | Ecto.Association.NotLoaded.t(),
          quiz_item_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "quiz_item_alternatives" do
    field :position, :integer, default: 0
    field :description, :string
    field :is_correct, :boolean, default: false

    belongs_to :quiz_item, QuizItem

    timestamps()
  end

  @required_fields [:description, :quiz_item_id]
  # position and is_correct are required in the DB, but they
  # have default values, so it's ok to skip changeset validation
  @optional_fields [:position, :is_correct]
  @all_fields @required_fields ++ @optional_fields

  @doc false
  def changeset(quiz_item_alternative, attrs) do
    quiz_item_alternative
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:is_correct, :quiz_item_id],
      name: :quiz_item_alternatives_is_correct_quiz_item_id_index,
      message: gettext("There's already a correct alternative for this question")
    )
  end
end
