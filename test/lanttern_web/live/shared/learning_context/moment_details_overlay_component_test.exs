defmodule LantternWeb.MomentDetailsOverlayComponentTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  @live_view_base_path "/strands"

  setup [:register_and_log_in_staff_member]

  describe "Moment details overlay" do
    test "open overlay by clicking moment name", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand, name: "moment abc")

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> click_button(moment.name)
      |> assert_has("#moment-details-overlay h1", text: "moment abc")
    end

    test "add description when moment has none", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> click_button(moment.name)
      |> click_button("Add description")
      |> fill_in("Moment description", with: "New description abc")
      |> click_button("#moment-description-form button", "Save")
      |> assert_has("p", text: "New description abc")
    end

    test "edit existing description", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand, description: "Old description abc")

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}")
      |> click_button(moment.name)
      |> click_button("Edit description")
      |> fill_in("Moment description", with: "Updated description xyz")
      |> click_button("#moment-description-form button", "Save")
      |> assert_has("p", text: "Updated description xyz")
    end
  end
end
