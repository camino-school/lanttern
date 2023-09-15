defmodule Lanttern.Conversation.Comment do
  use Ecto.Schema
  import Ecto.Changeset
  alias Lanttern.Repo

  schema "comments" do
    field :comment, :string

    field :mark_feedback_id_for_completion, :id, virtual: true

    has_one :completed_feedback, Lanttern.Assessments.Feedback,
      foreign_key: :completion_comment_id

    belongs_to :profile, Lanttern.Identity.Profile

    timestamps()
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:comment, :profile_id, :mark_feedback_id_for_completion])
    |> validate_required([:comment, :profile_id])
    |> foreign_key_constraint(:profile_id, message: "Profile not found")
    |> handle_feedback_completion()
  end

  defp handle_feedback_completion(changeset) do
    changeset
    |> get_change(:mark_feedback_id_for_completion)
    |> handle_feedback_completion(changeset)
  end

  defp handle_feedback_completion(nil, changeset), do: changeset

  defp handle_feedback_completion(feedback_id, changeset) do
    case Repo.get(Lanttern.Assessments.Feedback, feedback_id) do
      nil ->
        changeset
        |> add_error(:completed_feedback, "Feedback not found")

      feedback ->
        changeset
        |> put_assoc(:completed_feedback, feedback)
    end
  end
end
