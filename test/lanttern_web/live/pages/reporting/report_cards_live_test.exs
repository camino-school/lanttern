defmodule LantternWeb.ReportCardsLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.ReportingFixtures
  alias Lanttern.SchoolsFixtures

  @live_view_path "/reporting"

  setup [:register_and_log_in_user]

  describe "Report cards live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)

      assert html_response(conn, 200) =~ ~r"<h1 .+>\s*Report Cards\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "list report cards and navigate to detail", %{conn: conn} do
      cycle_2024 =
        SchoolsFixtures.cycle_fixture(%{
          start_at: ~D[2024-01-01],
          end_at: ~D[2024-12-31],
          name: "Cycle 2024"
        })

      cycle_2023 =
        SchoolsFixtures.cycle_fixture(%{
          start_at: ~D[2023-01-01],
          end_at: ~D[2023-12-31],
          name: "Cycle 2023"
        })

      report_card_2024 =
        report_card_fixture(%{school_cycle_id: cycle_2024.id, name: "Report Card blah 2024"})

      report_card_2023 =
        report_card_fixture(%{school_cycle_id: cycle_2023.id, name: "Report Card blah 2023"})

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("h6", cycle_2024.name)
      assert view |> has_element?("a", report_card_2024.name)
      assert view |> has_element?("h6", cycle_2023.name)
      assert view |> has_element?("a", report_card_2023.name)

      view
      |> element("a", report_card_2024.name)
      |> render_click()

      assert_redirect(view, "#{@live_view_path}/#{report_card_2024.id}")
    end
  end
end
