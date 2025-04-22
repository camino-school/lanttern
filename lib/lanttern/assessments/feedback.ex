defmodule Lanttern.Assessments.Feedback do
  @moduledoc """
  The `Feedback` schema
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Conversation.Comment
  alias Lanttern.Identity.Profile
  alias Lanttern.Schools.Student

  @type t :: %__MODULE__{
          id: pos_integer(),
          comment: String.t(),
          profile: Profile.t(),
          profile_id: pos_integer(),
          student: Student.t(),
          student_id: pos_integer(),
          assessment_point: AssessmentPoint.t(),
          assessment_point_id: pos_integer(),
          completion_comment: Comment.t(),
          completion_comment_id: pos_integer(),
          comments: [Comment.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "feedback" do
    field :comment, :string

    belongs_to :profile, Profile
    belongs_to :student, Student
    belongs_to :assessment_point, AssessmentPoint
    belongs_to :completion_comment, Comment

    many_to_many :comments, Comment,
      join_through: "feedback_comments",
      on_replace: :delete,
      preload_order: [asc: :inserted_at]

    timestamps()
  end

  @doc false
  def changeset(feedback, attrs) do
    feedback
    |> cast(attrs, [
      :comment,
      :profile_id,
      :student_id,
      :assessment_point_id,
      :completion_comment_id
    ])
    |> validate_required([:comment, :profile_id, :student_id, :assessment_point_id])
    |> validate_profile_is_of_type_staff()
    |> unique_constraint([:assessment_point_id, :student_id],
      message: "Student already has feedback for this assessment point"
    )
  end

  defp validate_profile_is_of_type_staff(changeset) do
    case get_change(changeset, :profile_id) do
      nil ->
        changeset

      profile_id ->
        profile_id
        |> Lanttern.Identity.get_profile!()
        |> case do
          %{type: "staff"} -> changeset
          _ -> add_error(changeset, :profile_id, "Only staff profiles allowed")
        end
    end
  end
end
