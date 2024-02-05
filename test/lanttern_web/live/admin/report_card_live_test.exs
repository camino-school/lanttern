defmodule LantternWeb.Admin.ReportCardLiveTest do
  use LantternWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lanttern.ReportingFixtures

  @update_attrs %{name: "some updated name", description: "some updated description"}
  @invalid_attrs %{name: nil, description: nil}

  defp create_report_card(_) do
    report_card = report_card_fixture()
    %{report_card: report_card}
  end

  setup :register_and_log_in_root_admin

  describe "Index" do
    setup [:create_report_card]

    test "lists all report_cards", %{conn: conn, report_card: report_card} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/report_cards")

      assert html =~ "Listing Report cards"
      assert html =~ report_card.name
    end

    test "saves new report_card", %{conn: conn} do
      school_cycle = Lanttern.SchoolsFixtures.cycle_fixture()

      {:ok, index_live, _html} = live(conn, ~p"/admin/report_cards")

      assert index_live |> element("a", "New Report card") |> render_click() =~
               "New Report card"

      assert_patch(index_live, ~p"/admin/report_cards/new")

      create_attrs = %{
        name: "some name",
        description: "some description",
        school_cycle_id: school_cycle.id
      }

      assert index_live
             |> form("#report_card-form", report_card: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#report_card-form", report_card: create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/report_cards")

      html = render(index_live)
      assert html =~ "Report card created successfully"
      assert html =~ "some name"
    end

    test "updates report_card in listing", %{conn: conn, report_card: report_card} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/report_cards")

      assert index_live |> element("#report_cards-#{report_card.id} a", "Edit") |> render_click() =~
               "Edit Report card"

      assert_patch(index_live, ~p"/admin/report_cards/#{report_card}/edit")

      assert index_live
             |> form("#report_card-form", report_card: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#report_card-form", report_card: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/report_cards")

      html = render(index_live)
      assert html =~ "Report card updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes report_card in listing", %{conn: conn, report_card: report_card} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/report_cards")

      assert index_live
             |> element("#report_cards-#{report_card.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#report_cards-#{report_card.id}")
    end
  end

  describe "Show" do
    setup [:create_report_card]

    test "displays report_card", %{conn: conn, report_card: report_card} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/report_cards/#{report_card}")

      assert html =~ "Show Report card"
      assert html =~ report_card.name
    end

    test "updates report_card within modal", %{conn: conn, report_card: report_card} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/report_cards/#{report_card}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Report card"

      assert_patch(show_live, ~p"/admin/report_cards/#{report_card}/show/edit")

      assert show_live
             |> form("#report_card-form", report_card: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#report_card-form", report_card: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/report_cards/#{report_card}")

      html = render(show_live)
      assert html =~ "Report card updated successfully"
      assert html =~ "some updated name"
    end
  end
end
