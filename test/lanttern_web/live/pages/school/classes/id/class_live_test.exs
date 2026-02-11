defmodule LantternWeb.ClassLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.SchoolsFixtures

  @live_view_base_path "/school/classes"

  setup [:register_and_log_in_staff_member]

  describe "Class live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      cycle = user.current_profile.current_school_cycle

      class =
        SchoolsFixtures.class_fixture(%{
          school_id: school_id,
          cycle_id: cycle.id,
          name: "some class abc xyz"
        })

      conn = get(conn, "#{@live_view_base_path}/#{class.id}/people")

      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*some class abc xyz \(.+\)\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "list students", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      cycle_id = user.current_profile.current_school_cycle.id

      class =
        SchoolsFixtures.class_fixture(%{school_id: school_id, cycle_id: cycle_id})

      student_a =
        SchoolsFixtures.student_fixture(%{
          name: "student a",
          school_id: school_id,
          classes_ids: [class.id]
        })

      student_b =
        SchoolsFixtures.student_fixture(%{
          name: "student b",
          school_id: school_id,
          classes_ids: [class.id]
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{class.id}/people")

      assert view |> has_element?("a", student_a.name)
      assert view |> has_element?("a", student_b.name)

      view
      |> element("a", student_a.name)
      |> render_click()

      assert_redirect(view, ~p"/school/students/#{student_a}")
    end

    test "displays both staff and students sections in people tab", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      cycle_id = user.current_profile.current_school_cycle.id

      class = SchoolsFixtures.class_fixture(%{school_id: school_id, cycle_id: cycle_id})

      student =
        SchoolsFixtures.student_fixture(%{
          school_id: school_id,
          classes_ids: [class.id]
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{class.id}/people")

      assert view |> has_element?("#staff-section")
      assert view |> has_element?("#students-section")
      assert view |> has_element?("a", student.name)
    end

    test "sections are expanded by default", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      cycle_id = user.current_profile.current_school_cycle.id

      class = SchoolsFixtures.class_fixture(%{school_id: school_id, cycle_id: cycle_id})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{class.id}/people")

      # Check that content divs are visible (not hidden)
      assert view |> has_element?("#staff-section-content:not(.hidden)")
      assert view |> has_element?("#students-section-content:not(.hidden)")
    end
  end

  describe "Class management permissions" do
    test "allow user with school management permissions to edit class", context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)
      school_id = user.current_profile.school_id
      class = SchoolsFixtures.class_fixture(%{school_id: school_id, name: "class abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{class.id}/people?edit=true")

      assert view |> has_element?("#class-form-overlay h2", "Edit class")
    end

    test "prevent user without school management permissions to edit staff member", %{
      conn: conn,
      user: user
    } do
      school_id = user.current_profile.school_id
      class = SchoolsFixtures.class_fixture(%{school_id: school_id, name: "class abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{class.id}/people?edit=true")

      refute view |> has_element?("#class-form-overlay h2", "Edit class")
    end
  end
end
