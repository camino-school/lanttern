defmodule LantternWeb.FeedbackOverlayComponentTest do
  use LantternWeb.ConnCase

  alias Lanttern.Repo
  alias Lanttern.SchoolsFixtures
  alias Lanttern.AssessmentsFixtures

  @live_view_path_base "/assessment_points"
  @overlay_selector "#feedback-overlay"
  @form_selector "#feedback-form"

  setup :register_and_log_in_user

  describe "Create new feedback in assessment points live view" do
    setup :create_assessment_point_without_feedback

    test "feedback overlay shows in live view", %{conn: conn, assessment_point: assessment_point} do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # confirms overlay is not rendered
      refute view
             |> element("#{@overlay_selector} h2", "Feedback")
             |> has_element?()

      # click button to render
      view
      |> element("button", "No feedback yet")
      |> render_click()

      # assert overlay is rendered
      assert view
             |> element("#{@overlay_selector} h2", "Feedback")
             |> has_element?()
    end

    test "from/to is based on the current user", %{
      conn: conn,
      assessment_point: assessment_point,
      user: user,
      student: student
    } do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # open overlay
      view
      |> element("button", "No feedback yet")
      |> render_click()

      # assert from/to is correct
      {:ok, regex} =
        Regex.compile("From.+#{user.current_profile.teacher.name}.+To.+#{student.name}", "s")

      assert view
             |> element("#{@overlay_selector}", regex)
             |> has_element?()
    end

    test "after creating feedback using form, feedback is displayed in overlay", %{
      conn: conn,
      assessment_point: assessment_point,
      student: student,
      user: user
    } do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # open overlay
      view
      |> element("button", "No feedback yet")
      |> render_click()

      # submit with extra info
      view
      |> element("#{@overlay_selector} #{@form_selector}")
      |> render_submit(%{
        "feedback" => %{
          "comment" => "new feedback comment",
          "assessment_point_id" => assessment_point.id,
          "student_id" => student.id,
          "profile_id" => user.current_profile.id
        }
      }) =~ ~r/<p.+>\s*new feedback comment\s*<\/p>/

      # assert feedback was actually created (just in case!)
      assert Repo.get_by!(Lanttern.Assessments.Feedback,
               assessment_point_id: assessment_point.id,
               student_id: student.id,
               profile_id: user.current_profile.id
             )
    end
  end

  defp create_assessment_point_without_feedback(_) do
    assessment_point = AssessmentsFixtures.assessment_point_fixture()

    # create assessment point entry to render the student row,
    # which contains the feedback button
    student = SchoolsFixtures.student_fixture()

    _assessment_point_entry =
      AssessmentsFixtures.assessment_point_entry_fixture(%{
        assessment_point_id: assessment_point.id,
        student_id: student.id
      })

    %{
      assessment_point: assessment_point,
      student: student
    }
  end

  describe "Display existing feedback in assessment points live view" do
    setup :create_assessment_point_with_feedback

    test "feedback overlay shows in live view", %{conn: conn, assessment_point: assessment_point} do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # confirms overlay is not rendered
      refute view
             |> element("#{@overlay_selector} h2", "Feedback")
             |> has_element?()

      # click button to render
      view
      |> element("button", "Not completed yet")
      |> render_click()

      # assert overlay is rendered
      assert view
             |> element("#{@overlay_selector} h2", "Feedback")
             |> has_element?()
    end

    test "from/to is based on the existing feedback", %{
      conn: conn,
      assessment_point: assessment_point,
      teacher: teacher,
      student: student
    } do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # open overlay
      view
      |> element("button", "Not completed yet")
      |> render_click()

      # assert from/to is correct
      {:ok, regex} =
        Regex.compile("From.+#{teacher.name}.+To.+#{student.name}", "s")

      assert view
             |> element("#{@overlay_selector}", regex)
             |> has_element?()
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
