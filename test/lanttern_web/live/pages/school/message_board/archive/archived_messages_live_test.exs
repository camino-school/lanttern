defmodule LantternWeb.ArchivedMessagesLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory

  alias Lanttern.MessageBoard
  alias Lanttern.Schools

  @live_view_path "/school/message_board/archive"

  setup [:register_and_log_in_staff_member]

  describe "Archived message board" do
    test "list archived messages", %{conn: conn, user: user} do
      # school_id = user.current_profile.school_id
      school = Schools.get_school!(user.current_profile.school_id)
      section = insert(:section, %{school: school})

      message =
        insert(:message, %{
          school: school,
          section: section,
          name: "not archived message abc",
          description: "not archived message desc abc"
        })

      # message =
      #   MessageBoardFixtures.message_fixture(%{
      #     school_id: school_id,
      #     name: "not archived message abc",
      #     description: "not archived message desc abc"
      #   })

      # MessageBoardFixtures.message_fixture(%{
      #   school_id: school_id,
      #   name: "archived message abc",
      #   description: "archived message desc abc"
      # })
      {:ok, archived} =
        insert(:message, %{
          school: school,
          section: section,
          name: "archived message abc",
          description: "archived message desc abc"
        })
        |> MessageBoard.archive_message()

      {:ok, view, _html} = live(conn, @live_view_path)

      refute view |> has_element?("h5", message.name)
      refute view |> has_element?("p", message.description)

      assert view |> has_element?("h5", archived.name)
      assert view |> has_element?("p", archived.description)
    end

    test "display unarchive and delete buttons to communication manager", context do
      %{conn: conn, user: user} = set_user_permissions(["communication_management"], context)

      school = Schools.get_school!(user.current_profile.school_id)
      section = insert(:section, %{school: school})

      # school_id = user.current_profile.school_id

      {:ok, _message} =
        insert(:message, %{
          school: school,
          section: section
        })
        # |> MessageBoard.archive_message()
        # MessageBoardFixtures.message_fixture(%{school_id: school_id})
        |> MessageBoard.archive_message()

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("button", "Unarchive")
      assert view |> has_element?("button", "Delete")
    end

    test "hide unarchive and delete buttons when not communication manager", %{
      conn: conn,
      user: user
    } do
      school = Schools.get_school!(user.current_profile.school_id)
      section = insert(:section, %{school: school})

      # school_id = user.current_profile.school_id

      {:ok, _message} =
        insert(:message, %{
          school: school,
          section: section
        })
        # |> MessageBoard.archive_message()
        # MessageBoardFixtures.message_fixture(%{school_id: school_id})
        |> MessageBoard.archive_message()

      {:ok, view, _html} = live(conn, @live_view_path)

      refute view |> has_element?("button", "Unarchive")
      refute view |> has_element?("button", "Delete")
    end
  end
end
