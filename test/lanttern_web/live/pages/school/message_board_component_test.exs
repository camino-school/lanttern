defmodule LantternWeb.SchoolLive.MessageBoardComponentTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory

  alias Lanttern.MessageBoard
  alias Lanttern.MessageBoardFixtures

  @live_view_path "/school/message_board"

  setup [:register_and_log_in_staff_member]

  describe "Message board" do
    test "list messages", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id

      message =
        insert(:message, %{
          school: user.current_profile.staff_member.school,
          inserted_at: ~N[2025-05-19 13:27:42],
          updated_at: ~N[2025-05-19 14:00:00]
        })

      {:ok, archived} =
        MessageBoardFixtures.message_fixture(%{
          school_id: school_id,
          name: "archived message abc",
          description: "archived message desc abc"
        })
        |> MessageBoard.archive_message()

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("h5", message.name)
      assert view |> has_element?("p", message.description)
      assert render(view) =~ "May 19, 2025, 10:27"
      assert render(view) =~ "Updated May 19, 2025, 11:00"

      refute view |> has_element?("h5", archived.name)
      refute view |> has_element?("p", archived.description)
    end

    test "allow user with communication management permissions to create message", context do
      %{conn: conn} = set_user_permissions(["communication_management"], context)

      {:ok, view, _html} = live(conn, "#{@live_view_path}?new=true")

      assert view |> has_element?("#message-form-overlay h2", "New message")
    end

    test "prevent user without communication management permissions to create message", ctx do
      {:ok, view, _html} = live(ctx.conn, "#{@live_view_path}?new=true")

      refute view |> has_element?("#message-form-overlay h2", "New message")
    end

    test "allow user with communication management permissions to edit message", context do
      %{conn: conn, user: user} = set_user_permissions(["communication_management"], context)
      school_id = user.current_profile.school_id

      message =
        MessageBoardFixtures.message_fixture(%{school_id: school_id, name: "message abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_path}?edit=#{message.id}")

      assert view |> has_element?("#message-form-overlay h2", "Edit message")
    end

    test "prevent user without communication management permissions to edit message", ctx do
      school_id = ctx.user.current_profile.school_id

      message =
        MessageBoardFixtures.message_fixture(%{school_id: school_id, name: "message abc"})

      {:ok, view, _html} = live(ctx.conn, "#{@live_view_path}?edit=#{message.id}")

      refute view |> has_element?("#message-form-overlay h2", "Edit message")
    end

    test "prevent user to edit message from other schools", context do
      %{conn: conn} = set_user_permissions(["communication_management"], context)

      message =
        MessageBoardFixtures.message_fixture(%{name: "message from other school"})

      {:ok, view, _html} = live(conn, "#{@live_view_path}?edit=#{message.id}")

      refute view |> has_element?("#message-form-overlay h2", "Edit message")
    end
  end
end
