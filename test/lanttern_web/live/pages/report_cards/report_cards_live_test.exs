defmodule LantternWeb.ReportCardsLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.ReportingFixtures
  alias Lanttern.SchoolsFixtures

  @live_view_path "/report_cards"

  setup [:register_and_log_in_staff_member]

  describe "Report cards live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)

      assert html_response(conn, 200) =~ ~r"<h1 .+>\s*Report cards\s*<\/h1>"

      {:ok, _view, _html} = live(conn)
    end

    test "list report cards and navigate to detail", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      cycle_2020_id = user.current_profile.current_school_cycle.id

      cycle_2020_2 =
        SchoolsFixtures.cycle_fixture(%{
          school_id: school_id,
          start_at: ~D[2020-07-01],
          end_at: ~D[2020-12-31],
          name: "Cycle 2020 2",
          parent_cycle_id: cycle_2020_id
        })

      cycle_2020_1 =
        SchoolsFixtures.cycle_fixture(%{
          school_id: school_id,
          start_at: ~D[2020-01-01],
          end_at: ~D[2020-06-30],
          name: "Cycle 2020 1",
          parent_cycle_id: cycle_2020_id
        })

      report_card_2020_2 =
        report_card_fixture(%{school_cycle_id: cycle_2020_2.id, name: "Report Card blah 2020 2"})

      report_card_2020_1 =
        report_card_fixture(%{school_cycle_id: cycle_2020_1.id, name: "Report Card blah 2020 1"})

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("h6", cycle_2020_2.name)
      assert view |> has_element?("a", report_card_2020_2.name)
      assert view |> has_element?("h6", cycle_2020_1.name)
      assert view |> has_element?("a", report_card_2020_1.name)

      view
      |> element("a", report_card_2020_2.name)
      |> render_click()

      assert_redirect(view, "#{@live_view_path}/#{report_card_2020_2.id}")
    end
  end
end
