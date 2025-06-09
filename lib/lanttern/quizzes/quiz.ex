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

  @doc false
  def changeset(quiz, attrs) do
    quiz
    |> cast(attrs, [:position, :title, :description, :moment_id])
    |> validate_required([:title, :description, :moment_id])
  end
end
