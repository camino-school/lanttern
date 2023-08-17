defmodule LantternWeb.ClassControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.SchoolsFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup %{conn: conn} do
    # log_in user for all test cases
    conn =
      conn
      |> log_in_user(Lanttern.IdentityFixtures.root_admin_fixture())

    [conn: conn]
  end

  describe "index" do
    test "lists all classes", %{conn: conn} do
      conn = get(conn, ~p"/admin/schools/classes")
      assert html_response(conn, 200) =~ "Listing Classes"
    end
  end

  describe "new class" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/schools/classes/new")
      assert html_response(conn, 200) =~ "New Class"
    end
  end

  describe "create class" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/admin/schools/classes", class: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/schools/classes/#{id}"

      conn = get(conn, ~p"/admin/schools/classes/#{id}")
      assert html_response(conn, 200) =~ "Class #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/schools/classes", class: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Class"
    end
  end

  describe "edit class" do
    setup [:create_class]

    test "renders form for editing chosen class", %{conn: conn, class: class} do
      conn = get(conn, ~p"/admin/schools/classes/#{class}/edit")
      assert html_response(conn, 200) =~ "Edit Class"
    end
  end

  describe "update class" do
    setup [:create_class]

    test "redirects when data is valid", %{conn: conn, class: class} do
      conn = put(conn, ~p"/admin/schools/classes/#{class}", class: @update_attrs)
      assert redirected_to(conn) == ~p"/admin/schools/classes/#{class}"

      conn = get(conn, ~p"/admin/schools/classes/#{class}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, class: class} do
      conn = put(conn, ~p"/admin/schools/classes/#{class}", class: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Class"
    end
  end

  describe "delete class" do
    setup [:create_class]

    test "deletes chosen class", %{conn: conn, class: class} do
      conn = delete(conn, ~p"/admin/schools/classes/#{class}")
      assert redirected_to(conn) == ~p"/admin/schools/classes"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/schools/classes/#{class}")
      end
    end
  end

  defp create_class(_) do
    class = class_fixture()
    %{class: class}
  end
end
