defmodule LantternWeb.RubricLiveTest do
  use LantternWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lanttern.RubricsFixtures

  @update_attrs %{criteria: "some updated criteria", is_differentiation: false}
  @invalid_attrs %{criteria: nil, is_differentiation: false}

  defp create_rubric(_) do
    rubric = rubric_fixture()
    %{rubric: rubric}
  end

  setup :register_and_log_in_root_admin

  describe "Index" do
    setup [:create_rubric]

    test "lists all rubrics", %{conn: conn, rubric: rubric} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/rubrics")

      assert html =~ "Listing Rubrics"
      assert html =~ rubric.criteria
    end

    test "saves new rubric", %{conn: conn} do
      scale = Lanttern.GradingFixtures.scale_fixture()

      {:ok, index_live, _html} = live(conn, ~p"/admin/rubrics")

      assert index_live |> element("a", "New Rubric") |> render_click() =~
               "New Rubric"

      assert_patch(index_live, ~p"/admin/rubrics/new")

      assert index_live
             |> form("#rubric-form", rubric: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      create_attrs = %{
        criteria: "some criteria",
        scale_id: scale.id,
        is_differentiation: true
      }

      assert index_live
             |> form("#rubric-form", rubric: create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/rubrics")

      html = render(index_live)
      assert html =~ "Rubric created successfully"
      assert html =~ "some criteria"
    end

    test "updates rubric in listing", %{conn: conn, rubric: rubric} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/rubrics")

      assert index_live |> element("#rubrics-#{rubric.id} a", "Edit") |> render_click() =~
               "Edit Rubric"

      assert_patch(index_live, ~p"/admin/rubrics/#{rubric}/edit")

      assert index_live
             |> form("#rubric-form", rubric: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#rubric-form", rubric: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/rubrics")

      html = render(index_live)
      assert html =~ "Rubric updated successfully"
      assert html =~ "some updated criteria"
    end

    test "deletes rubric in listing", %{conn: conn, rubric: rubric} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/rubrics")

      assert index_live |> element("#rubrics-#{rubric.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#rubrics-#{rubric.id}")
    end
  end

  describe "Show" do
    setup [:create_rubric]

    test "displays rubric", %{conn: conn, rubric: rubric} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/rubrics/#{rubric}")

      assert html =~ "Show Rubric"
      assert html =~ rubric.criteria
    end

    test "updates rubric within modal", %{conn: conn, rubric: rubric} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/rubrics/#{rubric}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Rubric"

      assert_patch(show_live, ~p"/admin/rubrics/#{rubric}/show/edit")

      assert show_live
             |> form("#rubric-form", rubric: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#rubric-form", rubric: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/rubrics/#{rubric}")

      html = render(show_live)
      assert html =~ "Rubric updated successfully"
      assert html =~ "some updated criteria"
    end
  end
end
