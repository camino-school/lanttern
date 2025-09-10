defmodule LantternWeb.ArchivedMessagesLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.MessageBoard
  alias Lanttern.Schools

  import Lanttern.Factory

  @live_view_path "/school/message_board/archive"

  setup [:register_and_log_in_staff_member]

  describe "Archived message board" do
    test "list archived messages", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      school = Schools.get_school!(school_id)
      section = insert(:section, %{school: school})

      message = insert(:message, %{
          school: school,
          section: section,
          name: "not archived message abc",
          description: "not archived message desc abc"
        })

      {:ok, archived} =
        insert(:message, %{
          school: school,
          section: section,
          name: "archived message abc",
          description: "archived message desc abc"
        })
        |> MessageBoard.archive_message()

      {:ok, view, _html} = live(conn, @live_view_path)

      refute view |> has_element?("h3", message.name)
      assert view |> has_element?("h3", archived.name)
    end

    test "display unarchive button to communication manager", context do
      %{conn: conn, user: user} = set_user_permissions(["communication_management"], context)

      school_id = user.current_profile.school_id
      school = Schools.get_school!(school_id)
      section = insert(:section, %{school: school})

      {:ok, _message} = insert(:message, %{school: school, section: section})
        |> MessageBoard.archive_message()

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("button[title='Unarchive']")
    end

    test "hide unarchive and delete buttons when not communication manager", %{
      conn: conn,
      user: user
    } do
      school_id = user.current_profile.school_id
      school = Schools.get_school!(school_id)
      section = insert(:section, %{school: school})

      {:ok, _message} =
        insert(:message, %{school: school, section: section})
        |> MessageBoard.archive_message()

      {:ok, view, _html} = live(conn, @live_view_path)

      refute view |> has_element?("button", "Unarchive")
      refute view |> has_element?("button", "Delete")
    end
  end
end
