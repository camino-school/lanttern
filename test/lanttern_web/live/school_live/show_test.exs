defmodule LantternWeb.SchoolLive.ShowTest do
  use LantternWeb.ConnCase

  alias Lanttern.SchoolsFixtures

  @live_view_path "/school"

  setup [:register_and_log_in_user]

  describe "School live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)

      school = conn.assigns.current_user.current_profile.teacher.school
      {:ok, regex} = Regex.compile("<h1 .+>\\s*#{school.name}\\s*<\/h1>")

      assert html_response(conn, 200) =~ regex

      {:ok, _view, _html} = live(conn)
    end

    test "list classes", %{conn: conn, user: user} do
      school = user.current_profile.teacher.school
      class = SchoolsFixtures.class_fixture(%{school_id: school.id, name: "school abc"})

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("td", class.name)
    end
  end
end
