defmodule LantternWeb.StudentHomeLiveV2Test do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  @live_view_path "/student_v2"

  setup [:register_and_log_in_student]

  describe "Student home live view basic navigation" do
    test "displays message board and opens message overlay", ctx do
      message = insert(:message, %{school: ctx.user.current_profile.student.school})

      ctx.conn
      |> visit(@live_view_path)
      |> assert_has("h3", text: message.section.name)
      |> assert_has("h3", text: message.name)
      |> click_button("span[phx-click='card_lookout']", "Find out more")
      # |> assert_path("/student_v2?message=#{message.id}")
      |> assert_has("#card-message-overlay-#{message.id}")
      |> assert_has("h1", text: message.name)
      |> assert_has("p", text: message.description)
    end
  end
end
