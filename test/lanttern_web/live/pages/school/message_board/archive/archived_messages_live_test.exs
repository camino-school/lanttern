defmodule LantternWeb.ArchivedMessagesLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.MessageBoardFixtures

  @live_view_path "/school/message_board/archive"

  setup [:register_and_log_in_staff_member]

  describe "Archived message board" do
    test "list archived messages", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id

      message =
        MessageBoardFixtures.message_fixture(%{
          school_id: school_id,
          name: "not archived message abc",
          description: "not archived message desc abc"
        })

      archived =
        MessageBoardFixtures.message_fixture(%{
          school_id: school_id,
          name: "archived message abc",
          description: "archived message desc abc",
          archived_at: DateTime.utc_now()
        })

      {:ok, view, _html} = live(conn, @live_view_path)

      refute view |> has_element?("h5", message.name)
      refute view |> has_element?("p", message.description)

      assert view |> has_element?("h5", archived.name)
      assert view |> has_element?("p", archived.description)
    end

    test "display unarchive and delete buttons to communication manager", context do
      %{conn: conn, user: user} = set_user_permissions(["communication_management"], context)

      school_id = user.current_profile.school_id

      _message =
        MessageBoardFixtures.message_fixture(%{
          school_id: school_id,
          archived_at: DateTime.utc_now()
        })

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("button", "Unarchive")
      assert view |> has_element?("button", "Delete")
    end

    test "hide unarchive and delete buttons when not communication manager", %{
      conn: conn,
      user: user
    } do
      school_id = user.current_profile.school_id

      _message =
        MessageBoardFixtures.message_fixture(%{
          school_id: school_id,
          archived_at: DateTime.utc_now()
        })

      {:ok, view, _html} = live(conn, @live_view_path)

      refute view |> has_element?("button", "Unarchive")
      refute view |> has_element?("button", "Delete")
    end
  end
end
