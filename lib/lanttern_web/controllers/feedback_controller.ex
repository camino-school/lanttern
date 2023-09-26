defmodule LantternWeb.FeedbackController do
  use LantternWeb, :controller

  import LantternWeb.AssessmentsHelpers
  import LantternWeb.IdentityHelpers
  import LantternWeb.SchoolsHelpers

  alias Lanttern.Assessments
  alias Lanttern.Assessments.Feedback

  def index(conn, _params) do
    feedback_list =
      Assessments.list_feedback(preloads: [:assessment_point, :student, profile: :teacher])

    render(conn, :index, feedback_list: feedback_list)
  end

  def new(conn, _params) do
    assessment_point_options = generate_assessment_point_options()
    student_options = generate_student_options()
    profile_options = generate_teacher_profile_options()
    changeset = Assessments.change_feedback(%Feedback{})

    render(conn, :new,
      assessment_point_options: assessment_point_options,
      student_options: student_options,
      profile_options: profile_options,
      changeset: changeset
    )
  end

  def create(conn, %{"feedback" => feedback_params}) do
    case Assessments.create_feedback(feedback_params) do
      {:ok, feedback} ->
        conn
        |> put_flash(:info, "Feedback created successfully.")
        |> redirect(to: ~p"/admin/feedback/#{feedback}")

      {:error, %Ecto.Changeset{} = changeset} ->
        assessment_point_options = generate_assessment_point_options()
        student_options = generate_student_options()
        profile_options = generate_teacher_profile_options()

        render(conn, :new,
          assessment_point_options: assessment_point_options,
          student_options: student_options,
          profile_options: profile_options,
          changeset: changeset
        )
    end
  end

  def show(conn, %{"id" => id}) do
    feedback =
      Assessments.get_feedback!(id, preloads: [:assessment_point, :student, profile: :teacher])

    render(conn, :show, feedback: feedback)
  end

  def edit(conn, %{"id" => id}) do
    feedback = Assessments.get_feedback!(id)
    assessment_point_options = generate_assessment_point_options()
    student_options = generate_student_options()
    profile_options = generate_teacher_profile_options()
    changeset = Assessments.change_feedback(feedback)

    render(conn, :edit,
      feedback: feedback,
      assessment_point_options: assessment_point_options,
      student_options: student_options,
      profile_options: profile_options,
      changeset: changeset
    )
  end

  def update(conn, %{"id" => id, "feedback" => feedback_params}) do
    feedback = Assessments.get_feedback!(id)

    case Assessments.update_feedback(feedback, feedback_params) do
      {:ok, feedback} ->
        conn
        |> put_flash(:info, "Feedback updated successfully.")
        |> redirect(to: ~p"/admin/feedback/#{feedback}")

      {:error, %Ecto.Changeset{} = changeset} ->
        assessment_point_options = generate_assessment_point_options()
        student_options = generate_student_options()
        profile_options = generate_teacher_profile_options()

        render(conn, :edit,
          feedback: feedback,
          assessment_point_options: assessment_point_options,
          student_options: student_options,
          profile_options: profile_options,
          changeset: changeset
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    feedback = Assessments.get_feedback!(id)
    {:ok, _feedback} = Assessments.delete_feedback(feedback)

    conn
    |> put_flash(:info, "Feedback deleted successfully.")
    |> redirect(to: ~p"/admin/feedback")
  end
end
