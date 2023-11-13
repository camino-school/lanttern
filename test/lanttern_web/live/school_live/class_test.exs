defmodule LantternWeb.SchoolLive.ClassTest do
  use LantternWeb.ConnCase

  alias Lanttern.SchoolsFixtures

  @live_view_base_path "/school/class"

  setup [:register_and_log_in_user]

  describe "School live view basic navigation" do
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

      assert view |> has_element?("span", std_a.name)
      assert view |> has_element?("span", std_b.name)
    end
  end
end
