defmodule LantternWeb.MessageBoard.IndexLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  setup [:register_and_log_in_staff_member]

  describe "Message board view basic navigation" do
    test "list only filter classes", ctx do
      school = ctx.user.current_profile.staff_member.school
      cycle = ctx.user.current_profile.current_school_cycle
      class = insert(:class, %{school: school, cycle: cycle})
      attrs = %{school: school, send_to: "classes", classes_ids: [class.id]}

      message = insert(:message, attrs)
      m2 = insert(:message, %{school: school})

      Lanttern.Filters.set_profile_current_filters(ctx.user, %{classes_ids: [class.id]})

      ctx.conn
      |> visit("/school/message_board_v2")
      |> assert_has("h1", text: "Message board admin")
      |> refute_has("h3", text: message.name)
      |> assert_has("h3", text: m2.name)
      |> assert_has("button", text: class.name)
    end
  end
end
