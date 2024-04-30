defmodule Lanttern.Conversation.Comment do
  @moduledoc """
  The `Comment` schema
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Lanttern.Repo

  alias Lanttern.Assessments.Feedback
  alias Lanttern.Identity.Profile

  @type t :: %__MODULE__{
          id: pos_integer(),
          comment: String.t(),
          mark_feedback_for_completion: boolean(),
          feedback_id_for_completion: pos_integer(),
          completed_feedback: Feedback.t(),
          profile: Profile.t(),
          profile_id: pos_integer(),
          feedback: [Feedback.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "comments" do
    field :comment, :string

    field :mark_feedback_for_completion, :boolean, virtual: true
    field :feedback_id_for_completion, :id, virtual: true

    has_one :completed_feedback, Feedback,
      foreign_key: :completion_comment_id,
      on_replace: :nilify

    belongs_to :profile, Profile

    many_to_many :feedback, Feedback,
      join_through: "feedback_comments",
      on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [
      :comment,
      :profile_id,
      :mark_feedback_for_completion,
      :feedback_id_for_completion
    ])
    |> validate_required([:comment, :profile_id])
    |> foreign_key_constraint(:profile_id, message: "Profile not found")
    |> handle_feedback_completion()
  end

  defp handle_feedback_completion(changeset) do
    changeset
    |> get_change(:mark_feedback_for_completion)
    |> handle_feedback_completion(changeset)
  end

  defp handle_feedback_completion(true, changeset) do
    feedback_id =
      get_field(changeset, :feedback_id_for_completion)

    case Repo.get(Feedback, feedback_id) do
      nil ->
        changeset
        |> add_error(:completed_feedback, "Feedback not found")

      feedback ->
        changeset
        |> put_assoc(:completed_feedback, feedback)
    end
  end

  defp handle_feedback_completion(_false_or_nil, changeset) do
    # if comment exists and a Feedback references it, remove association
    with feedback_id when not is_nil(feedback_id) <-
           get_field(changeset, :feedback_id_for_completion),
         comment_id when not is_nil(comment_id) <-
           get_field(changeset, :id),
         feedback when not is_nil(feedback) <-
           Repo.get_by(Feedback,
             id: feedback_id,
             completion_comment_id: comment_id
           ) do
      changeset
      |> put_assoc(:completed_feedback, nil)
    else
      _ ->
        changeset
    end
  end
end
