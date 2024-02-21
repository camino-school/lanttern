defmodule LantternWeb.Admin.StudentReportCardLiveTest do
  use LantternWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lanttern.ReportingFixtures

  @invalid_attrs %{report_card_id: nil, student_id: nil, comment: nil, footnote: nil}

  setup :register_and_log_in_root_admin

  defp create_student_report_card(_) do
    student_report_card = student_report_card_fixture()
    %{student_report_card: student_report_card}
  end

  describe "Index" do
    setup [:create_student_report_card]

    test "lists all student_report_cards", %{conn: conn, student_report_card: student_report_card} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/student_report_cards")

      assert html =~ "Listing Student report cards"
      assert html =~ student_report_card.comment
    end

    test "saves new student_report_card", %{conn: conn} do
      report_card = report_card_fixture()
      student = Lanttern.SchoolsFixtures.student_fixture()

      create_attrs = %{
        report_card_id: report_card.id,
        student_id: student.id,
        comment: "some comment",
        footnote: "some footnote"
      }

      {:ok, index_live, _html} = live(conn, ~p"/admin/student_report_cards")

      assert index_live |> element("a", "New Student report card") |> render_click() =~
               "New Student report card"

      assert_patch(index_live, ~p"/admin/student_report_cards/new")

      assert index_live
             |> form("#student-report-card-form", student_report_card: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#student-report-card-form", student_report_card: create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/student_report_cards")

      html = render(index_live)
      assert html =~ "Student report card created successfully"
      assert html =~ "some comment"
    end

    test "updates student_report_card in listing", %{
      conn: conn,
      student_report_card: student_report_card
    } do
      {:ok, index_live, _html} = live(conn, ~p"/admin/student_report_cards")

      assert index_live
             |> element("#student_report_cards-#{student_report_card.id} a", "Edit")
             |> render_click() =~
               "Edit Student report card"

      assert_patch(index_live, ~p"/admin/student_report_cards/#{student_report_card}/edit")

      assert index_live
             |> form("#student-report-card-form", student_report_card: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      update_attrs = %{
        report_card_id: student_report_card.report_card_id,
        student_id: student_report_card.student_id,
        comment: "some updated comment",
        footnote: "some updated footnote"
      }

      assert index_live
             |> form("#student-report-card-form", student_report_card: update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/student_report_cards")

      html = render(index_live)
      assert html =~ "Student report card updated successfully"
      assert html =~ "some updated comment"
    end

    test "deletes student_report_card in listing", %{
      conn: conn,
      student_report_card: student_report_card
    } do
      {:ok, index_live, _html} = live(conn, ~p"/admin/student_report_cards")

      assert index_live
             |> element("#student_report_cards-#{student_report_card.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#student_report_cards-#{student_report_card.id}")
    end
  end

  describe "Show" do
    setup [:create_student_report_card]

    test "displays student_report_card", %{conn: conn, student_report_card: student_report_card} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/student_report_cards/#{student_report_card}")

      assert html =~ "Show Student report card"
      assert html =~ student_report_card.comment
    end

    test "updates student_report_card within modal", %{
      conn: conn,
      student_report_card: student_report_card
    } do
      {:ok, show_live, _html} = live(conn, ~p"/admin/student_report_cards/#{student_report_card}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Student report card"

      assert_patch(show_live, ~p"/admin/student_report_cards/#{student_report_card}/show/edit")

      assert show_live
             |> form("#student-report-card-form", student_report_card: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      update_attrs = %{
        report_card_id: student_report_card.report_card_id,
        student_id: student_report_card.student_id,
        comment: "some updated comment",
        footnote: "some updated footnote"
      }

      assert show_live
             |> form("#student-report-card-form", student_report_card: update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/student_report_cards/#{student_report_card}")

      html = render(show_live)
      assert html =~ "Student report card updated successfully"
      assert html =~ "some updated comment"
    end
  end
end
