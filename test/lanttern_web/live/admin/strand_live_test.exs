defmodule LantternWeb.Admin.StrandLiveTest do
  use LantternWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lanttern.LearningContextFixtures

  @create_attrs %{
    name: "some name",
    description: "some description",
    subjects_ids: [],
    years_ids: []
  }

  @update_attrs %{
    name: "some updated name",
    description: "some updated description",
    subjects_ids: [],
    years_ids: []
  }

  @invalid_attrs %{
    name: nil,
    description: nil,
    subjects_ids: [],
    years_ids: []
  }

  defp create_strand(_) do
    strand = strand_fixture()
    %{strand: strand}
  end

  setup :register_and_log_in_root_admin

  describe "Index" do
    setup [:create_strand]

    test "lists all strands", %{conn: conn, strand: strand} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/strands")

      assert html =~ "Listing Strands"
      assert html =~ strand.name
    end

    test "saves new strand", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/strands")

      assert index_live |> element("a", "New Strand") |> render_click() =~
               "New Strand"

      assert_patch(index_live, ~p"/admin/strands/new")

      assert index_live
             |> form("#strand-form", strand: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#strand-form", strand: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/strands")

      html = render(index_live)
      assert html =~ "Strand created successfully"
      assert html =~ "some name"
    end

    test "updates strand in listing", %{conn: conn, strand: strand} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/strands")

      assert index_live |> element("#strands-#{strand.id} a", "Edit") |> render_click() =~
               "Edit Strand"

      assert_patch(index_live, ~p"/admin/strands/#{strand}/edit")

      assert index_live
             |> form("#strand-form", strand: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#strand-form", strand: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/strands")

      html = render(index_live)
      assert html =~ "Strand updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes strand in listing", %{conn: conn, strand: strand} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/strands")

      assert index_live |> element("#strands-#{strand.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#strands-#{strand.id}")
    end
  end

  describe "Show" do
    setup [:create_strand]

    test "displays strand", %{conn: conn, strand: strand} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/strands/#{strand}")

      assert html =~ "Show Strand"
      assert html =~ strand.name
    end

    test "updates strand within modal", %{conn: conn, strand: strand} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/strands/#{strand}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Strand"

      assert_patch(show_live, ~p"/admin/strands/#{strand}/show/edit")

      assert show_live
             |> form("#strand-form", strand: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#strand-form", strand: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/strands/#{strand}")

      html = render(show_live)
      assert html =~ "Strand updated successfully"
      assert html =~ "some updated name"
    end
  end
end
