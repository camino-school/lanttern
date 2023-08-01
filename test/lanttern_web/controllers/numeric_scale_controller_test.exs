defmodule LantternWeb.NumericScaleControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.GradingFixtures

  @create_attrs %{name: "some name", start: 120.5, stop: 120.5}
  @update_attrs %{name: "some updated name", start: 456.7, stop: 456.7}
  @invalid_attrs %{name: nil, start: nil, stop: nil}

  describe "index" do
    test "lists all numeric_scales", %{conn: conn} do
      conn = get(conn, ~p"/grading/numeric_scales")
      assert html_response(conn, 200) =~ "Listing Numeric scales"
    end
  end

  describe "new numeric_scale" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/grading/numeric_scales/new")
      assert html_response(conn, 200) =~ "New Numeric scale"
    end
  end

  describe "create numeric_scale" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/grading/numeric_scales", numeric_scale: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/grading/numeric_scales/#{id}"

      conn = get(conn, ~p"/grading/numeric_scales/#{id}")
      assert html_response(conn, 200) =~ "Numeric scale #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/grading/numeric_scales", numeric_scale: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Numeric scale"
    end
  end

  describe "edit numeric_scale" do
    setup [:create_numeric_scale]

    test "renders form for editing chosen numeric_scale", %{
      conn: conn,
      numeric_scale: numeric_scale
    } do
      conn = get(conn, ~p"/grading/numeric_scales/#{numeric_scale}/edit")
      assert html_response(conn, 200) =~ "Edit Numeric scale"
    end
  end

  describe "update numeric_scale" do
    setup [:create_numeric_scale]

    test "redirects when data is valid", %{conn: conn, numeric_scale: numeric_scale} do
      conn = put(conn, ~p"/grading/numeric_scales/#{numeric_scale}", numeric_scale: @update_attrs)
      assert redirected_to(conn) == ~p"/grading/numeric_scales/#{numeric_scale}"

      conn = get(conn, ~p"/grading/numeric_scales/#{numeric_scale}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, numeric_scale: numeric_scale} do
      conn =
        put(conn, ~p"/grading/numeric_scales/#{numeric_scale}", numeric_scale: @invalid_attrs)

      assert html_response(conn, 200) =~ "Edit Numeric scale"
    end
  end

  describe "delete numeric_scale" do
    setup [:create_numeric_scale]

    test "deletes chosen numeric_scale", %{conn: conn, numeric_scale: numeric_scale} do
      conn = delete(conn, ~p"/grading/numeric_scales/#{numeric_scale}")
      assert redirected_to(conn) == ~p"/grading/numeric_scales"

      assert_error_sent 404, fn ->
        get(conn, ~p"/grading/numeric_scales/#{numeric_scale}")
      end
    end
  end

  defp create_numeric_scale(_) do
    numeric_scale = numeric_scale_fixture()
    %{numeric_scale: numeric_scale}
  end
end
