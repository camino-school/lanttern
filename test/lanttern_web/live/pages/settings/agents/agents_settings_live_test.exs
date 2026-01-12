defmodule LantternWeb.AgentsSettingsLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  alias Lanttern.Repo

  @live_view_path "/settings/agents"

  setup [:register_and_log_in_staff_member]

  describe "Agents settings live view" do
    test "agents are listed", context do
      %{conn: conn, user: user} = set_user_permissions(["agents_management"], context)
      school = Lanttern.Schools.get_school!(user.current_profile.school_id)

      insert(:agent, %{school: school, name: "Agent Alpha"})
      insert(:agent, %{school: school, name: "Agent Beta"})

      conn
      |> visit(@live_view_path)
      |> assert_has("#agents-list", text: "Agent Alpha")
      |> assert_has("#agents-list", text: "Agent Beta")
    end

    test "agent detail is displayed correctly", context do
      %{conn: conn, user: user} = set_user_permissions(["agents_management"], context)
      school = Lanttern.Schools.get_school!(user.current_profile.school_id)

      agent =
        insert(:agent,
          school: school,
          name: "Agent Detail",
          personality: "Curious tone",
          knowledge: "Math topics",
          instructions: "Guide students",
          guardrails: "Stay safe"
        )

      insert(:agent, %{school: school, name: "Other Agent", personality: "Different tone"})

      conn
      |> visit("#{@live_view_path}/#{agent.id}")
      |> assert_has("#agents-list", text: "Agent Detail")
      |> assert_has("#agents-list", text: "Personality")
      |> assert_has("#agents-list", text: "Curious tone")
      |> assert_has("#agents-list", text: "Knowledge")
      |> assert_has("#agents-list", text: "Math topics")
      |> assert_has("#agents-list", text: "Instructions")
      |> assert_has("#agents-list", text: "Guide students")
      |> assert_has("#agents-list", text: "Guardrails")
      |> assert_has("#agents-list", text: "Stay safe")
      |> refute_has("#agents-list", text: "Different tone")
    end

    test "create agent", context do
      %{conn: conn} = set_user_permissions(["agents_management"], context)

      session =
        conn
        |> visit(@live_view_path)
        |> click_button("New agent")
        |> within("#agent-form-overlay", fn conn ->
          conn
          |> fill_in("Agent name", with: "New agent name")
          |> click_button("Save")
        end)

      # get created agent id
      agent = Repo.get_by(Lanttern.Agents.Agent, name: "New agent name")

      session
      |> assert_path("#{@live_view_path}/#{agent.id}")
      |> assert_has("#agents-list", text: "New agent name")
      |> assert_has("#agents-list", text: "Edit")
      |> assert_has("#agents-list", text: "Add personality")
    end

    test "edit agent", context do
      %{conn: conn, user: user} = set_user_permissions(["agents_management"], context)
      school = Lanttern.Schools.get_school!(user.current_profile.school_id)
      agent = insert(:agent, %{school: school, name: "Old name"})

      conn
      |> visit("#{@live_view_path}/#{agent.id}")
      |> click_button("#agents-list button[phx-click=\"edit_agent\"]", "Edit")
      |> within("#agent-form-overlay", fn conn ->
        conn
        |> fill_in("Agent name", with: "Updated agent name")
        |> click_button("Save")
      end)
      |> assert_has("#agents-list", text: "Updated agent name")
      |> assert_has("#agents-list", text: "Edit")
    end

    test "delete agent", context do
      %{conn: conn, user: user} = set_user_permissions(["agents_management"], context)
      school = Lanttern.Schools.get_school!(user.current_profile.school_id)
      agent = insert(:agent, %{school: school, name: "Agent to delete"})

      conn
      |> visit("#{@live_view_path}/#{agent.id}")
      |> click_button("#agents-list button[phx-click=\"edit_agent\"]", "Edit")
      |> click_button("#agent-form-overlay button", "Delete")
      |> refute_has("#agents-list", text: "Agent to delete")
    end
  end
end
