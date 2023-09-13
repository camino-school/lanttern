defmodule LantternWeb.CurriculumComponentControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.CurriculaFixtures

  @create_attrs %{code: "some code", name: "some name"}
  @update_attrs %{code: "some updated code", name: "some updated name"}
  @invalid_attrs %{code: nil, name: nil}

  setup :register_and_log_in_root_admin

  describe "index" do
    test "lists all curriculum_components", %{conn: conn} do
      conn = get(conn, ~p"/admin/curricula/curriculum_components")
      assert html_response(conn, 200) =~ "Listing Curriculum components"
    end
  end

  describe "new curriculum_component" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/curricula/curriculum_components/new")
      assert html_response(conn, 200) =~ "New Curriculum component"
    end
  end

  describe "create curriculum_component" do
    test "redirects to show when data is valid", %{conn: conn} do
      curriculum = curriculum_fixture()
      create_attrs = @create_attrs |> Map.put_new(:curriculum_id, curriculum.id)

      conn =
        post(conn, ~p"/admin/curricula/curriculum_components", curriculum_component: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/curricula/curriculum_components/#{id}"

      conn = get(conn, ~p"/admin/curricula/curriculum_components/#{id}")
      assert html_response(conn, 200) =~ "Curriculum component #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/admin/curricula/curriculum_components",
          curriculum_component: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "New Curriculum component"
    end
  end

  describe "edit curriculum_component" do
    setup [:create_curriculum_component]

    test "renders form for editing chosen curriculum_component", %{
      conn: conn,
      curriculum_component: curriculum_component
    } do
      conn = get(conn, ~p"/admin/curricula/curriculum_components/#{curriculum_component}/edit")
      assert html_response(conn, 200) =~ "Edit Curriculum component"
    end
  end

  describe "update curriculum_component" do
    setup [:create_curriculum_component]

    test "redirects when data is valid", %{conn: conn, curriculum_component: curriculum_component} do
      conn =
        put(conn, ~p"/admin/curricula/curriculum_components/#{curriculum_component}",
          curriculum_component: @update_attrs
        )

      assert redirected_to(conn) ==
               ~p"/admin/curricula/curriculum_components/#{curriculum_component}"

      conn = get(conn, ~p"/admin/curricula/curriculum_components/#{curriculum_component}")
      assert html_response(conn, 200) =~ "some updated code"
    end

    test "renders errors when data is invalid", %{
      conn: conn,
      curriculum_component: curriculum_component
    } do
      conn =
        put(conn, ~p"/admin/curricula/curriculum_components/#{curriculum_component}",
          curriculum_component: @invalid_attrs
        )

      assert html_response(conn, 200) =~ "Edit Curriculum component"
    end
  end

  describe "delete curriculum_component" do
    setup [:create_curriculum_component]

    test "deletes chosen curriculum_component", %{
      conn: conn,
      curriculum_component: curriculum_component
    } do
      conn = delete(conn, ~p"/admin/curricula/curriculum_components/#{curriculum_component}")
      assert redirected_to(conn) == ~p"/admin/curricula/curriculum_components"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/curricula/curriculum_components/#{curriculum_component}")
      end
    end
  end

  defp create_curriculum_component(_) do
    curriculum_component = curriculum_component_fixture()
    %{curriculum_component: curriculum_component}
  end
end
