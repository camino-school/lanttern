defmodule LantternWeb.StudentLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.SchoolsFixtures

  @live_view_base_path "/school/student"

  setup [:register_and_log_in_teacher]

  describe "Student live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id

      student =
        SchoolsFixtures.student_fixture(%{school_id: school_id, name: "some student abc xyz"})

      conn = get(conn, "#{@live_view_base_path}/#{student.id}")

      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*some student abc xyz\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "list classes", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      class_b = SchoolsFixtures.class_fixture(%{school_id: school_id, name: "bbb"})
      class_a = SchoolsFixtures.class_fixture(%{school_id: school_id, name: "aaa"})

      student =
        SchoolsFixtures.student_fixture(%{
          school_id: school_id,
          classes_ids: [class_a.id, class_b.id]
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{student.id}")

      assert view |> has_element?("p", class_a.name)
      assert view |> has_element?("p", class_b.name)
    end
  end

  describe "Student management permissions" do
    test "allow user with school management permissions to edit student", context do
      %{conn: conn, user: user} = add_school_management_permissions(context)
      school_id = user.current_profile.school_id
      student = SchoolsFixtures.student_fixture(%{school_id: school_id, name: "student abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{student.id}?edit=true")

      assert view |> has_element?("#student-form-overlay h2", "Edit student")
    end

    test "prevent user without school management permissions to edit class", %{
      conn: conn,
      user: user
    } do
      school_id = user.current_profile.school_id
      student = SchoolsFixtures.student_fixture(%{school_id: school_id, name: "student abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{student.id}?edit=true")

      refute view |> has_element?("#student-form-overlay h2", "Edit student")
    end
  end
end
