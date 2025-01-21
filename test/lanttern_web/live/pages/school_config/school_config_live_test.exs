defmodule LantternWeb.SchoolConfigLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.SchoolsFixtures
  alias Lanttern.SchoolConfigFixtures

  @live_view_base_path "/school_config"

  setup [:register_and_log_in_teacher]

  describe "School config live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, "#{@live_view_base_path}/cycles")

      school_name = conn.assigns.current_user.current_profile.school_name
      {:ok, regex} = Regex.compile("<h1 .+>\\s*#{school_name} config\\s*<\/h1>")

      assert html_response(conn, 200) =~ regex

      {:ok, _view, _html} = live(conn)
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
