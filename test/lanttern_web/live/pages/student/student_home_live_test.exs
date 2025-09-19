defmodule LantternWeb.StudentHomeLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory

  alias Lanttern.IdentityFixtures
  alias Lanttern.Schools
  alias Lanttern.StudentsCycleInfo

  @live_view_path "/student"

  setup [:register_and_log_in_student]

  describe "Student home live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)

      assert html_response(conn, 200) =~ ~r"<h1 .+>\s*Welcome!\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "display message board", %{conn: conn, user: user} do
      school = Schools.get_school!(user.current_profile.school_id)
      section = insert(:section, %{school: school})

      insert(:message, %{
        school: school,
        section: section,
        name: "some message name",
        description: "some message description"
      })

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("h5", "some message name")
      assert view |> has_element?("p", "some message description")
    end

    test "display student cycle info", %{conn: conn, user: user, student: student} do
      school = Schools.get_school!(user.current_profile.school_id)
      cycle = Schools.get_cycle!(user.current_profile.current_school_cycle.id)

      student_cycle_info =
        insert(:student_cycle_info, %{
          school: school,
          student: student,
          cycle: cycle,
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
