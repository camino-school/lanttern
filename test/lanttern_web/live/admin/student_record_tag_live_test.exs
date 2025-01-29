defmodule LantternWeb.Admin.StudentRecordTagLiveTest do
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

  defp create_student_record_tag(_) do
    student_record_tag = student_record_tag_fixture()
    %{student_record_tag: student_record_tag}
  end

  describe "Index" do
    setup [:create_student_record_tag]

    test "lists all student_record_tags", %{conn: conn, student_record_tag: student_record_tag} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/student_record_tags")

      assert html =~ "Listing Student record tags"
      assert html =~ student_record_tag.name
    end

    test "saves new student_record_tag", %{conn: conn} do
      school = SchoolsFixtures.school_fixture()
      {:ok, index_live, _html} = live(conn, ~p"/admin/student_record_tags")

      assert index_live |> element("a", "New Student record tag") |> render_click() =~
               "New Student record tag"

      assert_patch(index_live, ~p"/admin/student_record_tags/new")

      assert index_live
             |> form("#student_record_tag-form", tag: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      create_attrs = %{
        school_id: school.id,
        name: "some name",
        bg_color: "#000000",
        text_color: "#ffffff"
      }

      assert index_live
             |> form("#student_record_tag-form", tag: create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/student_record_tags")

      html = render(index_live)
      assert html =~ "Student record tag created successfully"
      assert html =~ "some name"
    end

    test "updates student_record_tag in listing", %{
      conn: conn,
      student_record_tag: student_record_tag
    } do
      {:ok, index_live, _html} = live(conn, ~p"/admin/student_record_tags")

      assert index_live
             |> element("#student_record_tags-#{student_record_tag.id} a", "Edit")
             |> render_click() =~
               "Edit Student record tag"

      assert_patch(index_live, ~p"/admin/student_record_tags/#{student_record_tag}/edit")

      assert index_live
             |> form("#student_record_tag-form", tag: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#student_record_tag-form", tag: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/student_record_tags")

      html = render(index_live)
      assert html =~ "Student record tag updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes student_record_tag in listing", %{
      conn: conn,
      student_record_tag: student_record_tag
    } do
      {:ok, index_live, _html} = live(conn, ~p"/admin/student_record_tags")

      assert index_live
             |> element("#student_record_tags-#{student_record_tag.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#student_record_tags-#{student_record_tag.id}")
    end
  end

  describe "Show" do
    setup [:create_student_record_tag]

    test "displays student_record_tag", %{conn: conn, student_record_tag: student_record_tag} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/student_record_tags/#{student_record_tag}")

      assert html =~ "Show Student record tag"
      assert html =~ student_record_tag.name
    end

    test "updates student_record_tag within modal", %{
      conn: conn,
      student_record_tag: student_record_tag
    } do
      {:ok, show_live, _html} = live(conn, ~p"/admin/student_record_tags/#{student_record_tag}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Student record tag"

      assert_patch(show_live, ~p"/admin/student_record_tags/#{student_record_tag}/show/edit")

      assert show_live
             |> form("#student_record_tag-form", tag: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#student_record_tag-form", tag: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/student_record_tags/#{student_record_tag}")

      html = render(show_live)
      assert html =~ "Student record tag updated successfully"
      assert html =~ "some updated name"
    end
  end
end
