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

    test "list classes", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      class = SchoolsFixtures.class_fixture(%{school_id: school_id, name: "school abc"})

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("td", class.name)
    end
  end
end
