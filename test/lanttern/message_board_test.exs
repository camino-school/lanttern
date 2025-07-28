defmodule Lanttern.MessageBoardTest do
  use Lanttern.DataCase

  alias Lanttern.Repo

  alias Lanttern.MessageBoard

  import Lanttern.Factory

  describe "board_messages" do
    alias Lanttern.MessageBoard.Message

    import Lanttern.MessageBoardFixtures

    alias Lanttern.SchoolsFixtures

    @invalid_attrs %{name: nil, description: nil, send_to: nil}

    test "list_messages/1 returns all board_messages (pinned first. archived not included)" do
      message = message_fixture()
      {:ok, _archived} = message_fixture() |> MessageBoard.archive_message()

      # wait 1 second to test ordering by inserted_at
      Process.sleep(1000)
      pinned = message_fixture(%{is_pinned: true})

      assert MessageBoard.list_messages() == [pinned, message]
    end

    test "list_messages/1 with archived opt returns all archived board messages" do
      _message = message_fixture()
      {:ok, archived} = message_fixture() |> MessageBoard.archive_message()

      assert MessageBoard.list_messages(archived: true) == [archived]
    end

    test "list_messages/1 with school_id opt returns all board_messages filtered by given school" do
      school = SchoolsFixtures.school_fixture()
      message = message_fixture(%{school_id: school.id})

      # other fixtures for filtering assertion
      message_fixture()

      assert MessageBoard.list_messages(school_id: school.id) == [message]
    end

    test "list_messages/1 with classes_ids opt returns all board_messages filtered by given classes" do
      class = SchoolsFixtures.class_fixture()

      message =
        message_fixture(%{
          send_to: "classes",
          school_id: class.school_id,
          classes_ids: [class.id]
        })

      # wait 1 second to test ordering by inserted_at
      Process.sleep(1000)

      # school messages should be included in the list
      school_message =
        message_fixture(%{
          send_to: "school",
          school_id: class.school_id
        })

      # other fixtures for filtering assertion
      another_class = SchoolsFixtures.class_fixture(%{school_id: class.school_id})

      message_fixture(%{
        send_to: "classes",
        school_id: class.school_id,
        classes_ids: [another_class.id]
      })

      message_fixture()

      assert [expected_school_message, expected_message] =
               MessageBoard.list_messages(school_id: class.school_id, classes_ids: [class.id])

      assert expected_message.id == message.id
      assert expected_school_message.id == school_message.id
    end

    test "list_student_messages/1 returns all messages relevant to the student" do
      school = SchoolsFixtures.school_fixture()
      class = SchoolsFixtures.class_fixture(%{school_id: school.id})
      student = SchoolsFixtures.student_fixture(%{school_id: school.id, classes_ids: [class.id]})

      school_message =
        message_fixture(%{
          send_to: "school",
          school_id: class.school_id
        })

      # wait 1 second to test ordering by inserted_at
      Process.sleep(1000)

      class_message =
        message_fixture(%{
          send_to: "classes",
          school_id: class.school_id,
          classes_ids: [class.id]
        })

      # expect pinned messages first
      pinned_message =
        message_fixture(%{
          send_to: "classes",
          school_id: class.school_id,
          classes_ids: [class.id],
          is_pinned: true
        })

      # other fixtures for filtering assertion
      another_class = SchoolsFixtures.class_fixture(%{school_id: class.school_id})

      message_fixture(%{
        send_to: "classes",
        school_id: class.school_id,
        classes_ids: [another_class.id]
      })

      message_fixture(%{
        send_to: "classes",
        school_id: class.school_id,
        classes_ids: [class.id]
      })
      |> MessageBoard.archive_message()

      message_fixture()

      assert [expected_pinned_message, expected_class_message, expected_school_message] =
               MessageBoard.list_student_messages(student)

      assert expected_pinned_message.id == pinned_message.id
      assert expected_class_message.id == class_message.id
      assert expected_school_message.id == school_message.id
    end

    test "get_message!/1 returns the message with given id" do
      message = message_fixture()
      assert MessageBoard.get_message!(message.id) == message
    end

    test "create_message/1 with valid data creates a school message" do
      school = Lanttern.SchoolsFixtures.school_fixture()

      valid_attrs = %{
        name: "some name",
        description: "some description",
        send_to: "school",
        school_id: school.id
      }

      assert {:ok, %Message{} = message} = MessageBoard.create_message(valid_attrs)
      assert message.name == "some name"
      assert message.description == "some description"
      assert message.send_to == "school"
      assert message.school_id == school.id
    end

    test "create_message/1 with valid data creates a class message" do
      school = Lanttern.SchoolsFixtures.school_fixture()
      class = Lanttern.SchoolsFixtures.class_fixture(%{school_id: school.id})

      valid_attrs = %{
        name: "some name",
        description: "some description",
        send_to: "classes",
        school_id: school.id,
        classes_ids: [class.id]
      }

      assert {:ok, %Message{} = message} = MessageBoard.create_message(valid_attrs)
      assert message.name == "some name"
      assert message.description == "some description"
      assert message.send_to == "classes"
      assert message.school_id == school.id

      message = message |> Repo.preload(:classes)
      assert message.classes == [class]
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = MessageBoard.create_message(@invalid_attrs)
    end

    test "update_message/2 with valid data updates the message" do
      message = message_fixture() |> Repo.preload(:message_classes)

      update_attrs = %{
        name: "some updated name",
        description: "some updated description"
      }

      assert {:ok, %Message{} = message} = MessageBoard.update_message(message, update_attrs)
      assert message.name == "some updated name"
      assert message.description == "some updated description"
    end

    test "update_message/2 with invalid data returns error changeset" do
      message = message_fixture() |> Repo.preload(:message_classes)
      assert {:error, %Ecto.Changeset{}} = MessageBoard.update_message(message, @invalid_attrs)
      assert message == MessageBoard.get_message!(message.id) |> Repo.preload(:message_classes)
    end

    test "archive_message/1 sets archived_at for given message" do
      message = message_fixture()

      assert {:ok, %Message{archived_at: %DateTime{}}} =
               MessageBoard.archive_message(message)
    end

    test "unarchive_message/1 sets archived_at to nil for given message" do
      message = message_fixture(%{archived_at: DateTime.utc_now()})

      assert {:ok, %Message{archived_at: nil}} =
               MessageBoard.unarchive_message(message)
    end

    test "delete_message/1 deletes the message" do
      message = message_fixture()
      assert {:ok, %Message{}} = MessageBoard.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> MessageBoard.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset" do
      message = message_fixture() |> Repo.preload(:message_classes)
      assert %Ecto.Changeset{} = MessageBoard.change_message(message)
    end
  end

  describe "card_sections" do
    alias Lanttern.MessageBoard.CardSection

    import Lanttern.MessageBoardFixtures

    @invalid_attrs %{name: nil}

    test "list_card_sections/0 returns all card_sections" do
      card_section = insert(:card_section)
      [expected] = MessageBoard.list_card_sections()
      assert expected.id == card_section.id
    end

    test "get_card_section!/1 returns the card_section with given id" do
      card_section = insert(:card_section)
      assert MessageBoard.get_card_section!(card_section.id) == card_section
    end

    test "create_card_section/1 with valid data creates a card_section" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %CardSection{} = card_section} = MessageBoard.create_card_section(valid_attrs)
      assert card_section.name == "some name"
    end

    test "create_card_section/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = MessageBoard.create_card_section(@invalid_attrs)
    end

    test "update_card_section/2 with valid data updates the card_section" do
      card_section = insert(:card_section)
      update_attrs = %{name: "some updated name"}

      assert {:ok, %CardSection{} = card_section} =
               MessageBoard.update_card_section(card_section, update_attrs)

      assert card_section.name == "some updated name"
    end

    test "update_card_section/2 with invalid data returns error changeset" do
      card_section = insert(:card_section)

      assert {:error, %Ecto.Changeset{}} =
               MessageBoard.update_card_section(card_section, @invalid_attrs)

      assert card_section == MessageBoard.get_card_section!(card_section.id)
    end

    test "delete_card_section/1 deletes the card_section" do
      card_section = insert(:card_section)
      assert {:ok, %CardSection{}} = MessageBoard.delete_card_section(card_section)
      assert_raise Ecto.NoResultsError, fn -> MessageBoard.get_card_section!(card_section.id) end
    end

    test "change_card_section/1 returns a card_section changeset" do
      card_section = insert(:card_section)
      assert %Ecto.Changeset{} = MessageBoard.change_card_section(card_section)
    end
  end

  describe "card_messages" do
    alias Lanttern.MessageBoard.CardMessage

    import Lanttern.MessageBoardFixtures

    @invalid_attrs %{title: nil, cover: nil, color: nil, subtitle: nil, content: nil}

    test "list_card_messages/0 returns all card_messages" do
      card_message = insert(:card_message)
      [expected] = MessageBoard.list_card_messages()
      assert assert expected.id == card_message.id
    end

    test "get_card_message!/1 returns the card_message with given id" do
      card_message = insert(:card_message)
      expected = MessageBoard.get_card_message!(card_message.id)
      assert expected.id == card_message.id
    end

    test "create_card_message/1 with valid data creates a card_message" do
      valid_attrs = params_with_assocs(:card_message)

      assert {:ok, %CardMessage{} = card_message} = MessageBoard.create_card_message(valid_attrs)
      assert card_message.title == valid_attrs.title
      assert card_message.cover == valid_attrs.cover
      assert card_message.color == valid_attrs.color
      assert card_message.subtitle == valid_attrs.subtitle
      assert card_message.content == valid_attrs.content
    end

    test "create_card_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = MessageBoard.create_card_message(@invalid_attrs)
    end

    test "update_card_message/2 with valid data updates the card_message" do
      card_message = insert(:card_message)

      update_attrs = params_for(:card_message)

      assert {:ok, %CardMessage{} = card_message} =
               MessageBoard.update_card_message(card_message, update_attrs)

      assert card_message.title == update_attrs.title
      assert card_message.cover == update_attrs.cover
      assert card_message.color == update_attrs.color
      assert card_message.subtitle == update_attrs.subtitle
      assert card_message.content == update_attrs.content
    end

    test "update_card_message/2 with invalid data returns error changeset" do
      card_message = insert(:card_message)

      assert {:error, %Ecto.Changeset{}} =
               MessageBoard.update_card_message(card_message, @invalid_attrs)

      expected = MessageBoard.get_card_message!(card_message.id)
      assert expected.id == card_message.id
      assert expected.title == card_message.title
      assert expected.cover == card_message.cover
      assert expected.color == card_message.color
      assert expected.subtitle == card_message.subtitle
      assert expected.content == card_message.content
    end

    test "delete_card_message/1 deletes the card_message" do
      card_message = insert(:card_message)
      assert {:ok, %CardMessage{}} = MessageBoard.delete_card_message(card_message)
      assert_raise Ecto.NoResultsError, fn -> MessageBoard.get_card_message!(card_message.id) end
    end

    test "change_card_message/1 returns a card_message changeset" do
      card_message = insert(:card_message)
      assert %Ecto.Changeset{} = MessageBoard.change_card_message(card_message)
    end
  end
end
