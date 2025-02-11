defmodule Lanttern.MessageBoardTest do
  use Lanttern.DataCase

  alias Lanttern.MessageBoard

  describe "board_messages" do
    alias Lanttern.MessageBoard.Message

    import Lanttern.MessageBoardFixtures

    @invalid_attrs %{name: nil, description: nil, send_to: nil, archived_at: nil}

    test "list_board_messages/0 returns all board_messages" do
      message = message_fixture()
      assert MessageBoard.list_board_messages() == [message]
    end

    test "get_message!/1 returns the message with given id" do
      message = message_fixture()
      assert MessageBoard.get_message!(message.id) == message
    end

    test "create_message/1 with valid data creates a message" do
      school = Lanttern.SchoolsFixtures.school_fixture()

      valid_attrs = %{
        name: "some name",
        description: "some description",
        send_to: "classes",
        school_id: school.id,
        archived_at: ~U[2025-02-10 11:27:00Z]
      }

      assert {:ok, %Message{} = message} = MessageBoard.create_message(valid_attrs)
      assert message.name == "some name"
      assert message.description == "some description"
      assert message.send_to == "classes"
      assert message.school_id == school.id
      assert message.archived_at == ~U[2025-02-10 11:27:00Z]
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = MessageBoard.create_message(@invalid_attrs)
    end

    test "update_message/2 with valid data updates the message" do
      message = message_fixture()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        send_to: "classes",
        archived_at: ~U[2025-02-11 11:27:00Z]
      }

      assert {:ok, %Message{} = message} = MessageBoard.update_message(message, update_attrs)
      assert message.name == "some updated name"
      assert message.description == "some updated description"
      assert message.send_to == "classes"
      assert message.archived_at == ~U[2025-02-11 11:27:00Z]
    end

    test "update_message/2 with invalid data returns error changeset" do
      message = message_fixture()
      assert {:error, %Ecto.Changeset{}} = MessageBoard.update_message(message, @invalid_attrs)
      assert message == MessageBoard.get_message!(message.id)
    end

    test "delete_message/1 deletes the message" do
      message = message_fixture()
      assert {:ok, %Message{}} = MessageBoard.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> MessageBoard.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset" do
      message = message_fixture()
      assert %Ecto.Changeset{} = MessageBoard.change_message(message)
    end
  end
end
