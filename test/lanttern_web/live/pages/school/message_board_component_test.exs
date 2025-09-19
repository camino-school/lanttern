defmodule LantternWeb.SchoolLive.MessageBoardComponentTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory

  alias Lanttern.MessageBoard
  alias Lanttern.Schools

  @live_view_path "/school/message_board"

  setup [:register_and_log_in_staff_member]

  describe "Message board" do
    test "list messages", %{conn: conn, user: user} do
      school = Schools.get_school!(user.current_profile.school_id)
      section = insert(:section, %{school: school})

      message =
        insert(:message_board, %{
          school: user.current_profile.staff_member.school,
          section: section,
          inserted_at: ~N[2025-05-19 13:27:42],
          updated_at: ~N[2025-05-19 14:00:00]
        })

      {:ok, archived} =
        insert(:message, %{
          name: "archived message abc",
          description: "archived message desc abc",
          school: school,
          section: section,
          send_to: "school",
          inserted_at: ~N[2025-06-19 13:27:42],
          updated_at: ~N[2025-06-19 14:00:00]
        })
        |> MessageBoard.archive_message()

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("h3", message.name)

      refute view |> has_element?("h5", archived.name)
      refute view |> has_element?("p", archived.description)
    end

    test "allow user with communication management permissions to create message", context do
      %{conn: conn, user: user} = set_user_permissions(["communication_management"], context)
      school_id = user.current_profile.school_id
      school = Schools.get_school!(school_id)
      section = insert(:section, %{school: school})

      {:ok, view, _html} = live(conn, "#{@live_view_path}?new=true&section_id=#{section.id}")
      assert view |> has_element?("#message-form-overlay h2", "New message")
    end

    test "prevent user without communication management permissions to create message", ctx do
      {:ok, view, _html} = live(ctx.conn, "#{@live_view_path}?new=true")

      refute view |> has_element?("#message-form-overlay h2", "New message")
    end

    test "allow user with communication management permissions to edit message", context do
      %{conn: conn, user: user} = set_user_permissions(["communication_management"], context)
      school_id = user.current_profile.school_id
      school = Schools.get_school!(school_id)
      section = insert(:section, %{school: school})

      message = insert(:message, %{name: "message abc", school: school, section: section})

      {:ok, view, _html} = live(conn, "#{@live_view_path}?edit=#{message.id}")

      assert view |> has_element?("#message-form-overlay h2", "Edit message")
    end

    test "prevent user without communication management permissions to edit message", ctx do
      school_id = ctx.user.current_profile.school_id
      school = Schools.get_school!(school_id)
      section = insert(:section, %{school: school})

      message = insert(:message, %{name: "message abc", school: school, section: section})

      {:ok, view, _html} = live(ctx.conn, "#{@live_view_path}?edit=#{message.id}")

      refute view |> has_element?("#message-form-overlay h2", "Edit message")
    end

    test "prevent user to edit message from other schools", context do
      %{conn: conn} = set_user_permissions(["communication_management"], context)
      school = insert(:school)
      section = insert(:section, %{school: school})

      message =
        insert(
          :message,
          %{name: "message from other school", school: school, section: section}
        )

      {:ok, view, _html} = live(conn, "#{@live_view_path}?edit=#{message.id}")

      refute view |> has_element?("#message-form-overlay h2", "Edit message")
    end
  end
end
