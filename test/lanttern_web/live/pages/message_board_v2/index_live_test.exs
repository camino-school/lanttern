defmodule LantternWeb.MessageBoard.IndexLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  setup [:register_and_log_in_staff_member]

  describe "Message board view basic navigation" do
    test "list all messages", ctx do
      message = insert(:message_board, %{school: ctx.user.current_profile.staff_member.school})

      ctx.conn
      |> visit("/school/message_board_v2")
      |> assert_has("h1", text: "Message board admin")
      |> assert_has("h5", text: message.name)
    end

    @tag :skip
    test "list only filter classes", ctx do
      school = ctx.user.current_profile.staff_member.school
      cycle = ctx.user.current_profile.current_school_cycle
      class = insert(:class, %{school: school, cycle: cycle})
      attrs = %{school: school, send_to: "classes", classes_ids: [class.id]}

      message = insert(:message_board, attrs)
      m2 = insert(:message_board, %{school: school})

      ctx.conn
      |> visit("/school/message_board_v2")
      |> assert_has("h1", text: "Message board admin")
      |> assert_has("h5", text: message.name)
      |> refute_has("h5", text: m2.name)
    end
  end
end
