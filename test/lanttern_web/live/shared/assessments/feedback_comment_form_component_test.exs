defmodule LantternWeb.Assessments.FeedbackCommentFormComponentTest do
  use LantternWeb.ConnCase

  alias Lanttern.Repo
  alias Lanttern.SchoolsFixtures
  alias Lanttern.AssessmentsFixtures
  alias Lanttern.ConversationFixtures

  @live_view_path_base "/assessment_points"
  @overlay_selector "#feedback-overlay"
  @base_form_selector "#feedback-comment-form"
  @new_comment_form_selector "#{@base_form_selector}-new"

  setup [:register_and_log_in_root_admin, :register_and_log_in_teacher]

  describe "Create feedback comment in assessment points live view" do
    setup :create_assessment_point_with_feedback

    test "feedback comment form shows in feedback overlay", %{
      conn: conn,
      assessment_point: assessment_point
    } do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # open overlay
      view
      |> element("a", "Not completed yet")
      |> render_click()

      # assert form is rendered in overlay
      assert view
             |> element("#{@overlay_selector} #{@new_comment_form_selector}")
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
      |> element("a", "Not completed yet")
      |> render_click()

      # submit form
      view
      |> element("#{@overlay_selector} #{@new_comment_form_selector}")
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
    scale = Lanttern.GradingFixtures.scale_fixture()
    assessment_point = AssessmentsFixtures.assessment_point_fixture(%{scale_id: scale.id})
    student = SchoolsFixtures.student_fixture()

    # create assessment point entry to render the student row,
    # which contains the feedback button

    _assessment_point_entry =
      AssessmentsFixtures.assessment_point_entry_fixture(%{
        assessment_point_id: assessment_point.id,
        student_id: student.id,
        scale_id: scale.id,
        scale_type: scale.type
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

  describe "Update feedback comment in assessment points live view" do
    setup [:create_assessment_point_with_feedback, :create_feedback_comment]

    test "update feedback comment form shows in feedback overlay", %{
      conn: conn,
      assessment_point: assessment_point,
      feedback_comment: feedback_comment
    } do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # open overlay
      view
      |> element("a", "Not completed yet")
      |> render_click()

      # assert comment is rendered in overlay
      assert view
             |> element("#{@overlay_selector} p", feedback_comment.comment)
             |> has_element?()

      # click comment edit and assert edit form is rendered
      view
      |> element("#{@overlay_selector} button", "Edit")
      |> render_click()

      form_selector = "#{@base_form_selector}-#{feedback_comment.id}"

      assert view
             |> element("#{@overlay_selector} #{form_selector}")
             |> has_element?()
    end

    test "after updating feedback comment using form, updated comment is displayed in overlay", %{
      conn: conn,
      assessment_point: assessment_point,
      user: user,
      feedback_comment: feedback_comment
    } do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # open overlay
      view
      |> element("a", "Not completed yet")
      |> render_click()

      # click edit comment button
      view
      |> element("#{@overlay_selector} button", "Edit")
      |> render_click()

      # submit form
      view
      |> element("#{@overlay_selector} #{@base_form_selector}-#{feedback_comment.id}")
      |> render_submit(%{
        "comment" => %{
          "comment" => "updated feedback comment",
          "profile_id" => user.current_profile.id
        }
      })

      # assert in a new render(view) to "wait" for brodcast and send_update
      assert render(view) =~ ~r/<p.+>\s*updated feedback comment\s*<\/p>/
    end
  end

  describe "Delete feedback comment in assessment points live view" do
    setup [:create_assessment_point_with_feedback, :create_feedback_comment]

    test "delete feedback comment form shows in feedback overlay", %{
      conn: conn,
      assessment_point: assessment_point,
      feedback_comment: feedback_comment
    } do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # open overlay
      view
      |> element("a", "Not completed yet")
      |> render_click()

      # assert comment is rendered in overlay
      assert view
             |> element("#{@overlay_selector} p", feedback_comment.comment)
             |> has_element?()

      # assert delete comment button is rendered in overlay
      view
      |> element("#{@overlay_selector} button", "Delete")
      |> render_click()
    end

    test "after deleting feedback comment, comment should be removed from UI", %{
      conn: conn,
      assessment_point: assessment_point,
      feedback_comment: feedback_comment
    } do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # open overlay
      view
      |> element("a", "Not completed yet")
      |> render_click()

      # assert comment is rendered
      {:ok, re} = Regex.compile("<p.+>\\s*#{feedback_comment.comment}\\s*</p>")
      assert render(view) =~ re

      # click delete comment button
      view
      |> element("#{@overlay_selector} button", "Delete")
      |> render_click()

      # refute comment is rendered in a new render(view) to "wait" for brodcast and send_update
      refute render(view) =~ re
    end
  end

  defp create_feedback_comment(%{feedback: feedback, user: user}) do
    feedback_comment =
      ConversationFixtures.feedback_comment_fixture(
        %{profile_id: user.current_profile.id, comment: "Some regex compile safe string"},
        feedback.id
      )

    %{feedback_comment: feedback_comment}
  end
end
