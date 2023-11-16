defmodule LantternWeb.Admin.ActivityLiveTest do
  use LantternWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lanttern.LearningContextFixtures

  @update_attrs %{
    name: "some updated name",
    position: 43,
    description: "some updated description"
  }
  @invalid_attrs %{name: nil, position: nil, description: nil}

  defp create_activity(_) do
    activity = activity_fixture()
    %{activity: activity}
  end

  setup :register_and_log_in_root_admin

  describe "Index" do
    setup [:create_activity]

    test "lists all activities", %{conn: conn, activity: activity} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/activities")

      assert html =~ "Listing Activities"
      assert html =~ activity.name
    end

    test "saves new activity", %{conn: conn} do
      strand = strand_fixture()
      {:ok, index_live, _html} = live(conn, ~p"/admin/activities")

      assert index_live |> element("a", "New Activity") |> render_click() =~
               "New Activity"

      assert_patch(index_live, ~p"/admin/activities/new")

      assert index_live
             |> form("#activity-form", activity: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      create_attrs = %{
        name: "some name",
        position: 42,
        description: "some description",
        strand_id: strand.id
      }

      assert index_live
             |> form("#activity-form", activity: create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/activities")

      html = render(index_live)
      assert html =~ "Activity created successfully"
      assert html =~ "some name"
    end

    test "updates activity in listing", %{conn: conn, activity: activity} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/activities")

      assert index_live |> element("#activities-#{activity.id} a", "Edit") |> render_click() =~
               "Edit Activity"

      assert_patch(index_live, ~p"/admin/activities/#{activity}/edit")

      assert index_live
             |> form("#activity-form", activity: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#activity-form", activity: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/activities")

      html = render(index_live)
      assert html =~ "Activity updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes activity in listing", %{conn: conn, activity: activity} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/activities")

      assert index_live |> element("#activities-#{activity.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#activities-#{activity.id}")
    end
  end

  describe "Show" do
    setup [:create_activity]

    test "displays activity", %{conn: conn, activity: activity} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/activities/#{activity}")

      assert html =~ "Show Activity"
      assert html =~ activity.name
    end

    test "updates activity within modal", %{conn: conn, activity: activity} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/activities/#{activity}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Activity"

      assert_patch(show_live, ~p"/admin/activities/#{activity}/show/edit")

      assert show_live
             |> form("#activity-form", activity: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#activity-form", activity: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/activities/#{activity}")

      html = render(show_live)
      assert html =~ "Activity updated successfully"
      assert html =~ "some updated name"
    end
  end
end
