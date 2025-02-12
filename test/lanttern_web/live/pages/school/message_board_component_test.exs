defmodule LantternWeb.SchoolLive.MessageBoardComponentTest do
  use LantternWeb.ConnCase

  alias Lanttern.MessageBoardFixtures

  @live_view_path "/school/message_board"

  setup [:register_and_log_in_staff_member]

  describe "Message board" do
    test "list messages", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id

      message =
        MessageBoardFixtures.message_fixture(%{
          school_id: school_id,
          name: "message abc",
          description: "message desc abc"
        })

      archived =
        MessageBoardFixtures.message_fixture(%{
          school_id: school_id,
          name: "archived message abc",
          description: "archived message desc abc",
          archived_at: DateTime.utc_now()
        })

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("h3", message.name)
      assert view |> has_element?("p", message.description)

      refute view |> has_element?("h3", archived.name)
      refute view |> has_element?("p", archived.description)
    end

    test "allow user with communication management permissions to create message", context do
      %{conn: conn} = set_user_permissions(["communication_management"], context)
      {:ok, view, _html} = live(conn, "#{@live_view_path}?new=true")

      assert view |> has_element?("#message-form-overlay h2", "New message")
    end

    test "prevent user without communication management permissions to create message", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, "#{@live_view_path}?new=true")

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

    test "prevent user without communication management permissions to edit message", %{
      conn: conn,
      user: user
    } do
      school_id = user.current_profile.school_id

      message =
        MessageBoardFixtures.message_fixture(%{school_id: school_id, name: "message abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_path}?edit=#{message.id}")

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
