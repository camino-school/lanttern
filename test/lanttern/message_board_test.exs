defmodule Lanttern.MessageBoardTest do
  use Lanttern.DataCase

  alias Lanttern.Attachments.Attachment
  alias Lanttern.MessageBoard
  alias Lanttern.Repo

  import Lanttern.Factory

  describe "messages" do
    alias Lanttern.MessageBoard.Message

    import Lanttern.MessageBoardFixtures

    alias Lanttern.SchoolsFixtures

    @invalid_attrs %{name: nil, description: nil, send_to: nil}

    test "list_messages/1 returns all board_messages (pinned first. archived not included)" do
      message = message_fixture()
      {:ok, _archived} = message_fixture() |> MessageBoard.archive_message()

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
      valid_attrs = params_with_assocs(:message, %{school: school})

      assert {:ok, %Message{} = message} = MessageBoard.create_message(valid_attrs)
      assert message.name == valid_attrs.name
      assert message.description == valid_attrs.description
      assert message.send_to == "school"
      assert message.school_id == school.id
    end

    test "create_message/1 with valid data creates a class message" do
      school = Lanttern.SchoolsFixtures.school_fixture()
      class = Lanttern.SchoolsFixtures.class_fixture(%{school_id: school.id})
      attrs = %{classes_ids: [class.id], school: school, send_to: "classes"}

      valid_attrs = params_with_assocs(:message, attrs)

      assert {:ok, %Message{} = message} = MessageBoard.create_message(valid_attrs)
      assert message.name == valid_attrs.name
      assert message.description == valid_attrs.description
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

  describe "sections" do
    alias Lanttern.MessageBoard.Section

    import Lanttern.MessageBoardFixtures

    @invalid_attrs %{name: nil, position: nil, school_id: nil}

    test "get_section!/1 returns the section with given id" do
      section = insert(:section)
      fetched_section = MessageBoard.get_section!(section.id)

      assert fetched_section.id == section.id
      assert fetched_section.name == section.name
      assert fetched_section.position == section.position
      assert fetched_section.school_id == section.school_id
    end

    test "create_section/1 with valid data creates a section" do
      valid_attrs = params_for(:section)

      assert {:ok, %Section{} = section} = MessageBoard.create_section(valid_attrs)
      assert section.name == valid_attrs.name
      assert section.position == valid_attrs.position
      assert section.school_id == valid_attrs.school_id
    end

    test "create_section/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = MessageBoard.create_section(@invalid_attrs)
    end

    test "update_section/2 with valid data updates the section" do
      section = insert(:section)
      update_attrs = params_for(:section)

      assert {:ok, %Section{} = section} = MessageBoard.update_section(section, update_attrs)
      assert section.name == update_attrs.name
      assert section.position == update_attrs.position
      assert section.school_id == update_attrs.school_id
    end

    test "update_section/2 with invalid data returns error changeset" do
      section = insert(:section)
      original_section = MessageBoard.get_section!(section.id)

      assert {:error, %Ecto.Changeset{}} = MessageBoard.update_section(section, @invalid_attrs)

      updated_section = MessageBoard.get_section!(section.id)
      assert updated_section.name == original_section.name
      assert updated_section.position == original_section.position
      assert updated_section.school_id == original_section.school_id
    end

    test "delete_section/1 deletes the section" do
      section = insert(:section)
      assert {:ok, %Section{}} = MessageBoard.delete_section(section)
      assert_raise Ecto.NoResultsError, fn -> MessageBoard.get_section!(section.id) end
    end

    test "change_section/1 returns a section changeset" do
      section = insert(:section)
      assert %Ecto.Changeset{} = MessageBoard.change_section(section)
    end
  end

  describe "create_message_attachment/3" do
    test "returns ok when valid data" do
      attrs = %{
        "name" => "some name",
        "link" => "https://create-valid.link"
      }

      message = insert(:message)
      profile = insert(:profile)

      assert {:ok, %Attachment{} = subject} =
               MessageBoard.create_message_attachment(profile.id, message.id, attrs)

      assert subject = Lanttern.Repo.preload(subject, :message)

      assert subject.id
      assert subject.owner_id == profile.id
      assert subject.message.id == message.id
    end
  end
end
