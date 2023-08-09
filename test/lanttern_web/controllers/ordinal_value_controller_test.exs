defmodule LantternWeb.OrdinalValueControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.GradingFixtures

  @create_attrs %{name: "some name", normalized_value: 0.42}
  @update_attrs %{name: "some updated name", normalized_value: 0.43}
  @invalid_attrs %{name: nil, normalized_value: nil}

  setup %{conn: conn} do
    # log_in user for all test cases
    conn =
      conn
      |> log_in_user(Lanttern.IdentityFixtures.root_admin_fixture())

    [conn: conn]
  end

  describe "index" do
    test "lists all ordinal_values", %{conn: conn} do
      conn = get(conn, ~p"/admin/grading/ordinal_values")
      assert html_response(conn, 200) =~ "Listing Ordinal values"
    end
  end

  describe "new ordinal_value" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/grading/ordinal_values/new")
      assert html_response(conn, 200) =~ "New Ordinal value"
    end
  end

  describe "create ordinal_value" do
    test "redirects to show when data is valid", %{conn: conn} do
      scale = scale_fixture()
      create_attrs = @create_attrs |> Map.put_new(:scale_id, scale.id)
      conn = post(conn, ~p"/admin/grading/ordinal_values", ordinal_value: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/grading/ordinal_values/#{id}"

      conn = get(conn, ~p"/admin/grading/ordinal_values/#{id}")
      assert html_response(conn, 200) =~ "Ordinal value #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/grading/ordinal_values", ordinal_value: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Ordinal value"
    end
  end

  describe "edit ordinal_value" do
    setup [:create_ordinal_value]

    test "renders form for editing chosen ordinal_value", %{
      conn: conn,
      ordinal_value: ordinal_value
    } do
      conn = get(conn, ~p"/admin/grading/ordinal_values/#{ordinal_value}/edit")
      assert html_response(conn, 200) =~ "Edit Ordinal value"
    end
  end

  describe "update ordinal_value" do
    setup [:create_ordinal_value]

    test "redirects when data is valid", %{conn: conn, ordinal_value: ordinal_value} do
      conn =
        put(conn, ~p"/admin/grading/ordinal_values/#{ordinal_value}",
          ordinal_value: @update_attrs
        )

      assert redirected_to(conn) == ~p"/admin/grading/ordinal_values/#{ordinal_value}"

      conn = get(conn, ~p"/admin/grading/ordinal_values/#{ordinal_value}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, ordinal_value: ordinal_value} do
      conn =
        put(conn, ~p"/admin/grading/ordinal_values/#{ordinal_value}",
          ordinal_value: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "Edit Ordinal value"
    end
  end

  describe "delete ordinal_value" do
    setup [:create_ordinal_value]

    test "deletes chosen ordinal_value", %{conn: conn, ordinal_value: ordinal_value} do
      conn = delete(conn, ~p"/admin/grading/ordinal_values/#{ordinal_value}")
      assert redirected_to(conn) == ~p"/admin/grading/ordinal_values"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/grading/ordinal_values/#{ordinal_value}")
      end
    end
  end

  defp create_ordinal_value(_) do
    ordinal_value = ordinal_value_fixture()
    %{ordinal_value: ordinal_value}
  end
end
