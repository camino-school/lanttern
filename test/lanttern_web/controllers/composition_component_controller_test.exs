defmodule LantternWeb.CompositionComponentControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.GradingFixtures

  @create_attrs %{name: "some name", weight: 120.5}
  @update_attrs %{name: "some updated name", weight: 456.7}
  @invalid_attrs %{name: nil, weight: nil}

  setup :register_and_log_in_root_admin

  describe "index" do
    test "lists all composition_components", %{conn: conn} do
      conn = get(conn, ~p"/admin/grading_composition_components")
      assert html_response(conn, 200) =~ "Listing Grade composition components"
    end
  end

  describe "new composition_component" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/grading_composition_components/new")
      assert html_response(conn, 200) =~ "New Composition component"
    end
  end

  describe "create composition_component" do
    test "redirects to show when data is valid", %{conn: conn} do
      composition = composition_fixture()
      create_attrs = @create_attrs |> Map.put_new(:composition_id, composition.id)

      conn =
        post(conn, ~p"/admin/grading_composition_components", composition_component: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/grading_composition_components/#{id}"

      conn = get(conn, ~p"/admin/grading_composition_components/#{id}")
      assert html_response(conn, 200) =~ "Composition component #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/admin/grading_composition_components",
          composition_component: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "New Composition component"
    end
  end

  describe "edit composition_component" do
    setup [:create_composition_component]

    test "renders form for editing chosen composition_component", %{
      conn: conn,
      composition_component: composition_component
    } do
      conn = get(conn, ~p"/admin/grading_composition_components/#{composition_component}/edit")
      assert html_response(conn, 200) =~ "Edit Composition component"
    end
  end

  describe "update composition_component" do
    setup [:create_composition_component]

    test "redirects when data is valid", %{
      conn: conn,
      composition_component: composition_component
    } do
      conn =
        put(conn, ~p"/admin/grading_composition_components/#{composition_component}",
          composition_component: @update_attrs
        )

      assert redirected_to(conn) ==
               ~p"/admin/grading_composition_components/#{composition_component}"

      conn = get(conn, ~p"/admin/grading_composition_components/#{composition_component}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{
      conn: conn,
      composition_component: composition_component
    } do
      conn =
        put(conn, ~p"/admin/grading_composition_components/#{composition_component}",
          composition_component: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "Edit Composition component"
    end
  end

  describe "delete composition_component" do
    setup [:create_composition_component]

    test "deletes chosen composition_component", %{
      conn: conn,
      composition_component: composition_component
    } do
      conn = delete(conn, ~p"/admin/grading_composition_components/#{composition_component}")
      assert redirected_to(conn) == ~p"/admin/grading_composition_components"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/grading_composition_components/#{composition_component}")
      end
    end
  end

  defp create_composition_component(_) do
    composition_component = composition_component_fixture()
    %{composition_component: composition_component}
  end
end
