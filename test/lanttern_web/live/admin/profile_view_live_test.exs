defmodule LantternWeb.Admin.ProfileViewLiveTest do
  use LantternWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lanttern.PersonalizationFixtures

  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_profile_view(_) do
    profile_view = profile_view_fixture()
    %{profile_view: profile_view}
  end

  setup :register_and_log_in_root_admin

  describe "Index" do
    setup [:create_profile_view]

    test "lists all profile_views", %{
      conn: conn,
      profile_view: profile_view
    } do
      {:ok, _index_live, html} = live(conn, ~p"/admin/profile_views")

      assert html =~ "Listing Profile views"
      assert html =~ profile_view.name
    end

    test "saves new profile_view", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/profile_views")

      create_attrs = %{
        name: "some name",
        profile_id: Lanttern.IdentityFixtures.teacher_profile_fixture().id
      }

      assert index_live |> element("a", "New Profile view") |> render_click() =~
               "New Profile view"

      assert_patch(index_live, ~p"/admin/profile_views/new")

      assert index_live
             |> form("#profile_view-form",
               profile_view: @invalid_attrs
             )
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#profile_view-form",
               profile_view: create_attrs
             )
             |> render_submit()

      assert_patch(index_live, ~p"/admin/profile_views")

      html = render(index_live)
      assert html =~ "Profile view created successfully"
      assert html =~ "some name"
    end

    test "updates profile_view in listing", %{
      conn: conn,
      profile_view: profile_view
    } do
      {:ok, index_live, _html} = live(conn, ~p"/admin/profile_views")

      assert index_live
             |> element(
               "#profile_views-#{profile_view.id} a",
               "Edit"
             )
             |> render_click() =~
               "Edit Profile view"

      assert_patch(
        index_live,
        ~p"/admin/profile_views/#{profile_view}/edit"
      )

      assert index_live
             |> form("#profile_view-form",
               profile_view: @invalid_attrs
             )
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#profile_view-form",
               profile_view: @update_attrs
             )
             |> render_submit()

      assert_patch(index_live, ~p"/admin/profile_views")

      html = render(index_live)
      assert html =~ "Profile view updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes profile_view in listing", %{
      conn: conn,
      profile_view: profile_view
    } do
      {:ok, index_live, _html} = live(conn, ~p"/admin/profile_views")

      assert index_live
             |> element(
               "#profile_views-#{profile_view.id} a",
               "Delete"
             )
             |> render_click()

      refute has_element?(
               index_live,
               "#profile_views-#{profile_view.id}"
             )
    end
  end

  describe "Show" do
    setup [:create_profile_view]

    test "displays profile_view", %{
      conn: conn,
      profile_view: profile_view
    } do
      {:ok, _show_live, html} =
        live(conn, ~p"/admin/profile_views/#{profile_view}")

      assert html =~ "Show Profile view"
      assert html =~ profile_view.name
    end

    test "updates profile_view within modal", %{
      conn: conn,
      profile_view: profile_view
    } do
      {:ok, show_live, _html} =
        live(conn, ~p"/admin/profile_views/#{profile_view}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Profile view"

      assert_patch(
        show_live,
        ~p"/admin/profile_views/#{profile_view}/show/edit"
      )

      assert show_live
             |> form("#profile_view-form",
               profile_view: @invalid_attrs
             )
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#profile_view-form",
               profile_view: @update_attrs
             )
             |> render_submit()

      assert_patch(
        show_live,
        ~p"/admin/profile_views/#{profile_view}"
      )

      html = render(show_live)
      assert html =~ "Profile view updated successfully"
      assert html =~ "some updated name"
    end
  end
end
