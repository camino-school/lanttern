defmodule Lanttern.Quizzes.Quiz do
  @moduledoc """
  The `Quiz` schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]

  use Gettext, backend: Lanttern.Gettext

  import Lanttern.RepoHelpers, only: [get_next_position: 1]

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

  @doc """
  Set the position in changeset for new quizzes based on existing moment quizzes.

  Skip if position already present in changeset.
  """
  def set_position_in_new(%Ecto.Changeset{valid?: true} = changeset) do
    case get_change(changeset, :position) do
      nil ->
        moment_id = get_field(changeset, :moment_id)

        position =
          from(
            q in __MODULE__,
            where: q.moment_id == ^moment_id
          )
          |> get_next_position()

        put_change(changeset, :position, position)

      _ ->
        changeset
    end
  end

  def set_position_in_new(%Ecto.Changeset{} = changeset), do: changeset
end
