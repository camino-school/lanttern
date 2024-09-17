defmodule LantternWeb.StudentRecordLiveTest do
  use LantternWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lanttern.StudentsRecordsFixtures

  alias Lanttern.SchoolsFixtures

  @update_attrs %{
    name: "some updated name",
    date: "2024-09-16",
    time: "15:01",
    description: "some updated description"
  }
  @invalid_attrs %{name: nil, date: nil, time: nil, description: nil}

  setup :register_and_log_in_root_admin

  defp create_student_record(_) do
    student_record = student_record_fixture()
    %{student_record: student_record}
  end

  describe "Index" do
    setup [:create_student_record]

    test "lists all students_records", %{conn: conn, student_record: student_record} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/students_records")

      assert html =~ "Listing Students records"
      assert html =~ student_record.name
    end

    test "saves new student_record", %{conn: conn} do
      school = SchoolsFixtures.school_fixture()
      status = student_record_status_fixture(%{school_id: school.id})
      type = student_record_type_fixture(%{school_id: school.id})

      {:ok, index_live, _html} = live(conn, ~p"/admin/students_records")

      assert index_live |> element("a", "New Student record") |> render_click() =~
               "New Student record"

      assert_patch(index_live, ~p"/admin/students_records/new")

      assert index_live
             |> form("#student_record-form", student_record: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      create_attrs = %{
        school_id: school.id,
        status_id: status.id,
        type_id: type.id,
        name: "some name",
        date: "2024-09-15",
        time: "14:00",
        description: "some description"
      }

      assert index_live
             |> form("#student_record-form", student_record: create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/students_records")

      html = render(index_live)
      assert html =~ "Student record created successfully"
      assert html =~ "some name"
    end

    test "updates student_record in listing", %{conn: conn, student_record: student_record} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/students_records")

      assert index_live
             |> element("#students_records-#{student_record.id} a", "Edit")
             |> render_click() =~
               "Edit Student record"

      assert_patch(index_live, ~p"/admin/students_records/#{student_record}/edit")

      assert index_live
             |> form("#student_record-form", student_record: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#student_record-form", student_record: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/students_records")

      html = render(index_live)
      assert html =~ "Student record updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes student_record in listing", %{conn: conn, student_record: student_record} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/students_records")

      assert index_live
             |> element("#students_records-#{student_record.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#students_records-#{student_record.id}")
    end
  end

  describe "Show" do
    setup [:create_student_record]

    test "displays student_record", %{conn: conn, student_record: student_record} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/students_records/#{student_record}")

      assert html =~ "Show Student record"
      assert html =~ student_record.name
    end

    test "updates student_record within modal", %{conn: conn, student_record: student_record} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/students_records/#{student_record}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Student record"

      assert_patch(show_live, ~p"/admin/students_records/#{student_record}/show/edit")

      assert show_live
             |> form("#student_record-form", student_record: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#student_record-form", student_record: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/students_records/#{student_record}")

      html = render(show_live)
      assert html =~ "Student record updated successfully"
      assert html =~ "some updated name"
    end
  end
end
