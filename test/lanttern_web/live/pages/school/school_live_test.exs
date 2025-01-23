defmodule LantternWeb.SchoolLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.SchoolsFixtures
  alias Lanttern.SchoolConfigFixtures

  @live_view_base_path "/school"

  setup [:register_and_log_in_staff_member]

  describe "School live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, "#{@live_view_base_path}/classes")

      school_name = conn.assigns.current_user.current_profile.school_name
      {:ok, regex} = Regex.compile("<h1 .+>\\s*#{school_name}\\s*<\/h1>")

      assert html_response(conn, 200) =~ regex

      {:ok, _view, _html} = live(conn)
    end

    test "list students", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      student = SchoolsFixtures.student_fixture(%{school_id: school_id, name: "student abc"})
      other_student = SchoolsFixtures.student_fixture(%{name: "student from other school"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/students")

      assert view |> has_element?("div", student.name)
      refute view |> has_element?("div", other_student.name)
    end

    test "list classes", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      cycle_id = user.current_profile.current_school_cycle.id

      class =
        SchoolsFixtures.class_fixture(%{
          school_id: school_id,
          cycle_id: cycle_id,
          name: "class abc"
        })

      other_class = SchoolsFixtures.class_fixture(%{name: "class from other school"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/classes")

      assert view |> has_element?("p", class.name)
      refute view |> has_element?("p", other_class.name)
    end
  end

  describe "Students management permissions" do
    test "allow user with school management permissions to create student", context do
      %{conn: conn} = add_school_management_permissions(context)
      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/students?new=true")

      assert view |> has_element?("#student-form-overlay h2", "New student")
    end

    test "prevent user without school management permissions to create student", %{conn: conn} do
      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/students?new=true")

      refute view |> has_element?("#student-form-overlay h2", "New student")
    end
  end

  describe "Classes management permissions" do
    test "allow user with school management permissions to create class", context do
      %{conn: conn} = add_school_management_permissions(context)
      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/classes?new=true")

      assert view |> has_element?("#class-form-overlay h2", "Create class")
    end

    test "prevent user without school management permissions to create class", %{conn: conn} do
      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/classes?new=true")

      refute view |> has_element?("#class-form-overlay h2", "Create class")
    end

    test "allow user with school management permissions to edit class", context do
      %{conn: conn, user: user} = add_school_management_permissions(context)
      school_id = user.current_profile.school_id
      class = SchoolsFixtures.class_fixture(%{school_id: school_id, name: "school abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/classes?edit=#{class.id}")

      assert view |> has_element?("#class-form-overlay h2", "Edit class")
    end

    test "prevent user without school management permissions to edit class", %{
      conn: conn,
      user: user
    } do
      school_id = user.current_profile.school_id
      class = SchoolsFixtures.class_fixture(%{school_id: school_id, name: "school abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/classes?edit=#{class.id}")

      refute view |> has_element?("#class-form-overlay h2", "Edit class")
    end
  end

  describe "Cycle management" do
    test "list cycles", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id

      parent_cycle =
        SchoolsFixtures.cycle_fixture(%{school_id: school_id, name: "parent cycle abc"})

      subcycle =
        SchoolsFixtures.cycle_fixture(%{
          school_id: school_id,
          parent_cycle_id: parent_cycle.id,
          name: "subcycle abc"
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/cycles")

      assert view |> has_element?("div", parent_cycle.name)
      assert view |> has_element?("div", subcycle.name)
    end

    test "allow user with school management permissions to create cycle", context do
      %{conn: conn} = add_school_management_permissions(context)
      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/cycles?new=true")

      assert view |> has_element?("#cycle-form-overlay h2", "Create cycle")
    end

    test "prevent user without school management permissions to create cycle", %{conn: conn} do
      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/cycles?new=true")

      refute view |> has_element?("#cycle-form-overlay h2", "Create cycle")
    end

    test "allow user with school management permissions to edit cycle", context do
      %{conn: conn, user: user} = add_school_management_permissions(context)
      school_id = user.current_profile.school_id
      cycle = SchoolsFixtures.cycle_fixture(%{school_id: school_id, name: "cycle abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/cycles?edit=#{cycle.id}")

      assert view |> has_element?("#cycle-form-overlay h2", "Edit cycle")
    end

    test "prevent user without school management permissions to edit cycle", %{
      conn: conn,
      user: user
    } do
      school_id = user.current_profile.school_id
      cycle = SchoolsFixtures.cycle_fixture(%{school_id: school_id, name: "cycle abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/cycles?edit=#{cycle.id}")

      refute view |> has_element?("#cycle-form-overlay h2", "Edit cycle")
    end
  end

  describe "Template management" do
    test "list templates and basic navigation", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id

      template =
        SchoolConfigFixtures.moment_card_template_fixture(%{
          school_id: school_id,
          name: "template abc"
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/moment_cards_templates")

      assert view |> has_element?("a", "template abc")

      view
      |> element("a", "template abc")
      |> render_click()

      assert_patch(view, "#{@live_view_base_path}/moment_cards_templates?id=#{template.id}")
    end

    test "allow user with content management permissions to create template", context do
      %{conn: conn} = add_content_management_permissions(context)
      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/moment_cards_templates?new=true")

      assert view |> has_element?("#moment-card-template-overlay h5", "New moment card template")
    end

    test "prevent user without content management permissions to create template", %{conn: conn} do
      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/moment_cards_templates?new=true")

      refute view |> has_element?("#moment-card-template-overlay h5", "New moment card template")
    end

    test "allow user with content management permissions to edit template", context do
      %{conn: conn, user: user} = add_content_management_permissions(context)
      school_id = user.current_profile.school_id

      template =
        SchoolConfigFixtures.moment_card_template_fixture(%{
          school_id: school_id,
          name: "template abc"
        })

      {:ok, view, _html} =
        live(conn, "#{@live_view_base_path}/moment_cards_templates?id=#{template.id}")

      assert view |> has_element?("#moment-card-template-overlay button", "Edit template")
    end

    test "prevent user without content management permissions to edit template", %{
      conn: conn,
      user: user
    } do
      school_id = user.current_profile.school_id

      template =
        SchoolConfigFixtures.moment_card_template_fixture(%{
          school_id: school_id,
          name: "template abc"
        })

      {:ok, view, _html} =
        live(conn, "#{@live_view_base_path}/moment_cards_templates?id=#{template.id}")

      refute view |> has_element?("#moment-card-template-overlay button", "Edit template")
    end
  end
end
