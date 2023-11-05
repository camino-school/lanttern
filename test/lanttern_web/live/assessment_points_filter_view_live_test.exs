defmodule LantternWeb.Admin.AssessmentPointsFilterViewLiveTest do
  use LantternWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lanttern.ExplorerFixtures

  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  defp create_assessment_points_filter_view(_) do
    assessment_points_filter_view = assessment_points_filter_view_fixture()
    %{assessment_points_filter_view: assessment_points_filter_view}
  end

  setup :register_and_log_in_root_admin

  describe "Index" do
    setup [:create_assessment_points_filter_view]

    test "lists all assessment_points_filter_views", %{
      conn: conn,
      assessment_points_filter_view: assessment_points_filter_view
    } do
      {:ok, _index_live, html} = live(conn, ~p"/admin/assessment_points_filter_views")

      assert html =~ "Listing Assessment points filter views"
      assert html =~ assessment_points_filter_view.name
    end

    test "saves new assessment_points_filter_view", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/assessment_points_filter_views")

      create_attrs = %{
        name: "some name",
        profile_id: Lanttern.IdentityFixtures.teacher_profile_fixture().id
      }

      assert index_live |> element("a", "New Assessment points filter view") |> render_click() =~
               "New Assessment points filter view"

      assert_patch(index_live, ~p"/admin/assessment_points_filter_views/new")

      assert index_live
             |> form("#assessment_points_filter_view-form",
               assessment_points_filter_view: @invalid_attrs
             )
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#assessment_points_filter_view-form",
               assessment_points_filter_view: create_attrs
             )
             |> render_submit()

      assert_patch(index_live, ~p"/admin/assessment_points_filter_views")

      html = render(index_live)
      assert html =~ "Assessment points filter view created successfully"
      assert html =~ "some name"
    end

    test "updates assessment_points_filter_view in listing", %{
      conn: conn,
      assessment_points_filter_view: assessment_points_filter_view
    } do
      {:ok, index_live, _html} = live(conn, ~p"/admin/assessment_points_filter_views")

      assert index_live
             |> element(
               "#assessment_points_filter_views-#{assessment_points_filter_view.id} a",
               "Edit"
             )
             |> render_click() =~
               "Edit Assessment points filter view"

      assert_patch(
        index_live,
        ~p"/admin/assessment_points_filter_views/#{assessment_points_filter_view}/edit"
      )

      assert index_live
             |> form("#assessment_points_filter_view-form",
               assessment_points_filter_view: @invalid_attrs
             )
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#assessment_points_filter_view-form",
               assessment_points_filter_view: @update_attrs
             )
             |> render_submit()

      assert_patch(index_live, ~p"/admin/assessment_points_filter_views")

      html = render(index_live)
      assert html =~ "Assessment points filter view updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes assessment_points_filter_view in listing", %{
      conn: conn,
      assessment_points_filter_view: assessment_points_filter_view
    } do
      {:ok, index_live, _html} = live(conn, ~p"/admin/assessment_points_filter_views")

      assert index_live
             |> element(
               "#assessment_points_filter_views-#{assessment_points_filter_view.id} a",
               "Delete"
             )
             |> render_click()

      refute has_element?(
               index_live,
               "#assessment_points_filter_views-#{assessment_points_filter_view.id}"
             )
    end
  end

  describe "Show" do
    setup [:create_assessment_points_filter_view]

    test "displays assessment_points_filter_view", %{
      conn: conn,
      assessment_points_filter_view: assessment_points_filter_view
    } do
      {:ok, _show_live, html} =
        live(conn, ~p"/admin/assessment_points_filter_views/#{assessment_points_filter_view}")

      assert html =~ "Show Assessment points filter view"
      assert html =~ assessment_points_filter_view.name
    end

    test "updates assessment_points_filter_view within modal", %{
      conn: conn,
      assessment_points_filter_view: assessment_points_filter_view
    } do
      {:ok, show_live, _html} =
        live(conn, ~p"/admin/assessment_points_filter_views/#{assessment_points_filter_view}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Assessment points filter view"

      assert_patch(
        show_live,
        ~p"/admin/assessment_points_filter_views/#{assessment_points_filter_view}/show/edit"
      )

      assert show_live
             |> form("#assessment_points_filter_view-form",
               assessment_points_filter_view: @invalid_attrs
             )
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#assessment_points_filter_view-form",
               assessment_points_filter_view: @update_attrs
             )
             |> render_submit()

      assert_patch(
        show_live,
        ~p"/admin/assessment_points_filter_views/#{assessment_points_filter_view}"
      )

      html = render(show_live)
      assert html =~ "Assessment points filter view updated successfully"
      assert html =~ "some updated name"
    end
  end
end
