defmodule LantternWeb.SchoolControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.SchoolsFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup :register_and_log_in_root_admin

  describe "index" do
    test "lists all schools", %{conn: conn} do
      conn = get(conn, ~p"/admin/schools")
      assert html_response(conn, 200) =~ "Listing Schools"
    end
  end

  describe "new school" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/schools/new")
      assert html_response(conn, 200) =~ "New School"
    end
  end

  describe "create school" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/admin/schools", school: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/schools/#{id}"

      conn = get(conn, ~p"/admin/schools/#{id}")
      assert html_response(conn, 200) =~ "School #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/schools", school: @invalid_attrs)
      assert html_response(conn, 200) =~ "New School"
    end
  end

  describe "edit school" do
    setup [:create_school]

    test "renders form for editing chosen school", %{conn: conn, school: school} do
      conn = get(conn, ~p"/admin/schools/#{school}/edit")
      assert html_response(conn, 200) =~ "Edit School"
    end
  end

  describe "update school" do
    setup [:create_school]

    test "redirects when data is valid", %{conn: conn, school: school} do
      conn = put(conn, ~p"/admin/schools/#{school}", school: @update_attrs)
      assert redirected_to(conn) == ~p"/admin/schools/#{school}"

      conn = get(conn, ~p"/admin/schools/#{school}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, school: school} do
      conn = put(conn, ~p"/admin/schools/#{school}", school: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit School"
    end
  end

  describe "delete school" do
    setup [:create_school]

    test "deletes chosen school", %{conn: conn, school: school} do
      conn = delete(conn, ~p"/admin/schools/#{school}")
      assert redirected_to(conn) == ~p"/admin/schools"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/schools/#{school}")
      end
    end
  end

  defp create_school(_) do
    school = school_fixture()
    %{school: school}
  end
end
