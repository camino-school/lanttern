defmodule LantternWeb.ItemControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.CurriculaFixtures

  @create_attrs %{name: "some name", code: "some code"}
  @update_attrs %{name: "some updated name", code: "some updated code"}
  @invalid_attrs %{name: nil, code: nil}

  setup %{conn: conn} do
    # log_in user for all test cases
    conn =
      conn
      |> log_in_user(Lanttern.IdentityFixtures.root_admin_fixture())

    [conn: conn]
  end

  describe "index" do
    test "lists all items", %{conn: conn} do
      conn = get(conn, ~p"/admin/curricula/curriculum_items")
      assert html_response(conn, 200) =~ "Listing Curriculum Items"
    end
  end

  describe "new item" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/curricula/curriculum_items/new")
      assert html_response(conn, 200) =~ "New Curriculum Item"
    end
  end

  describe "create item" do
    test "redirects to show when data is valid", %{conn: conn} do
      curriculum_component = curriculum_component_fixture()
      create_attrs = @create_attrs |> Map.put(:curriculum_component_id, curriculum_component.id)

      conn = post(conn, ~p"/admin/curricula/curriculum_items", curriculum_item: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/curricula/curriculum_items/#{id}"

      conn = get(conn, ~p"/admin/curricula/curriculum_items/#{id}")
      assert html_response(conn, 200) =~ "Item #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/curricula/curriculum_items", curriculum_item: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Curriculum Item"
    end
  end

  describe "edit item" do
    setup [:create_curriculum_item]

    test "renders form for editing chosen item", %{conn: conn, curriculum_item: curriculum_item} do
      conn = get(conn, ~p"/admin/curricula/curriculum_items/#{curriculum_item}/edit")
      assert html_response(conn, 200) =~ "Edit Curriculum Item"
    end
  end

  describe "update item" do
    setup [:create_curriculum_item]

    test "redirects when data is valid", %{conn: conn, curriculum_item: curriculum_item} do
      conn =
        put(conn, ~p"/admin/curricula/curriculum_items/#{curriculum_item}",
          curriculum_item: @update_attrs
        )

      assert redirected_to(conn) == ~p"/admin/curricula/curriculum_items/#{curriculum_item}"

      conn = get(conn, ~p"/admin/curricula/curriculum_items/#{curriculum_item}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, curriculum_item: curriculum_item} do
      conn =
        put(conn, ~p"/admin/curricula/curriculum_items/#{curriculum_item}",
          curriculum_item: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "Edit Curriculum Item"
    end
  end

  describe "delete item" do
    setup [:create_curriculum_item]

    test "deletes chosen item", %{conn: conn, curriculum_item: curriculum_item} do
      conn = delete(conn, ~p"/admin/curricula/curriculum_items/#{curriculum_item}")
      assert redirected_to(conn) == ~p"/admin/curricula/curriculum_items"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/curricula/curriculum_items/#{curriculum_item}")
      end
    end
  end

  defp create_curriculum_item(_) do
    curriculum_item = curriculum_item_fixture()
    %{curriculum_item: curriculum_item}
  end
end
