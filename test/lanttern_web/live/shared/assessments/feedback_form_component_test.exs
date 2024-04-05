defmodule LantternWeb.Assessments.FeedbackFormComponentTest do
  use LantternWeb.ConnCase

  alias Lanttern.Repo
  alias Lanttern.SchoolsFixtures
  alias Lanttern.AssessmentsFixtures

  @live_view_path_base "/assessment_points"
  @overlay_selector "#feedback-overlay"
  @form_selector "#feedback-form"

  setup [:register_and_log_in_root_admin, :register_and_log_in_teacher]

  describe "Create new feedback in assessment points live view" do
    setup :create_assessment_point_without_feedback

    test "after creating feedback using form, feedback is displayed in overlay", %{
      conn: conn,
      assessment_point: assessment_point,
      student: student,
      user: user
    } do
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # open overlay
      view
      |> element("a", "No feedback yet")
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

    defp create_assessment_point_without_feedback(_) do
      scale = Lanttern.GradingFixtures.scale_fixture()
      assessment_point = AssessmentsFixtures.assessment_point_fixture(%{scale_id: scale.id})

      # create assessment point entry to render the student row,
      # which contains the feedback button
      student = SchoolsFixtures.student_fixture()

      _assessment_point_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          scale_id: scale.id,
          scale_type: scale.type,
          student_id: student.id
        })

      %{
        assessment_point: assessment_point,
        student: student
      }
    end
  end
end
