defmodule LantternWeb.CompositionComponentItemControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.GradingFixtures
  alias Lanttern.CurriculaFixtures

  @create_attrs %{weight: 120.5}
  @update_attrs %{weight: 456.7}
  @invalid_attrs %{weight: nil}

  setup %{conn: conn} do
    # log_in user for all test cases
    conn =
      conn
      |> log_in_user(Lanttern.IdentityFixtures.user_fixture())

    [conn: conn]
  end

  describe "index" do
    test "lists all component_items", %{conn: conn} do
      conn = get(conn, ~p"/admin/grading/component_items")
      assert html_response(conn, 200) =~ "Listing Component items"
    end
  end

  describe "new composition_component_item" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/grading/component_items/new")
      assert html_response(conn, 200) =~ "New Composition component item"
    end
  end

  describe "create composition_component_item" do
    test "redirects to show when data is valid", %{conn: conn} do
      component = composition_component_fixture()
      curriculum_item = CurriculaFixtures.item_fixture()

      create_attrs =
        @create_attrs
        |> Map.put_new(:component_id, component.id)
        |> Map.put_new(:curriculum_item_id, curriculum_item.id)

      conn =
        post(conn, ~p"/admin/grading/component_items", composition_component_item: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/grading/component_items/#{id}"

      conn = get(conn, ~p"/admin/grading/component_items/#{id}")
      assert html_response(conn, 200) =~ "Composition component item #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/admin/grading/component_items", composition_component_item: @invalid_attrs)

      assert html_response(conn, 200) =~ "New Composition component item"
    end
  end

  describe "edit composition_component_item" do
    setup [:create_composition_component_item]

    test "renders form for editing chosen composition_component_item", %{
      conn: conn,
      composition_component_item: composition_component_item
    } do
      conn = get(conn, ~p"/admin/grading/component_items/#{composition_component_item}/edit")
      assert html_response(conn, 200) =~ "Edit Composition component item"
    end
  end

  describe "update composition_component_item" do
    setup [:create_composition_component_item]

    test "redirects when data is valid", %{
      conn: conn,
      composition_component_item: composition_component_item
    } do
      conn =
        put(conn, ~p"/admin/grading/component_items/#{composition_component_item}",
          composition_component_item: @update_attrs
        )

      assert redirected_to(conn) ==
               ~p"/admin/grading/component_items/#{composition_component_item}"

      conn = get(conn, ~p"/admin/grading/component_items/#{composition_component_item}")
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{
      conn: conn,
      composition_component_item: composition_component_item
    } do
      conn =
        put(conn, ~p"/admin/grading/component_items/#{composition_component_item}",
          composition_component_item: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "Edit Composition component item"
    end
  end

  describe "delete composition_component_item" do
    setup [:create_composition_component_item]

    test "deletes chosen composition_component_item", %{
      conn: conn,
      composition_component_item: composition_component_item
    } do
      conn = delete(conn, ~p"/admin/grading/component_items/#{composition_component_item}")
      assert redirected_to(conn) == ~p"/admin/grading/component_items"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/grading/component_items/#{composition_component_item}")
      end
    end
  end

  defp create_composition_component_item(_) do
    composition_component_item = composition_component_item_fixture()
    %{composition_component_item: composition_component_item}
  end
end
