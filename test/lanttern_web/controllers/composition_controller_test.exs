defmodule LantternWeb.CompositionControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.GradingFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup %{conn: conn} do
    # log_in user for all test cases
    conn =
      conn
      |> log_in_user(Lanttern.IdentityFixtures.user_fixture())

    [conn: conn]
  end

  describe "index" do
    test "lists all compositions", %{conn: conn} do
      conn = get(conn, ~p"/admin/grading/compositions")
      assert html_response(conn, 200) =~ "Listing Compositions"
    end
  end

  describe "new composition" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/grading/compositions/new")
      assert html_response(conn, 200) =~ "New Composition"
    end
  end

  describe "create composition" do
    test "redirects to show when data is valid", %{conn: conn} do
      scale = scale_fixture()
      create_attrs = @create_attrs |> Map.put_new(:final_grade_scale_id, scale.id)
      conn = post(conn, ~p"/admin/grading/compositions", composition: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/grading/compositions/#{id}"

      conn = get(conn, ~p"/admin/grading/compositions/#{id}")
      assert html_response(conn, 200) =~ "Composition #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/grading/compositions", composition: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Composition"
    end
  end

  describe "edit composition" do
    setup [:create_composition]

    test "renders form for editing chosen composition", %{conn: conn, composition: composition} do
      conn = get(conn, ~p"/admin/grading/compositions/#{composition}/edit")
      assert html_response(conn, 200) =~ "Edit Composition"
    end
  end

  describe "update composition" do
    setup [:create_composition]

    test "redirects when data is valid", %{conn: conn, composition: composition} do
      conn = put(conn, ~p"/admin/grading/compositions/#{composition}", composition: @update_attrs)
      assert redirected_to(conn) == ~p"/admin/grading/compositions/#{composition}"

      conn = get(conn, ~p"/admin/grading/compositions/#{composition}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, composition: composition} do
      conn =
        put(conn, ~p"/admin/grading/compositions/#{composition}", composition: @invalid_attrs)

      assert html_response(conn, 200) =~ "Edit Composition"
    end
  end

  describe "delete composition" do
    setup [:create_composition]

    test "deletes chosen composition", %{conn: conn, composition: composition} do
      conn = delete(conn, ~p"/admin/grading/compositions/#{composition}")
      assert redirected_to(conn) == ~p"/admin/grading/compositions"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/grading/compositions/#{composition}")
      end
    end
  end

  defp create_composition(_) do
    composition = composition_fixture()
    %{composition: composition}
  end
end
