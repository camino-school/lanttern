defmodule LantternWeb.Admin.CycleLiveTest do
  use LantternWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lanttern.SchoolsFixtures

  @invalid_attrs %{name: nil, start_at: nil, end_at: nil}

  defp create_cycle(_) do
    cycle = cycle_fixture()
    %{cycle: cycle}
  end

  setup :register_and_log_in_root_admin

  describe "Index" do
    setup [:create_cycle]

    test "lists all school_cycles", %{conn: conn, cycle: cycle} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/school_cycles")

      assert html =~ "Listing School cycles"
      assert html =~ cycle.name
    end

    test "saves new cycle", %{conn: conn} do
      school = school_fixture()

      create_attrs = %{
        name: "some name",
        start_at: "2023-11-09",
        end_at: "2023-12-09",
        school_id: school.id
      }

      {:ok, index_live, _html} = live(conn, ~p"/admin/school_cycles")

      assert index_live |> element("a", "New Cycle") |> render_click() =~
               "New Cycle"

      assert_patch(index_live, ~p"/admin/school_cycles/new")

      assert index_live
             |> form("#cycle-form", cycle: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#cycle-form", cycle: create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/school_cycles")

      html = render(index_live)
      assert html =~ "Cycle created successfully"
      assert html =~ "some name"
    end

    test "updates cycle in listing", %{conn: conn, cycle: cycle} do
      school = school_fixture()

      update_attrs = %{
        name: "some updated name",
        start_at: "2023-11-10",
        end_at: "2023-12-10",
        school_id: school.id
      }

      {:ok, index_live, _html} = live(conn, ~p"/admin/school_cycles")

      assert index_live |> element("#school_cycles-#{cycle.id} a", "Edit") |> render_click() =~
               "Edit Cycle"

      assert_patch(index_live, ~p"/admin/school_cycles/#{cycle}/edit")

      assert index_live
             |> form("#cycle-form", cycle: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#cycle-form", cycle: update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/school_cycles")

      html = render(index_live)
      assert html =~ "Cycle updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes cycle in listing", %{conn: conn, cycle: cycle} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/school_cycles")

      assert index_live |> element("#school_cycles-#{cycle.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#school_cycles-#{cycle.id}")
    end
  end

  describe "Show" do
    setup [:create_cycle]

    test "displays cycle", %{conn: conn, cycle: cycle} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/school_cycles/#{cycle}")

      assert html =~ "Show Cycle"
      assert html =~ cycle.name
    end

    test "updates cycle within modal", %{conn: conn, cycle: cycle} do
      school = school_fixture()

      update_attrs = %{
        name: "some updated name",
        start_at: "2023-11-10",
        end_at: "2023-12-10",
        school_id: school.id
      }

      {:ok, show_live, _html} = live(conn, ~p"/admin/school_cycles/#{cycle}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Cycle"

      assert_patch(show_live, ~p"/admin/school_cycles/#{cycle}/show/edit")

      assert show_live
             |> form("#cycle-form", cycle: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#cycle-form", cycle: update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/school_cycles/#{cycle}")

      html = render(show_live)
      assert html =~ "Cycle updated successfully"
      assert html =~ "some updated name"
    end
  end
end
