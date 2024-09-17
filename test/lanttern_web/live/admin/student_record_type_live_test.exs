defmodule LantternWeb.StudentRecordTypeLiveTest do
  use LantternWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lanttern.StudentsRecordsFixtures

  alias Lanttern.SchoolsFixtures

  @update_attrs %{
    name: "some updated name",
    bg_color: "#ffffff",
    text_color: "#000000"
  }
  @invalid_attrs %{name: nil, bg_color: nil, text_color: nil}

  setup :register_and_log_in_root_admin

  defp create_student_record_type(_) do
    student_record_type = student_record_type_fixture()
    %{student_record_type: student_record_type}
  end

  describe "Index" do
    setup [:create_student_record_type]

    test "lists all student_record_types", %{conn: conn, student_record_type: student_record_type} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/student_record_types")

      assert html =~ "Listing Student record types"
      assert html =~ student_record_type.name
    end

    test "saves new student_record_type", %{conn: conn} do
      school = SchoolsFixtures.school_fixture()
      {:ok, index_live, _html} = live(conn, ~p"/admin/student_record_types")

      assert index_live |> element("a", "New Student record type") |> render_click() =~
               "New Student record type"

      assert_patch(index_live, ~p"/admin/student_record_types/new")

      assert index_live
             |> form("#student_record_type-form", student_record_type: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      create_attrs = %{
        school_id: school.id,
        name: "some name",
        bg_color: "#000000",
        text_color: "#ffffff"
      }

      assert index_live
             |> form("#student_record_type-form", student_record_type: create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/student_record_types")

      html = render(index_live)
      assert html =~ "Student record type created successfully"
      assert html =~ "some name"
    end

    test "updates student_record_type in listing", %{
      conn: conn,
      student_record_type: student_record_type
    } do
      {:ok, index_live, _html} = live(conn, ~p"/admin/student_record_types")

      assert index_live
             |> element("#student_record_types-#{student_record_type.id} a", "Edit")
             |> render_click() =~
               "Edit Student record type"

      assert_patch(index_live, ~p"/admin/student_record_types/#{student_record_type}/edit")

      assert index_live
             |> form("#student_record_type-form", student_record_type: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#student_record_type-form", student_record_type: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/student_record_types")

      html = render(index_live)
      assert html =~ "Student record type updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes student_record_type in listing", %{
      conn: conn,
      student_record_type: student_record_type
    } do
      {:ok, index_live, _html} = live(conn, ~p"/admin/student_record_types")

      assert index_live
             |> element("#student_record_types-#{student_record_type.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#student_record_types-#{student_record_type.id}")
    end
  end

  describe "Show" do
    setup [:create_student_record_type]

    test "displays student_record_type", %{conn: conn, student_record_type: student_record_type} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/student_record_types/#{student_record_type}")

      assert html =~ "Show Student record type"
      assert html =~ student_record_type.name
    end

    test "updates student_record_type within modal", %{
      conn: conn,
      student_record_type: student_record_type
    } do
      {:ok, show_live, _html} = live(conn, ~p"/admin/student_record_types/#{student_record_type}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Student record type"

      assert_patch(show_live, ~p"/admin/student_record_types/#{student_record_type}/show/edit")

      assert show_live
             |> form("#student_record_type-form", student_record_type: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#student_record_type-form", student_record_type: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/student_record_types/#{student_record_type}")

      html = render(show_live)
      assert html =~ "Student record type updated successfully"
      assert html =~ "some updated name"
    end
  end
end
