defmodule LantternWeb.SchoolConfigLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.SchoolsFixtures

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
  end

  describe "Management permissions" do
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
end
