defmodule LantternWeb.SchoolLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.SchoolsFixtures

  @live_view_path "/school"

  setup [:register_and_log_in_teacher]

  describe "School live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)

      school_name = conn.assigns.current_user.current_profile.school_name
      {:ok, regex} = Regex.compile("<h1 .+>\\s*#{school_name}\\s*<\/h1>")

      assert html_response(conn, 200) =~ regex

      {:ok, _view, _html} = live(conn)
    end

    test "list students", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      student = SchoolsFixtures.student_fixture(%{school_id: school_id, name: "student abc"})
      other_student = SchoolsFixtures.student_fixture(%{name: "student from other school"})

      {:ok, view, _html} = live(conn, "#{@live_view_path}/students")

      assert view |> has_element?("div", student.name)
      refute view |> has_element?("div", other_student.name)
    end

    test "list classes", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      class = SchoolsFixtures.class_fixture(%{school_id: school_id, name: "class abc"})
      other_class = SchoolsFixtures.class_fixture(%{name: "class from other school"})

      {:ok, view, _html} = live(conn, "#{@live_view_path}/classes")

      assert view |> has_element?("p", class.name)
      refute view |> has_element?("p", other_class.name)
    end
  end

  describe "Students management permissions" do
    test "allow user with school management permissions to create student", context do
      %{conn: conn} = add_school_management_permissions(context)
      {:ok, view, _html} = live(conn, "#{@live_view_path}/students?new=true")

      assert view |> has_element?("#student-form-overlay h2", "New student")
    end

    test "prevent user without school management permissions to create student", %{conn: conn} do
      {:ok, view, _html} = live(conn, "#{@live_view_path}/students?new=true")

      refute view |> has_element?("#student-form-overlay h2", "New student")
    end
  end

  describe "Classes management permissions" do
    test "allow user with school management permissions to create class", context do
      %{conn: conn} = add_school_management_permissions(context)
      {:ok, view, _html} = live(conn, "#{@live_view_path}/classes?new=true")

      assert view |> has_element?("#class-form-overlay h2", "Create class")
    end

    test "prevent user without school management permissions to create class", %{conn: conn} do
      {:ok, view, _html} = live(conn, "#{@live_view_path}/classes?new=true")

      refute view |> has_element?("#class-form-overlay h2", "Create class")
    end

    test "allow user with school management permissions to edit class", context do
      %{conn: conn, user: user} = add_school_management_permissions(context)
      school_id = user.current_profile.school_id
      class = SchoolsFixtures.class_fixture(%{school_id: school_id, name: "school abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_path}/classes?edit=#{class.id}")

      assert view |> has_element?("#class-form-overlay h2", "Edit class")
    end

    test "prevent user without school management permissions to edit class", %{
      conn: conn,
      user: user
    } do
      school_id = user.current_profile.school_id
      class = SchoolsFixtures.class_fixture(%{school_id: school_id, name: "school abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_path}/classes?edit=#{class.id}")

      refute view |> has_element?("#class-form-overlay h2", "Edit class")
    end
  end
end
