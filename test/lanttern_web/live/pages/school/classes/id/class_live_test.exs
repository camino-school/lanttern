defmodule LantternWeb.ClassLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  alias Lanttern.Repo
  alias Lanttern.Schools
  alias Lanttern.Schools.School

  @live_view_base_path "/school/classes"

  setup [:register_and_log_in_staff_member]

  describe "Class live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn, user: user} do
      school = Repo.get!(School, user.current_profile.school_id)
      cycle = user.current_profile.current_school_cycle

      class = insert(:class, school: school, cycle: cycle, name: "some class abc xyz")

      conn = get(conn, "#{@live_view_base_path}/#{class.id}/people")

      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*some class abc xyz \(.+\)\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "list students", %{conn: conn, user: user} do
      school = Repo.get!(School, user.current_profile.school_id)
      cycle = user.current_profile.current_school_cycle

      class = insert(:class, school: school, cycle: cycle)

      student_a = insert(:student, school_id: school.id, name: "student a")
      student_a = Repo.preload(student_a, :classes)
      {:ok, student_a} = Schools.update_student(student_a, %{classes_ids: [class.id]})

      student_b = insert(:student, school_id: school.id, name: "student b")
      student_b = Repo.preload(student_b, :classes)
      {:ok, student_b} = Schools.update_student(student_b, %{classes_ids: [class.id]})

      conn
      |> visit("#{@live_view_base_path}/#{class.id}/people")
      |> assert_has("a", text: student_a.name)
      |> assert_has("a", text: student_b.name)
      |> click_link(student_a.name)
      |> assert_path(~p"/school/students/#{student_a}")
    end

    test "displays both staff and students sections in people tab", %{conn: conn, user: user} do
      school = Repo.get!(School, user.current_profile.school_id)
      cycle = user.current_profile.current_school_cycle

      class = insert(:class, school: school, cycle: cycle)

      student = insert(:student, school_id: school.id)
      student = Repo.preload(student, :classes)
      {:ok, student} = Schools.update_student(student, %{classes_ids: [class.id]})

      conn
      |> visit("#{@live_view_base_path}/#{class.id}/people")
      |> assert_has("#staff-section")
      |> assert_has("#students-section")
      |> assert_has("a", text: student.name)
    end

    test "sections are expanded by default", %{conn: conn, user: user} do
      school = Repo.get!(School, user.current_profile.school_id)
      cycle = user.current_profile.current_school_cycle

      class = insert(:class, school: school, cycle: cycle)

      conn
      |> visit("#{@live_view_base_path}/#{class.id}/people")
      |> assert_has("#staff-section-content:not(.hidden)")
      |> assert_has("#students-section-content:not(.hidden)")
    end
  end

  describe "Class management permissions" do
    test "allow user with school management permissions to edit class", context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)
      school = Repo.get!(School, user.current_profile.school_id)

      class = insert(:class, school: school, name: "class abc")

      conn
      |> visit("#{@live_view_base_path}/#{class.id}/people?edit=true")
      |> assert_has("#class-form-overlay h2", text: "Edit class")
    end

    test "prevent user without school management permissions to edit staff member", %{
      conn: conn,
      user: user
    } do
      school = Repo.get!(School, user.current_profile.school_id)

      class = insert(:class, school: school, name: "class abc")

      conn
      |> visit("#{@live_view_base_path}/#{class.id}/people?edit=true")
      |> refute_has("#class-form-overlay h2", text: "Edit class")
    end
  end
end
