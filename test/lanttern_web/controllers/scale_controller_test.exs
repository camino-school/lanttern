defmodule LantternWeb.ScaleControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.GradingFixtures

  @create_attrs %{name: "some name", start: 120.5, stop: 120.5, type: "numeric"}
  @update_attrs %{name: "some updated name", start: 456.7, stop: 456.7, type: "numeric"}
  @invalid_attrs %{name: nil, start: nil, stop: nil, type: nil}

  setup :register_and_log_in_root_admin

  describe "index" do
    test "lists all scales", %{conn: conn} do
      conn = get(conn, ~p"/admin/scales")
      assert html_response(conn, 200) =~ "Listing Scales"
    end
  end

  describe "new scale" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/scales/new")
      assert html_response(conn, 200) =~ "New Scale"
    end
  end

  describe "create scale" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/admin/scales", scale: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/scales/#{id}"

      conn = get(conn, ~p"/admin/scales/#{id}")
      assert html_response(conn, 200) =~ "Scale #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/scales", scale: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Scale"
    end
  end

  describe "edit scale" do
    setup [:create_scale]

    test "renders form for editing chosen scale", %{conn: conn, scale: scale} do
      conn = get(conn, ~p"/admin/scales/#{scale}/edit")
      assert html_response(conn, 200) =~ "Edit Scale"
    end
  end

  describe "update scale" do
    setup [:create_scale]

    test "redirects when data is valid", %{conn: conn, scale: scale} do
      conn = put(conn, ~p"/admin/scales/#{scale}", scale: @update_attrs)
      assert redirected_to(conn) == ~p"/admin/scales/#{scale}"

      conn = get(conn, ~p"/admin/scales/#{scale}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, scale: scale} do
      conn = put(conn, ~p"/admin/scales/#{scale}", scale: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Scale"
    end
  end

  describe "delete scale" do
    setup [:create_scale]

    test "deletes chosen scale", %{conn: conn, scale: scale} do
      conn = delete(conn, ~p"/admin/scales/#{scale}")
      assert redirected_to(conn) == ~p"/admin/scales"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/scales/#{scale}")
      end
    end
  end

  defp create_scale(_) do
    scale = scale_fixture()
    %{scale: scale}
  end
end
