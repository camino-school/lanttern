defmodule LantternWeb.CurriculumRelationshipControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.CurriculaFixtures

  @create_attrs %{type: "some type"}
  @update_attrs %{type: "some updated type"}
  @invalid_attrs %{type: nil}

  setup %{conn: conn} do
    # log_in user for all test cases
    conn =
      conn
      |> log_in_user(Lanttern.IdentityFixtures.root_admin_fixture())

    [conn: conn]
  end

  describe "index" do
    test "lists all curriculum_relationships", %{conn: conn} do
      conn = get(conn, ~p"/admin/curricula/curriculum_relationships")
      assert html_response(conn, 200) =~ "Listing Curriculum relationships"
    end
  end

  describe "new curriculum_relationship" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/curricula/curriculum_relationships/new")
      assert html_response(conn, 200) =~ "New Curriculum relationship"
    end
  end

  describe "create curriculum_relationship" do
    test "redirects to show when data is valid", %{conn: conn} do
      curriculum_item_a = curriculum_item_fixture()
      curriculum_item_b = curriculum_item_fixture()

      create_attrs =
        @create_attrs
        |> Map.put(:curriculum_item_a_id, curriculum_item_a.id)
        |> Map.put(:curriculum_item_b_id, curriculum_item_b.id)

      conn =
        post(conn, ~p"/admin/curricula/curriculum_relationships",
          curriculum_relationship: create_attrs
        )

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/curricula/curriculum_relationships/#{id}"

      conn = get(conn, ~p"/admin/curricula/curriculum_relationships/#{id}")
      assert html_response(conn, 200) =~ "Curriculum relationship #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/admin/curricula/curriculum_relationships",
          curriculum_relationship: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "New Curriculum relationship"
    end
  end

  describe "edit curriculum_relationship" do
    setup [:create_curriculum_relationship]

    test "renders form for editing chosen curriculum_relationship", %{
      conn: conn,
      curriculum_relationship: curriculum_relationship
    } do
      conn =
        get(conn, ~p"/admin/curricula/curriculum_relationships/#{curriculum_relationship}/edit")

      assert html_response(conn, 200) =~ "Edit Curriculum relationship"
    end
  end

  describe "update curriculum_relationship" do
    setup [:create_curriculum_relationship]

    test "redirects when data is valid", %{
      conn: conn,
      curriculum_relationship: curriculum_relationship
    } do
      conn =
        put(conn, ~p"/admin/curricula/curriculum_relationships/#{curriculum_relationship}",
          curriculum_relationship: @update_attrs
        )

      assert redirected_to(conn) ==
               ~p"/admin/curricula/curriculum_relationships/#{curriculum_relationship}"

      conn = get(conn, ~p"/admin/curricula/curriculum_relationships/#{curriculum_relationship}")
      assert html_response(conn, 200) =~ "some updated type"
    end

    test "renders errors when data is invalid", %{
      conn: conn,
      curriculum_relationship: curriculum_relationship
    } do
      conn =
        put(conn, ~p"/admin/curricula/curriculum_relationships/#{curriculum_relationship}",
          curriculum_relationship: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "Edit Curriculum relationship"
    end
  end

  describe "delete curriculum_relationship" do
    setup [:create_curriculum_relationship]

    test "deletes chosen curriculum_relationship", %{
      conn: conn,
      curriculum_relationship: curriculum_relationship
    } do
      conn =
        delete(conn, ~p"/admin/curricula/curriculum_relationships/#{curriculum_relationship}")

      assert redirected_to(conn) == ~p"/admin/curricula/curriculum_relationships"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/curricula/curriculum_relationships/#{curriculum_relationship}")
      end
    end
  end

  defp create_curriculum_relationship(_) do
    curriculum_relationship = curriculum_relationship_fixture()
    %{curriculum_relationship: curriculum_relationship}
  end
end
