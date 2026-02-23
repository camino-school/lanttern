defmodule LantternWeb.SchoolAiConfigLiveTest do
  use LantternWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lanttern.Factory
  import PhoenixTest

  @live_view_path "/settings/school_ai_config"

  setup [:register_and_log_in_staff_member]

  describe "SchoolAiConfigLive :index" do
    test "redirects to dashboard without agents_management permission", %{conn: conn} do
      conn
      |> visit(@live_view_path)
      |> assert_path("/dashboard")
    end

    test "renders page with agents_management permission", context do
      %{conn: conn} = set_user_permissions(["agents_management"], context)

      conn
      |> visit(@live_view_path)
      |> assert_has("p", text: "Configure school-wide AI settings")
    end

    test "shows empty state when no config exists", context do
      %{conn: conn} = set_user_permissions(["agents_management"], context)

      conn
      |> visit(@live_view_path)
      |> assert_has("h6", text: "Default LLM")
      |> assert_has("h6", text: "School knowledge")
      |> assert_has("h6", text: "School guardrails")
      |> assert_has("button", text: "Add")
    end

    test "shows existing values when config exists", context do
      %{conn: conn, user: user} = set_user_permissions(["agents_management"], context)
      school = Lanttern.Schools.get_school!(user.current_profile.school_id)

      insert(:ai_config,
        school: school,
        base_model: "gpt-5-turbo",
        knowledge: "Our school philosophy is student-centered.",
        guardrails: "Always be supportive."
      )

      conn
      |> visit(@live_view_path)
      |> assert_has("div", text: "gpt-5-turbo")
      |> assert_has("*", text: "Our school philosophy is student-centered.")
      |> assert_has("*", text: "Always be supportive.")
    end
  end

  describe "SchoolAiConfigLive editing workflow" do
    test "can edit and save base_model field", context do
      %{conn: conn, user: user} = set_user_permissions(["agents_management"], context)
      school = Lanttern.Schools.get_school!(user.current_profile.school_id)

      insert(:ai_config, school: school, base_model: "old-model-name")

      {:ok, view, _html} = live(conn, @live_view_path)

      # Click edit button to enter edit mode
      view |> element("button[phx-click=\"edit_base_model\"]") |> render_click()

      # Submit form with new value
      view
      |> form("form[phx-submit=\"save_base_model\"]", ai_config: %{base_model: "new-model-name"})
      |> render_submit()

      # Verify the updated value is displayed
      html = render(view)
      assert html =~ "new-model-name"
      refute html =~ "old-model-name"
    end

    test "can edit and save knowledge field", context do
      %{conn: conn, user: user} = set_user_permissions(["agents_management"], context)
      school = Lanttern.Schools.get_school!(user.current_profile.school_id)

      insert(:ai_config, school: school, knowledge: "Initial knowledge")

      {:ok, view, _html} = live(conn, @live_view_path)

      # Click edit button to enter edit mode
      view |> element("button[phx-click=\"edit_knowledge\"]") |> render_click()

      # Submit form with new value
      view
      |> form("form[phx-submit=\"save_knowledge\"]",
        ai_config: %{knowledge: "Updated school knowledge"}
      )
      |> render_submit()

      # Verify the updated value is displayed
      html = render(view)
      assert html =~ "Updated school knowledge"
      refute html =~ "Initial knowledge"
    end

    test "can edit and save guardrails field", context do
      %{conn: conn, user: user} = set_user_permissions(["agents_management"], context)
      school = Lanttern.Schools.get_school!(user.current_profile.school_id)

      insert(:ai_config, school: school, guardrails: "Initial guardrails")

      {:ok, view, _html} = live(conn, @live_view_path)

      # Click edit button to enter edit mode
      view |> element("button[phx-click=\"edit_guardrails\"]") |> render_click()

      # Submit form with new value
      view
      |> form("form[phx-submit=\"save_guardrails\"]",
        ai_config: %{guardrails: "Updated guardrails"}
      )
      |> render_submit()

      # Verify the updated value is displayed
      html = render(view)
      assert html =~ "Updated guardrails"
      refute html =~ "Initial guardrails"
    end

    test "can cancel edit without saving", context do
      %{conn: conn, user: user} = set_user_permissions(["agents_management"], context)
      school = Lanttern.Schools.get_school!(user.current_profile.school_id)

      insert(:ai_config, school: school, base_model: "gpt-5-mini")

      {:ok, view, _html} = live(conn, @live_view_path)

      # Click edit button to enter edit mode
      view |> element("button[phx-click=\"edit_base_model\"]") |> render_click()

      # Click cancel button
      view |> element("button[phx-click=\"cancel_edit_base_model\"]") |> render_click()

      # Verify the original value is still displayed (not in edit mode)
      assert has_element?(view, "button[phx-click=\"edit_base_model\"]", "gpt-5-mini")
    end

    test "can add new ai_config from empty state", context do
      %{conn: conn} = set_user_permissions(["agents_management"], context)

      {:ok, view, _html} = live(conn, @live_view_path)

      # Click the Add button to enter edit mode for base_model
      view |> element("button[phx-click=\"edit_base_model\"]", "Add") |> render_click()

      # Submit form with new value
      view
      |> form("form[phx-submit=\"save_base_model\"]", ai_config: %{base_model: "gpt-5-mini"})
      |> render_submit()

      # Verify the value is displayed
      assert has_element?(view, "div", "gpt-5-mini")
    end
  end
end
