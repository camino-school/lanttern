defmodule LantternWeb.CurriculumControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.CurriculaFixtures

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
    test "lists all curricula", %{conn: conn} do
      conn = get(conn, ~p"/admin/curricula/cur")
      assert html_response(conn, 200) =~ "Listing Curricula"
    end
  end

  describe "new curriculum" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/curricula/cur/new")
      assert html_response(conn, 200) =~ "New Curriculum"
    end
  end

  describe "create curriculum" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/admin/curricula/cur", curriculum: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/curricula/cur/#{id}"

      conn = get(conn, ~p"/admin/curricula/cur/#{id}")
      assert html_response(conn, 200) =~ "Curriculum #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/curricula/cur", curriculum: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Curriculum"
    end
  end

  describe "edit curriculum" do
    setup [:create_curriculum]

    test "renders form for editing chosen curriculum", %{conn: conn, curriculum: curriculum} do
      conn = get(conn, ~p"/admin/curricula/cur/#{curriculum}/edit")
      assert html_response(conn, 200) =~ "Edit Curriculum"
    end
  end

  describe "update curriculum" do
    setup [:create_curriculum]

    test "redirects when data is valid", %{conn: conn, curriculum: curriculum} do
      conn = put(conn, ~p"/admin/curricula/cur/#{curriculum}", curriculum: @update_attrs)
      assert redirected_to(conn) == ~p"/admin/curricula/cur/#{curriculum}"

      conn = get(conn, ~p"/admin/curricula/cur/#{curriculum}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, curriculum: curriculum} do
      conn = put(conn, ~p"/admin/curricula/cur/#{curriculum}", curriculum: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Curriculum"
    end
  end

  describe "delete curriculum" do
    setup [:create_curriculum]

    test "deletes chosen curriculum", %{conn: conn, curriculum: curriculum} do
      conn = delete(conn, ~p"/admin/curricula/cur/#{curriculum}")
      assert redirected_to(conn) == ~p"/admin/curricula/cur"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/curricula/cur/#{curriculum}")
      end
    end
  end

  defp create_curriculum(_) do
    curriculum = curriculum_fixture()
    %{curriculum: curriculum}
  end
end
