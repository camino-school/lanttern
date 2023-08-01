defmodule LantternWeb.OrdinalScaleControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.GradingFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  describe "index" do
    test "lists all ordinal_scales", %{conn: conn} do
      conn = get(conn, ~p"/grading/ordinal_scales")
      assert html_response(conn, 200) =~ "Listing Ordinal scales"
    end
  end

  describe "new ordinal_scale" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/grading/ordinal_scales/new")
      assert html_response(conn, 200) =~ "New Ordinal scale"
    end
  end

  describe "create ordinal_scale" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/grading/ordinal_scales", ordinal_scale: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/grading/ordinal_scales/#{id}"

      conn = get(conn, ~p"/grading/ordinal_scales/#{id}")
      assert html_response(conn, 200) =~ "Ordinal scale #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/grading/ordinal_scales", ordinal_scale: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Ordinal scale"
    end
  end

  describe "edit ordinal_scale" do
    setup [:create_ordinal_scale]

    test "renders form for editing chosen ordinal_scale", %{
      conn: conn,
      ordinal_scale: ordinal_scale
    } do
      conn = get(conn, ~p"/grading/ordinal_scales/#{ordinal_scale}/edit")
      assert html_response(conn, 200) =~ "Edit Ordinal scale"
    end
  end

  describe "update ordinal_scale" do
    setup [:create_ordinal_scale]

    test "redirects when data is valid", %{conn: conn, ordinal_scale: ordinal_scale} do
      conn = put(conn, ~p"/grading/ordinal_scales/#{ordinal_scale}", ordinal_scale: @update_attrs)
      assert redirected_to(conn) == ~p"/grading/ordinal_scales/#{ordinal_scale}"

      conn = get(conn, ~p"/grading/ordinal_scales/#{ordinal_scale}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, ordinal_scale: ordinal_scale} do
      conn =
        put(conn, ~p"/grading/ordinal_scales/#{ordinal_scale}", ordinal_scale: @invalid_attrs)

      assert html_response(conn, 200) =~ "Edit Ordinal scale"
    end
  end

  describe "delete ordinal_scale" do
    setup [:create_ordinal_scale]

    test "deletes chosen ordinal_scale", %{conn: conn, ordinal_scale: ordinal_scale} do
      conn = delete(conn, ~p"/grading/ordinal_scales/#{ordinal_scale}")
      assert redirected_to(conn) == ~p"/grading/ordinal_scales"

      assert_error_sent 404, fn ->
        get(conn, ~p"/grading/ordinal_scales/#{ordinal_scale}")
      end
    end
  end

  defp create_ordinal_scale(_) do
    ordinal_scale = ordinal_scale_fixture()
    %{ordinal_scale: ordinal_scale}
  end
end
