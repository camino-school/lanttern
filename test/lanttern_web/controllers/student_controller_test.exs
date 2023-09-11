defmodule LantternWeb.StudentControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.SchoolsFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup :register_and_log_in_root_admin

  describe "index" do
    test "lists all students", %{conn: conn} do
      conn = get(conn, ~p"/admin/schools/students")
      assert html_response(conn, 200) =~ "Listing Students"
    end
  end

  describe "new student" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/schools/students/new")
      assert html_response(conn, 200) =~ "New Student"
    end
  end

  describe "create student" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/admin/schools/students", student: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/schools/students/#{id}"

      conn = get(conn, ~p"/admin/schools/students/#{id}")
      assert html_response(conn, 200) =~ "Student #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/schools/students", student: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Student"
    end
  end

  describe "edit student" do
    setup [:create_student]

    test "renders form for editing chosen student", %{conn: conn, student: student} do
      conn = get(conn, ~p"/admin/schools/students/#{student}/edit")
      assert html_response(conn, 200) =~ "Edit Student"
    end
  end

  describe "update student" do
    setup [:create_student]

    test "redirects when data is valid", %{conn: conn, student: student} do
      conn = put(conn, ~p"/admin/schools/students/#{student}", student: @update_attrs)
      assert redirected_to(conn) == ~p"/admin/schools/students/#{student}"

      conn = get(conn, ~p"/admin/schools/students/#{student}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, student: student} do
      conn = put(conn, ~p"/admin/schools/students/#{student}", student: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Student"
    end
  end

  describe "delete student" do
    setup [:create_student]

    test "deletes chosen student", %{conn: conn, student: student} do
      conn = delete(conn, ~p"/admin/schools/students/#{student}")
      assert redirected_to(conn) == ~p"/admin/schools/students"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/schools/students/#{student}")
      end
    end
  end

  defp create_student(_) do
    student = student_fixture()
    %{student: student}
  end
end
