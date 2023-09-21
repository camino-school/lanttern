defmodule LantternWeb.FeedbackCommentFormComponentTest do
  use LantternWeb.ConnCase

  alias Lanttern.Repo
  alias Lanttern.SchoolsFixtures
  alias Lanttern.AssessmentsFixtures

  @live_view_path_base "/assessment_points"
  @overlay_selector "#feedback-overlay"
  @form_selector "#feedback-comment-form-new"

  setup :register_and_log_in_user

  describe "Create feedback comment in assessment points live view" do
    setup :create_assessment_point_with_feedback

    test "feedback comment form shows in feedback overlay", %{
      conn: conn,
      assessment_point: assessment_point
    } do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # open overlay
      view
      |> element("button", "Not completed yet")
      |> render_click()

      # assert form is rendered in overlay
      assert view
             |> element("#{@overlay_selector} #{@form_selector}")
             |> has_element?()
    end

    test "after creating feedback comment using form, feedback is displayed in overlay", %{
      conn: conn,
      assessment_point: assessment_point,
      user: user
    } do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # open overlay
      view
      |> element("button", "Not completed yet")
      |> render_click()

      # submit form
      view
      |> element("#{@overlay_selector} #{@form_selector}")
      |> render_submit(%{
        "comment" => %{
          "comment" => "new feedback comment",
          "profile_id" => user.current_profile.id
        }
      })

      # assert comment was actually created (just in case!)
      assert Repo.get_by!(Lanttern.Conversation.Comment,
               profile_id: user.current_profile.id
             )

      # assert in a new render(view) to "wait" for brodcast and send_update
      assert render(view) =~ ~r/<p.+>\s*new feedback comment\s*<\/p>/
    end
  end

  defp create_assessment_point_with_feedback(_) do
    assessment_point = AssessmentsFixtures.assessment_point_fixture()
    student = SchoolsFixtures.student_fixture()

    # create assessment point entry to render the student row,
    # which contains the feedback button

    _assessment_point_entry =
      AssessmentsFixtures.assessment_point_entry_fixture(%{
        assessment_point_id: assessment_point.id,
        student_id: student.id
      })

    feedback =
      AssessmentsFixtures.feedback_fixture(%{
        assessment_point_id: assessment_point.id,
        student_id: student.id
      })
      |> Repo.preload(profile: :teacher)

    %{
      assessment_point: assessment_point,
      student: student,
      teacher: feedback.profile.teacher,
      feedback: feedback
    }
  end
end
