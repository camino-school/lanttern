defmodule LantternWeb.DashboardLiveTest do
  use LantternWeb.ConnCase

  @live_view_path "/dashboard"

  setup :register_and_log_in_teacher

  describe "Dashboard live view basic navigation" do
    alias Lanttern.LearningContext
    alias Lanttern.LearningContextFixtures

    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*Dashboard 🚧\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "list starred strands", %{conn: conn, user: user} do
      starred_strand = LearningContextFixtures.strand_fixture(%{name: "Starred ABC"})
      LearningContext.star_strand(starred_strand.id, user.current_profile_id)

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("a", "Starred ABC")
    end
  end
end
