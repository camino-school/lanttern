defmodule LantternWeb.AssessmentPointLive.ShowTest do
  use LantternWeb.ConnCase

  alias Lanttern.Repo
  alias Lanttern.AssessmentsFixtures
  alias Lanttern.ConversationFixtures
  alias Lanttern.CurriculaFixtures
  alias Lanttern.GradingFixtures
  alias Lanttern.SchoolsFixtures

  @live_view_path_base "/assessment_points"
  @overlay_selector "#feedback-overlay"

  setup :register_and_log_in_user

  describe "Assessment point details live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      %{id: id} = AssessmentsFixtures.assessment_point_fixture()

      conn = get(conn, "#{@live_view_path_base}/#{id}")
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*Assessment point details\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "display assessment point details", %{conn: conn} do
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()
      scale = GradingFixtures.scale_fixture()
      attrs = %{curriculum_item_id: curriculum_item.id, scale: scale.id}

      %{
        id: id,
        name: name,
        description: description,
        datetime: datetime
      } =
        AssessmentsFixtures.assessment_point_fixture(attrs)

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{id}")

      assert view |> has_element?("h2", name)
      assert view |> has_element?("p", description)

      assert view
             |> has_element?(
               "div",
               Timex.format!(Timex.local(datetime), "{Mshort} {D}, {YYYY}, {h24}:{m}")
             )

      assert view |> has_element?("div", curriculum_item.name)
      assert view |> has_element?("div", scale.name)
    end

    test "redirect to /assessment_points when supplied id does not exist", %{conn: conn} do
      wrong_id = "1000000"

      {:error, {:redirect, %{to: path, flash: flash}}} =
        live(conn, "#{@live_view_path_base}/#{wrong_id}")

      assert path == "/assessment_points"
      assert flash["error"] == "Couldn't find assessment point"
    end

    test "redirect to /assessment_points when supplied id is string", %{conn: conn} do
      wrong_id = "abcd"

      {:error, {:redirect, %{to: path, flash: flash}}} =
        live(conn, "#{@live_view_path_base}/#{wrong_id}")

      assert path == "/assessment_points"
      assert flash["error"] == "Couldn't find assessment point"
    end
  end

  describe "Assessment point details live view feedback" do
    test "feedback buttons display", %{conn: conn} do
      assessment_point = AssessmentsFixtures.assessment_point_fixture()

      std_no_feedback = SchoolsFixtures.student_fixture()
      std_incomplete_feedback = SchoolsFixtures.student_fixture()
      std_completed_feedback = SchoolsFixtures.student_fixture()

      _entry_no_feedback =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: std_no_feedback.id
        })

      _entry_incomplete_feedback =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: std_incomplete_feedback.id
        })

      _entry_completed_feedback =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: std_completed_feedback.id
        })

      _incomplete_feedback =
        AssessmentsFixtures.feedback_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: std_incomplete_feedback.id
        })

      _completed_feedback =
        AssessmentsFixtures.feedback_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: std_completed_feedback.id,
          completion_comment_id: ConversationFixtures.comment_fixture().id
        })

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      assert view |> has_element?("a", "No feedback yet")
      assert view |> has_element?("a", "Not completed yet")
      assert view |> has_element?("a", ~r/Completed [A-Z][a-z]{2} [0-9]{1,2}, [0-9]{4} 🎉/)
    end
  end

  describe "Create new feedback in assessment points live view" do
    setup :create_assessment_point_without_feedback

    test "feedback overlay shows in live view", %{conn: conn, assessment_point: assessment_point} do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # confirms overlay is not rendered
      refute view
             |> element("#{@overlay_selector} h2", "Feedback")
             |> has_element?()

      # click link to render
      view
      |> element("a", "No feedback yet")
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
      |> element("a", "No feedback yet")
      |> render_click()

      # assert from/to is correct
      {:ok, regex} =
        Regex.compile("From.+#{user.current_profile.teacher.name}.+To.+#{student.name}", "s")

      assert view
             |> element("#{@overlay_selector}", regex)
             |> has_element?()
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
  end

  describe "Display existing feedback in assessment points live view" do
    setup :create_assessment_point_with_feedback

    test "feedback overlay shows in live view", %{conn: conn, assessment_point: assessment_point} do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # confirms overlay is not rendered
      refute view
             |> element("#{@overlay_selector} h2", "Feedback")
             |> has_element?()

      # click link to render
      view
      |> element("a", "Not completed yet")
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
      |> element("a", "Not completed yet")
      |> render_click()

      # assert from/to is correct
      {:ok, regex} =
        Regex.compile("From.+#{teacher.name}.+To.+#{student.name}", "s")

      assert view
             |> element("#{@overlay_selector}", regex)
             |> has_element?()
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

  describe "Assessment point details markdown support" do
    test "renders HTML correctly", %{conn: conn} do
      assessment_point =
        AssessmentsFixtures.assessment_point_fixture(%{
          description: """
          paragraph 1 with *italic*

          paragraph 2 with **bold**

          ## h2 heading

          - list item
          """
        })

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      assert view |> has_element?("p", "paragraph 1")
      assert view |> has_element?("em", "italic")
      assert view |> has_element?("p", "paragraph 2")
      assert view |> has_element?("strong", "bold")
      assert view |> has_element?("h2", "h2 heading")
      assert view |> has_element?("li", "list item")
    end
  end
end
