defmodule Lanttern.Quizzes.Quiz do
  @moduledoc """
  The `Quiz` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.LearningContext.Moment

  @type t :: %__MODULE__{
          id: pos_integer(),
          position: non_neg_integer(),
          title: String.t(),
          description: String.t(),
          moment: Moment.t() | Ecto.Association.NotLoaded.t(),
          moment_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "quizzes" do
    field :position, :integer, default: 0
    field :title, :string
    field :description, :string

    belongs_to :moment, Moment

    timestamps()
  end

  @required_fields [:title, :description, :moment_id]
  # position is required in the DB, but it has default values,
  # so it's ok to skip changeset validation
  @optional_fields [:position]
  @all_fields @required_fields ++ @optional_fields

  @doc false
  def changeset(quiz, attrs) do
    quiz
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
  end
end
