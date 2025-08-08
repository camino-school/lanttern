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

      archived =
        insert(:message, %{
          school: school,
          name: "archived message abc",
          description: "archived message desc abc",
          archived_at: DateTime.utc_now()
        })

      m2 = insert(:message, %{school: school})

      Lanttern.Filters.set_profile_current_filters(ctx.user, %{classes_ids: [class.id]})

      ctx.conn
      |> visit("/school/message_board")
      |> assert_has("h1", text: "Message board admin")
      |> refute_has("h3", text: message.name)
      |> assert_has("h3", text: m2.name)
      |> assert_has("button", text: class.name)
      |> refute_has("h3", text: archived.name)
    end

    test "create a new message", ctx do
      %{conn: conn} = set_user_permissions(["communication_management"], ctx)
      attr = %{name: "test message", description: "test description", color: "CBCBCB"}

      conn
      |> visit("/school/message_board")
      |> assert_has("h1", text: "Message board admin")
      |> click_link("Add new message")
      |> fill_in("Message title", with: attr.name)
      |> fill_in("Description", with: attr.description)
      |> fill_in("Message color", with: attr.color)
      |> click_button("Save")

      conn
      |> visit("/school/message_board")
      |> assert_has("h3", text: attr.name)
    end

    test "prevent user w/o permission to create a message", ctx do
      section = insert(:section)

      ctx.conn
      |> visit("/school/message_board?new=true&section_id=#{section.id}")
      |> refute_has("h2", text: "New message")
    end

    test "edit a existing message", ctx do
      %{conn: conn} = set_user_permissions(["communication_management"], ctx)
      message = insert(:message, %{school: ctx.user.current_profile.staff_member.school})
      attrs = %{name: "edited name"}

      conn
      |> visit("/school/message_board")
      |> assert_has("h3", text: message.name)
      |> click_link("#message-#{message.id} a", "Edit")
      |> fill_in("Message title", with: attrs.name)
      |> click_button("Save")

      conn
      |> visit("/school/message_board")
      |> assert_has("h3", text: attrs.name)
    end

    test "prevent user w/o permission to edit a message", ctx do
      message = insert(:message, %{name: "message from other school"})

      ctx.conn
      |> visit("/school/message_board?edit=#{message.id}")
      |> refute_has("h2", text: "Edit message")
    end
  end
end
