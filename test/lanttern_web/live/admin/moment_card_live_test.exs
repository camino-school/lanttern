defmodule LantternWeb.Admin.MomentCardLiveTest do
  use LantternWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lanttern.LearningContextFixtures

  @update_attrs %{
    name: "some updated name",
    position: 43,
    description: "some updated description"
  }
  @invalid_attrs %{name: nil, position: nil, description: nil}

  defp create_moment_card(_) do
    moment_card = moment_card_fixture()
    %{moment_card: moment_card}
  end

  setup :register_and_log_in_root_admin

  describe "Index" do
    setup [:create_moment_card]

    test "lists all moment_cards", %{conn: conn, moment_card: moment_card} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/moment_cards")

      assert html =~ "Listing Moment cards"
      assert html =~ moment_card.name
    end

    test "saves new moment_card", %{conn: conn} do
      moment = Lanttern.LearningContextFixtures.moment_fixture()

      {:ok, index_live, _html} = live(conn, ~p"/admin/moment_cards")

      assert index_live |> element("a", "New Moment card") |> render_click() =~
               "New Moment card"

      assert_patch(index_live, ~p"/admin/moment_cards/new")

      assert index_live
             |> form("#moment-card-form", moment_card: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      create_attrs = %{
        name: "some name",
        position: 42,
        description: "some description",
        moment_id: moment.id
      }

      assert index_live
             |> form("#moment-card-form", moment_card: create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/moment_cards")

      html = render(index_live)
      assert html =~ "Moment card created successfully"
      assert html =~ "some name"
    end

    test "updates moment_card in listing", %{conn: conn, moment_card: moment_card} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/moment_cards")

      assert index_live |> element("#moment_cards-#{moment_card.id} a", "Edit") |> render_click() =~
               "Edit Moment card"

      assert_patch(index_live, ~p"/admin/moment_cards/#{moment_card}/edit")

      assert index_live
             |> form("#moment-card-form", moment_card: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#moment-card-form", moment_card: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/moment_cards")

      html = render(index_live)
      assert html =~ "Moment card updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes moment_card in listing", %{conn: conn, moment_card: moment_card} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/moment_cards")

      assert index_live
             |> element("#moment_cards-#{moment_card.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#moment_cards-#{moment_card.id}")
    end
  end

  describe "Show" do
    setup [:create_moment_card]

    test "displays moment_card", %{conn: conn, moment_card: moment_card} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/moment_cards/#{moment_card}")

      assert html =~ "Show Moment card"
      assert html =~ moment_card.name
    end

    test "updates moment_card within modal", %{conn: conn, moment_card: moment_card} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/moment_cards/#{moment_card}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Moment card"

      assert_patch(show_live, ~p"/admin/moment_cards/#{moment_card}/show/edit")

      assert show_live
             |> form("#moment-card-form", moment_card: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#moment-card-form", moment_card: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/moment_cards/#{moment_card}")

      html = render(show_live)
      assert html =~ "Moment card updated successfully"
      assert html =~ "some updated name"
    end
  end
end
