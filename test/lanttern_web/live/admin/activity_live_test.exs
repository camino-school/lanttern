defmodule LantternWeb.Admin.MomentLiveTest do
  use LantternWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lanttern.LearningContextFixtures

  @update_attrs %{
    name: "some updated name",
    position: 43,
    description: "some updated description"
  }
  @invalid_attrs %{name: nil, position: nil, description: nil}

  defp create_moment(_) do
    moment = moment_fixture()
    %{moment: moment}
  end

  setup :register_and_log_in_root_admin

  describe "Index" do
    setup [:create_moment]

    test "lists all moments", %{conn: conn, moment: moment} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/moments")

      assert html =~ "Listing Moments"
      assert html =~ moment.name
    end

    test "saves new moment", %{conn: conn} do
      strand = strand_fixture()
      {:ok, index_live, _html} = live(conn, ~p"/admin/moments")

      assert index_live |> element("a", "New Moment") |> render_click() =~
               "New Moment"

      assert_patch(index_live, ~p"/admin/moments/new")

      assert index_live
             |> form("#moment-form", moment: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      create_attrs = %{
        name: "some name",
        position: 42,
        description: "some description",
        strand_id: strand.id
      }

      assert index_live
             |> form("#moment-form", moment: create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/moments")

      html = render(index_live)
      assert html =~ "Moment created successfully"
      assert html =~ "some name"
    end

    test "updates moment in listing", %{conn: conn, moment: moment} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/moments")

      assert index_live |> element("#moments-#{moment.id} a", "Edit") |> render_click() =~
               "Edit Moment"

      assert_patch(index_live, ~p"/admin/moments/#{moment}/edit")

      assert index_live
             |> form("#moment-form", moment: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#moment-form", moment: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/moments")

      html = render(index_live)
      assert html =~ "Moment updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes moment in listing", %{conn: conn, moment: moment} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/moments")

      assert index_live |> element("#moments-#{moment.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#moments-#{moment.id}")
    end
  end

  describe "Show" do
    setup [:create_moment]

    test "displays moment", %{conn: conn, moment: moment} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/moments/#{moment}")

      assert html =~ "Show Moment"
      assert html =~ moment.name
    end

    test "updates moment within modal", %{conn: conn, moment: moment} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/moments/#{moment}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Moment"

      assert_patch(show_live, ~p"/admin/moments/#{moment}/show/edit")

      assert show_live
             |> form("#moment-form", moment: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#moment-form", moment: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/moments/#{moment}")

      html = render(show_live)
      assert html =~ "Moment updated successfully"
      assert html =~ "some updated name"
    end
  end
end
