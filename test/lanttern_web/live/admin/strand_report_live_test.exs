defmodule LantternWeb.Admin.StrandReportLiveTest do
  use LantternWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lanttern.ReportingFixtures

  @invalid_attrs %{report_card_id: nil}

  defp create_strand_report(_) do
    strand_report = strand_report_fixture()
    %{strand_report: strand_report}
  end

  setup :register_and_log_in_root_admin

  describe "Index" do
    setup [:create_strand_report]

    test "lists all strand_reports", %{conn: conn, strand_report: strand_report} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/strand_reports")

      assert html =~ "Listing Strand reports"
      assert html =~ strand_report.description
    end

    test "saves new strand_report", %{conn: conn} do
      report_card = report_card_fixture()
      strand = Lanttern.LearningContextFixtures.strand_fixture()

      create_attrs = %{
        report_card_id: report_card.id,
        strand_id: strand.id,
        description: "some description",
        position: 1
      }

      {:ok, index_live, _html} = live(conn, ~p"/admin/strand_reports")

      assert index_live |> element("a", "New Strand report") |> render_click() =~
               "New Strand report"

      assert_patch(index_live, ~p"/admin/strand_reports/new")

      assert index_live
             |> form("#strand-report-form", strand_report: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#strand-report-form", strand_report: create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/strand_reports")

      html = render(index_live)
      assert html =~ "Strand report created successfully"
      assert html =~ "some description"
    end

    test "updates strand_report in listing", %{conn: conn, strand_report: strand_report} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/strand_reports")

      assert index_live
             |> element("#strand_reports-#{strand_report.id} a", "Edit")
             |> render_click() =~
               "Edit Strand report"

      assert_patch(index_live, ~p"/admin/strand_reports/#{strand_report}/edit")

      assert index_live
             |> form("#strand-report-form", strand_report: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      update_attrs = %{
        report_card_id: strand_report.report_card_id,
        strand_id: strand_report.strand_id,
        description: "some updated description"
      }

      assert index_live
             |> form("#strand-report-form", strand_report: update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/strand_reports")

      html = render(index_live)
      assert html =~ "Strand report updated successfully"
      assert html =~ "some updated description"
    end

    test "deletes strand_report in listing", %{conn: conn, strand_report: strand_report} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/strand_reports")

      assert index_live
             |> element("#strand_reports-#{strand_report.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#strand_reports-#{strand_report.id}")
    end
  end

  describe "Show" do
    setup [:create_strand_report]

    test "displays strand_report", %{conn: conn, strand_report: strand_report} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/strand_reports/#{strand_report}")

      assert html =~ "Show Strand report"
      assert html =~ strand_report.description
    end

    test "updates strand_report within modal", %{conn: conn, strand_report: strand_report} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/strand_reports/#{strand_report}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Strand report"

      assert_patch(show_live, ~p"/admin/strand_reports/#{strand_report}/show/edit")

      assert show_live
             |> form("#strand-report-form", strand_report: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      update_attrs = %{
        report_card_id: strand_report.report_card_id,
        strand_id: strand_report.strand_id,
        description: "some updated description"
      }

      assert show_live
             |> form("#strand-report-form", strand_report: update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/strand_reports/#{strand_report}")

      html = render(show_live)
      assert html =~ "Strand report updated successfully"
      assert html =~ "some updated description"
    end
  end
end
