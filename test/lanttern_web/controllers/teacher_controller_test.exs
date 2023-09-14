defmodule LantternWeb.TeacherControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.SchoolsFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup :register_and_log_in_root_admin

  describe "index" do
    test "lists all teachers", %{conn: conn} do
      conn = get(conn, ~p"/admin/teachers")
      assert html_response(conn, 200) =~ "Listing Teachers"
    end
  end

  describe "new teacher" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/teachers/new")
      assert html_response(conn, 200) =~ "New Teacher"
    end
  end

  describe "create teacher" do
    test "redirects to show when data is valid", %{conn: conn} do
      school = school_fixture()
      create_attrs = @create_attrs |> Map.put_new(:school_id, school.id)
      conn = post(conn, ~p"/admin/teachers", teacher: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/teachers/#{id}"

      conn = get(conn, ~p"/admin/teachers/#{id}")
      assert html_response(conn, 200) =~ "Teacher #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/teachers", teacher: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Teacher"
    end
  end

  describe "edit teacher" do
    setup [:create_teacher]

    test "renders form for editing chosen teacher", %{conn: conn, teacher: teacher} do
      conn = get(conn, ~p"/admin/teachers/#{teacher}/edit")
      assert html_response(conn, 200) =~ "Edit Teacher"
    end
  end

  describe "update teacher" do
    setup [:create_teacher]

    test "redirects when data is valid", %{conn: conn, teacher: teacher} do
      conn = put(conn, ~p"/admin/teachers/#{teacher}", teacher: @update_attrs)
      assert redirected_to(conn) == ~p"/admin/teachers/#{teacher}"

      conn = get(conn, ~p"/admin/teachers/#{teacher}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, teacher: teacher} do
      conn = put(conn, ~p"/admin/teachers/#{teacher}", teacher: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Teacher"
    end
  end

  describe "delete teacher" do
    setup [:create_teacher]

    test "deletes chosen teacher", %{conn: conn, teacher: teacher} do
      conn = delete(conn, ~p"/admin/teachers/#{teacher}")
      assert redirected_to(conn) == ~p"/admin/teachers"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/teachers/#{teacher}")
      end
    end
  end

  defp create_teacher(_) do
    teacher = teacher_fixture()
    %{teacher: teacher}
  end
end
