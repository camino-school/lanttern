defmodule LantternWeb.YearControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.TaxonomyFixtures

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
    test "lists all years", %{conn: conn} do
      conn = get(conn, ~p"/admin/taxonomy/years")
      assert html_response(conn, 200) =~ "Listing Years"
    end
  end

  describe "new year" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/taxonomy/years/new")
      assert html_response(conn, 200) =~ "New Year"
    end
  end

  describe "create year" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/admin/taxonomy/years", year: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/taxonomy/years/#{id}"

      conn = get(conn, ~p"/admin/taxonomy/years/#{id}")
      assert html_response(conn, 200) =~ "Year #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/taxonomy/years", year: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Year"
    end
  end

  describe "edit year" do
    setup [:create_year]

    test "renders form for editing chosen year", %{conn: conn, year: year} do
      conn = get(conn, ~p"/admin/taxonomy/years/#{year}/edit")
      assert html_response(conn, 200) =~ "Edit Year"
    end
  end

  describe "update year" do
    setup [:create_year]

    test "redirects when data is valid", %{conn: conn, year: year} do
      conn = put(conn, ~p"/admin/taxonomy/years/#{year}", year: @update_attrs)
      assert redirected_to(conn) == ~p"/admin/taxonomy/years/#{year}"

      conn = get(conn, ~p"/admin/taxonomy/years/#{year}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, year: year} do
      conn = put(conn, ~p"/admin/taxonomy/years/#{year}", year: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Year"
    end
  end

  describe "delete year" do
    setup [:create_year]

    test "deletes chosen year", %{conn: conn, year: year} do
      conn = delete(conn, ~p"/admin/taxonomy/years/#{year}")
      assert redirected_to(conn) == ~p"/admin/taxonomy/years"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/taxonomy/years/#{year}")
      end
    end
  end

  defp create_year(_) do
    year = year_fixture()
    %{year: year}
  end
end