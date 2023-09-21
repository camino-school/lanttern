defmodule Lanttern.Assessments.Feedback do
  use Ecto.Schema
  import Ecto.Changeset

  schema "feedback" do
    field :comment, :string

    belongs_to :profile, Lanttern.Identity.Profile
    belongs_to :student, Lanttern.Schools.Student
    belongs_to :assessment_point, Lanttern.Assessments.AssessmentPoint
    belongs_to :completion_comment, Lanttern.Conversation.Comment

    many_to_many :comments, Lanttern.Conversation.Comment,
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
    |> validate_profile_is_of_type_teacher()
    |> unique_constraint([:assessment_point_id, :student_id],
      message: "Student already has feedback for this assessment point"
    )
  end

  defp validate_profile_is_of_type_teacher(changeset) do
    case get_change(changeset, :profile_id) do
      nil ->
        changeset

      profile_id ->
        profile_id
        |> Lanttern.Identity.get_profile!()
        |> case do
          %{type: "teacher"} -> changeset
          _ -> add_error(changeset, :profile_id, "Only teacher profiles allowed")
        end
    end
  end
end
