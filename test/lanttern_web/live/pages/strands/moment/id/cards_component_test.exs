defmodule LantternWeb.MomentLive.CardsComponentTest do
  use LantternWeb.ConnCase

  alias Lanttern.LearningContextFixtures

  @live_view_base_path "/strands/moment"

  setup [:register_and_log_in_teacher]

  describe "Moment cards" do
    test "display existing moment cards", %{conn: conn} do
      moment = LearningContextFixtures.moment_fixture()

      _moment_card =
        LearningContextFixtures.moment_card_fixture(%{
          moment_id: moment.id,
          name: "some card name abc",
          description: "some card description abc"
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{moment.id}?tab=cards")
      assert view |> has_element?("h5", "some card name abc")
      assert view |> has_element?("p", "some card description abc")
    end

    test "create card", %{conn: conn} do
      moment = LearningContextFixtures.moment_fixture()

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{moment.id}?tab=cards")

      assert view |> has_element?("p", "No cards for this moment yet")

      view |> element("button", "Add moment card") |> render_click()

      assert_patch(view, "#{@live_view_base_path}/#{moment.id}/edit_card")

      attrs =
        %{
          "name" => "new moment card",
          "description" => "card description abc",
          "moment_id" => moment.id
        }

      assert view
             |> form("#moment-card-form", moment_card: attrs)
             |> render_submit()

      assert_redirect(view, "#{@live_view_base_path}/#{moment.id}?tab=cards")

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{moment.id}?tab=cards")
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

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{moment.id}?tab=cards")
      assert view |> has_element?("h5", "some card name abc")
      assert view |> has_element?("p", "some card description abc")

      view |> element("#moment-card-#{moment_card.id} button", "Edit") |> render_click()

      assert_patch(view, "#{@live_view_base_path}/#{moment.id}/edit_card")

      attrs =
        %{
          "name" => "updated moment card",
          "description" => "card description xyz",
          "moment_id" => moment.id
        }

      assert view
             |> form("#moment-card-form", moment_card: attrs)
             |> render_submit()

      assert_redirect(view, "#{@live_view_base_path}/#{moment.id}?tab=cards")

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{moment.id}?tab=cards")
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

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{moment.id}?tab=cards")
      assert view |> has_element?("h5", "some card name abc")

      view |> element("#moment-card-#{moment_card.id} button", "Edit") |> render_click()

      assert_patch(view, "#{@live_view_base_path}/#{moment.id}/edit_card")

      view |> element("#moment-card-form-overlay button", "Delete") |> render_click()

      assert_redirect(view, "#{@live_view_base_path}/#{moment.id}?tab=cards")

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{moment.id}?tab=cards")
      assert view |> has_element?("p", "No cards for this moment yet")
    end
  end
end
