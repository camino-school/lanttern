defmodule LantternWeb.ClassLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.SchoolsFixtures

  @live_view_base_path "/school/class"

  setup [:register_and_log_in_user]

  describe "Class live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn, user: user} do
      school = user.current_profile.teacher.school
      class = SchoolsFixtures.class_fixture(%{school_id: school.id, name: "some class abc xyz"})
      conn = get(conn, "#{@live_view_base_path}/#{class.id}")

      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*some class abc xyz\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "list students", %{conn: conn, user: user} do
      school = user.current_profile.teacher.school
      std_b = SchoolsFixtures.student_fixture(%{school_id: school.id, name: "bbb"})
      std_a = SchoolsFixtures.student_fixture(%{school_id: school.id, name: "aaa"})

      class =
        SchoolsFixtures.class_fixture(%{school_id: school.id, students_ids: [std_a.id, std_b.id]})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{class.id}")

      assert view |> has_element?("a", std_a.name)
      assert view |> has_element?("a", std_b.name)
    end

    test "navigate to student", %{conn: conn, user: user} do
      school = user.current_profile.teacher.school
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})

      class =
        SchoolsFixtures.class_fixture(%{
          school_id: school.id,
          students_ids: [student.id]
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{class.id}")

      view
      |> element("a", student.name)
      |> render_click()

      assert_patch(view, "/school/student/#{student.id}")
    end
  end
end
