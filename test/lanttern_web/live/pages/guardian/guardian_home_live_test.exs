defmodule LantternWeb.GuardianHomeLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.IdentityFixtures
  alias Lanttern.ReportingFixtures
  alias Lanttern.SchoolsFixtures
  alias Lanttern.StudentsCycleInfo
  alias Lanttern.StudentsCycleInfoFixtures

  @live_view_path "/guardian"

  setup [:register_and_log_in_guardian]

  describe "Guardian home live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)

      assert html_response(conn, 200) =~ ~r"<h1 .+>\s*Welcome!\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "list student report cards", %{conn: conn, user: user, student: student} do
      school_id = user.current_profile.school_id
      parent_cycle_id = user.current_profile.current_school_cycle.id

      cycle =
        SchoolsFixtures.cycle_fixture(%{
          school_id: school_id,
          parent_cycle_id: parent_cycle_id
        })

      report_card =
        ReportingFixtures.report_card_fixture(%{
          name: "Some report card name ABC",
          cycle_id: cycle.id
        })

      student_report_card =
        ReportingFixtures.student_report_card_fixture(%{
          report_card_id: report_card.id,
          student_id: student.id,
          allow_guardian_access: true
        })

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("a", "Some report card name ABC")

      view
      |> element("a", "Some report card name ABC")
      |> render_click()

      assert_redirect(view, "/student_report_card/#{student_report_card.id}")
    end

    test "display student cycle info", %{conn: conn, user: user, student: student} do
      school_id = user.current_profile.school_id

      student_cycle_info =
        StudentsCycleInfoFixtures.student_cycle_info_fixture(%{
          school_id: school_id,
          student_id: student.id,
          cycle_id: user.current_profile.current_school_cycle.id,
          shared_info: "some shared_info"
        })

      StudentsCycleInfo.create_student_cycle_info_attachment(
        IdentityFixtures.teacher_profile_fixture().id,
        student_cycle_info.id,
        %{
          "name" => "some attachment",
          "link" => "https://somevaliduri.com",
          "is_external" => true
        },
        true
      )

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("h3", "Additional cycle information")
      assert view |> has_element?("p", "some shared_info")

      view
      |> element("a", "some attachment")
      |> render_click()

      assert_redirect(view, "https://somevaliduri.com")
    end
  end
end
