defmodule LantternWeb.GuardianHomeLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.IdentityFixtures
  alias Lanttern.MessageBoardFixtures
  alias Lanttern.StudentsCycleInfo
  alias Lanttern.StudentsCycleInfoFixtures

  @live_view_path "/guardian"

  setup [:register_and_log_in_guardian]

  describe "Guardian home live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)

      assert html_response(conn, 200) =~ ~r"<h1 .+>\s*Hello!\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "display message board", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id

      MessageBoardFixtures.message_fixture(%{
        school_id: school_id,
        name: "some message name",
        description: "some message description"
      })

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("h5", "some message name")
      assert view |> has_element?("p", "some message description")
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
        IdentityFixtures.staff_member_profile_fixture().id,
        student_cycle_info.id,
        %{
          "name" => "some attachment",
          "link" => "https://somevaliduri.com",
          "is_external" => true
        },
        true
      )

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view
             |> has_element?(
               "h3",
               "Additional #{user.current_profile.current_school_cycle.name} information"
             )

      assert view |> has_element?("p", "some shared_info")

      view
      |> element("a", "some attachment")
      |> render_click()

      assert_redirect(view, "https://somevaliduri.com")
    end
  end
end
