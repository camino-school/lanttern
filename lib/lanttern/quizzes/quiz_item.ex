defmodule Lanttern.Quizzes.QuizItem do
  @moduledoc """
  The `QuizItem` schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  use Gettext, backend: Lanttern.Gettext

  import Lanttern.RepoHelpers, only: [get_next_position: 1]

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
    field :type, Ecto.Enum, values: [:multiple_choice, :text]
    field :description, :string

    belongs_to :quiz, Quiz

    timestamps()
  end

  @required_fields [:description, :type, :quiz_id]
  # position is required in the DB, but it has default values,
  # so it's ok to skip changeset validation
  @optional_fields [:position, :description]
  @all_fields @required_fields ++ @optional_fields

  @doc false
  def changeset(quiz_item, attrs) do
    quiz_item
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
  end

  @doc """
  Set the position in changeset for new quiz items based on existing quiz items.

  Skip if position already present in changeset.
  """
  def set_position_in_new(%Ecto.Changeset{valid?: true} = changeset) do
    case get_change(changeset, :position) do
      nil ->
        quiz_id = get_field(changeset, :quiz_id)

        position =
          from(
            qi in __MODULE__,
            where: qi.quiz_id == ^quiz_id
          )
          |> get_next_position()

        put_change(changeset, :position, position)

      _ ->
        changeset
    end
  end

  def set_position_in_new(%Ecto.Changeset{} = changeset), do: changeset
end
