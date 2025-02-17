defmodule LantternWeb.MomentLive.CardsComponentTest do
  use LantternWeb.ConnCase

  alias Lanttern.LearningContextFixtures

  @live_view_base_path "/strands/moment"

  setup [:register_and_log_in_staff_member]

  describe "Moment cards" do
    test "display existing moment cards", %{conn: conn} do
      moment = LearningContextFixtures.moment_fixture()

      _moment_card =
        LearningContextFixtures.moment_card_fixture(%{
          moment_id: moment.id,
          name: "some card name abc",
          description: "some card description abc"
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{moment.id}/cards")
      assert view |> has_element?("h5", "some card name abc")
      assert view |> has_element?("p", "some card description abc")
    end

    test "create card", %{conn: conn} do
      moment = LearningContextFixtures.moment_fixture()

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{moment.id}/cards")

      assert view |> has_element?("p", "No cards for this moment yet")

      view |> element("a", "New moment card") |> render_click()

      assert_patch(view, "#{@live_view_base_path}/#{moment.id}/cards?new=true")

      attrs =
        %{
          "name" => "new moment card",
          "description" => "card description abc"
        }

      assert view
             |> form("#moment-card-form", moment_card: attrs)
             |> render_submit()

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{moment.id}/cards")
      assert view |> has_element?("h5", "new moment card")
      assert view |> has_element?("p", "card description abc")
    end

    test "update card", %{conn: conn} do
      moment = LearningContextFixtures.moment_fixture()

      moment_card =
        LearningContextFixtures.moment_card_fixture(%{
          moment_id: moment.id,
          name: "some card name abc",
          description: "some card description abc"
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{moment.id}/cards")
      assert view |> has_element?("h5", "some card name abc")
      assert view |> has_element?("p", "some card description abc")

      view |> element("#moment_cards-#{moment_card.id} a", moment_card.name) |> render_click()

      assert_patch(
        view,
        "#{@live_view_base_path}/#{moment.id}/cards?moment_card_id=#{moment_card.id}"
      )

      view |> element("#moment-card-overlay button", "Edit card") |> render_click()

      attrs =
        %{
          "name" => "updated moment card",
          "description" => "card description xyz"
        }

      assert view
             |> form("#moment-card-form", moment_card: attrs)
             |> render_submit()

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{moment.id}/cards")
      assert view |> has_element?("h5", "updated moment card")
      assert view |> has_element?("p", "card description xyz")
      refute view |> has_element?("h5", "some card name abc")
      refute view |> has_element?("p", "some card description abc")
    end

    test "delete card", %{conn: conn} do
      moment = LearningContextFixtures.moment_fixture()

      moment_card =
        LearningContextFixtures.moment_card_fixture(%{
          moment_id: moment.id,
          name: "some card name abc"
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{moment.id}/cards")
      assert view |> has_element?("h5", "some card name abc")

      view |> element("#moment_cards-#{moment_card.id} a", moment_card.name) |> render_click()

      assert_patch(
        view,
        "#{@live_view_base_path}/#{moment.id}/cards?moment_card_id=#{moment_card.id}"
      )

      view |> element("#moment-card-overlay button", "Delete") |> render_click()

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{moment.id}/cards")
      assert view |> has_element?("p", "No cards for this moment yet")
    end
  end
end
