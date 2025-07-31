defmodule LantternWeb.StudentHomeLiveV2Test do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  @live_view_path "/student_v2"

  setup [:register_and_log_in_student]

  describe "Student home live view basic navigation" do
    test "displays message board and opens message overlay", ctx do
      message = insert(:card_message)

      ctx.conn
      |> visit(@live_view_path)
      |> assert_has("h3", text: message.card_section.name)
      |> assert_has("h3", text: message.title)
      |> click_button("span[phx-click='card_lookout']", "Find out more")
      # |> assert_path("/student_v2?message=#{message.id}")
      |> assert_has("#card-message-overlay-#{message.id}")
      |> assert_has("h1", text: message.title)
      |> assert_has("p", text: message.content)
    end
  end
end
