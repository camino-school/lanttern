defmodule LantternWeb.Admin.StudentRecordStatusLiveTest do
  use LantternWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lanttern.StudentsRecordsFixtures

  alias Lanttern.SchoolsFixtures

  @update_attrs %{
    name: "some updated name",
    bg_color: "#000000",
    text_color: "#ffffff"
  }
  @invalid_attrs %{name: nil, bg_color: nil, text_color: nil}

  setup :register_and_log_in_root_admin

  defp create_student_record_status(_) do
    student_record_status = student_record_status_fixture()
    %{student_record_status: student_record_status}
  end

  describe "Index" do
    setup [:create_student_record_status]

    test "lists all student_record_statuses", %{
      conn: conn,
      student_record_status: student_record_status
    } do
      {:ok, _index_live, html} = live(conn, ~p"/admin/student_record_statuses")

      assert html =~ "Listing Student record statuses"
      assert html =~ student_record_status.name
    end

    test "saves new student_record_status", %{conn: conn} do
      school = SchoolsFixtures.school_fixture()
      {:ok, index_live, _html} = live(conn, ~p"/admin/student_record_statuses")

      assert index_live |> element("a", "New Student record status") |> render_click() =~
               "New Student record status"

      assert_patch(index_live, ~p"/admin/student_record_statuses/new")

      assert index_live
             |> form("#student_record_status-form", student_record_status: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      create_attrs = %{
        school_id: school.id,
        name: "some name",
        bg_color: "#000000",
        text_color: "#ffffff"
      }

      assert index_live
             |> form("#student_record_status-form", student_record_status: create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/student_record_statuses")

      html = render(index_live)
      assert html =~ "Student record status created successfully"
      assert html =~ "some name"
    end

    test "updates student_record_status in listing", %{
      conn: conn,
      student_record_status: student_record_status
    } do
      {:ok, index_live, _html} = live(conn, ~p"/admin/student_record_statuses")

      assert index_live
             |> element("#student_record_statuses-#{student_record_status.id} a", "Edit")
             |> render_click() =~
               "Edit Student record status"

      assert_patch(index_live, ~p"/admin/student_record_statuses/#{student_record_status}/edit")

      assert index_live
             |> form("#student_record_status-form", student_record_status: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#student_record_status-form", student_record_status: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/student_record_statuses")

      html = render(index_live)
      assert html =~ "Student record status updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes student_record_status in listing", %{
      conn: conn,
      student_record_status: student_record_status
    } do
      {:ok, index_live, _html} = live(conn, ~p"/admin/student_record_statuses")

      assert index_live
             |> element("#student_record_statuses-#{student_record_status.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#student_record_statuses-#{student_record_status.id}")
    end
  end

  describe "Show" do
    setup [:create_student_record_status]

    test "displays student_record_status", %{
      conn: conn,
      student_record_status: student_record_status
    } do
      {:ok, _show_live, html} =
        live(conn, ~p"/admin/student_record_statuses/#{student_record_status}")

      assert html =~ "Show Student record status"
      assert html =~ student_record_status.name
    end

    test "updates student_record_status within modal", %{
      conn: conn,
      student_record_status: student_record_status
    } do
      {:ok, show_live, _html} =
        live(conn, ~p"/admin/student_record_statuses/#{student_record_status}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Student record status"

      assert_patch(
        show_live,
        ~p"/admin/student_record_statuses/#{student_record_status}/show/edit"
      )

      assert show_live
             |> form("#student_record_status-form", student_record_status: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#student_record_status-form", student_record_status: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/student_record_statuses/#{student_record_status}")

      html = render(show_live)
      assert html =~ "Student record status updated successfully"
      assert html =~ "some updated name"
    end
  end
end
