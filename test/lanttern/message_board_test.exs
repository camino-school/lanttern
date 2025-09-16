defmodule Lanttern.MessageBoardTest do
  use Lanttern.DataCase

  alias Lanttern.Attachments.Attachment
  alias Lanttern.MessageBoard
  alias Lanttern.Repo

  import Lanttern.Factory

  describe "messages" do
    alias Lanttern.MessageBoard.Message

    @invalid_attrs %{name: nil, description: nil, send_to: nil}

    test "list_messages/1 returns all board_messages (pinned first. archived not included)" do
      message = insert(:message)
      {:ok, _archived} = insert(:message) |> MessageBoard.archive_message()

      pinned = insert(:message, %{is_pinned: true})

      assert [expected_pinned, expected] =
               MessageBoard.list_messages()

      assert pinned.id == expected_pinned.id
      assert message.id == expected.id
    end

    test "list_messages/1 with archived opt returns all archived board messages" do
      _message = insert(:message)
      {:ok, archived} = insert(:message) |> MessageBoard.archive_message()

      assert [expected] = MessageBoard.list_messages(archived: true)
      assert expected.id == archived.id
    end

    test "list_messages/1 with school_id opt returns all board_messages filtered by given school" do
      school = insert(:school)
      section = insert(:section, %{school: school})

      message = insert(:message, %{school: school, section: section, send_to: "school"})

      # other fixtures for filtering assertion
      insert(:message)

      [expected_message] = MessageBoard.list_messages(school_id: school.id)

      assert expected_message.id == message.id
    end

    test "list_messages/1 with classes_ids opt returns all board_messages filtered by given classes" do
      school = insert(:school)
      cycle = insert(:cycle, %{school: school})
      class = insert(:class, %{school: school, cycle: cycle, name: "Class 1"})
      section = insert(:section, %{school: school})

      message = insert(:message, %{school: school, send_to: "classes"})

      insert(:message_class, %{message: message, class: class, school: school})

      # wait 1 second to test ordering by inserted_at
      Process.sleep(1000)

      # school messages should be included in the list
      school_message =
        insert(:message, %{
          name: "School message",
          section: section,
          school: school,
          send_to: "school"
        })

      Process.sleep(1000)

      # other messages for filtering assertion
      another_class = insert(:class, %{school: school, cycle: cycle})
      attrs = %{name: "another message", section: section, school: school, send_to: "classes"}
      another_message = insert(:message, attrs)
      insert(:message_class, %{message: another_message, class: another_class, school: school})

      assert [expected_message, expected_school_message, expected_another_message] =
               MessageBoard.list_messages(school_id: school.id)

      assert expected_message.id == message.id
      assert expected_school_message.id == school_message.id
      assert expected_another_message.id == another_message.id

      assert [expected_message, expected_school] =
               MessageBoard.list_messages(school_id: school.id, classes_ids: [class.id])

      assert expected_school.id == school_message.id
      assert expected_message.id == message.id

      assert [expected_school, expected_another] =
               MessageBoard.list_messages(school_id: school.id, classes_ids: [another_class.id])

      assert expected_school.id == school_message.id
      assert expected_another.id == another_message.id
    end

    test "list_student_messages/1 returns all messages relevant to the student" do
      school = insert(:school)
      cycle = insert(:cycle, %{school: school})
      class = insert(:class, %{school: school, cycle: cycle})
      student = insert(:student, %{school: school})

      # Create the association between student and class
      Repo.insert_all("classes_students", [%{class_id: class.id, student_id: student.id}])

      school_message =
        insert(:message, %{
          send_to: "school",
          school: school
        })

      # wait 1 second to test ordering by inserted_at
      Process.sleep(1000)

      class_message =
        insert(:message, %{
          send_to: "classes",
          school: school,
          classes_ids: [class.id]
        })

      insert(:message_class, %{message: class_message, class: class, school: school})

      # expect pinned messages first
      pinned_message =
        insert(:message, %{
          send_to: "classes",
          school: school,
          classes_ids: [class.id],
          is_pinned: true
        })

      insert(:message_class, %{message: pinned_message, class: class, school: school})

      # other fixtures for filtering assertion
      another_class = insert(:class, %{name: "another class", cycle: cycle, school: school})

      another_message =
        insert(:message, %{
          send_to: "classes",
          school: school,
          classes_ids: [another_class.id]
        })

      insert(:message_class, %{message: another_message, class: another_class, school: school})

      insert(:message, %{
        send_to: "classes",
        school: school,
        classes_ids: [class.id]
      })
      |> MessageBoard.archive_message()

      insert(:message)

      assert [expected_pinned_message, expected_class_message, expected_school_message] =
               MessageBoard.list_student_messages(student)

      assert expected_pinned_message.id == pinned_message.id
      assert expected_class_message.id == class_message.id
      assert expected_school_message.id == school_message.id
    end

    test "get_message!/1 returns the message with given id" do
      message = insert(:message)
      assert expected_message = MessageBoard.get_message!(message.id)
      assert expected_message.id == message.id
    end

    test "create_message/1 with valid data creates a school message" do
      school = insert(:school)
      valid_attrs = params_with_assocs(:message, %{school: school})

      assert {:ok, %Message{} = message} = MessageBoard.create_message(valid_attrs)
      assert message.name == valid_attrs.name
      assert message.description == valid_attrs.description
      assert message.send_to == "school"
      assert message.school_id == school.id
    end

    test "create_message/1 with valid data creates a class message" do
      school = insert(:school)
      cycle = insert(:cycle, %{school: school})
      class = insert(:class, %{school: school, cycle: cycle})
      attrs = %{classes_ids: [class.id], school: school, send_to: "classes"}

      valid_attrs = params_with_assocs(:message, attrs)

      assert {:ok, %Message{} = message} = MessageBoard.create_message(valid_attrs)
      assert message.name == valid_attrs.name
      assert message.description == valid_attrs.description
      assert message.send_to == "classes"
      assert message.school_id == school.id

      message = message |> Repo.preload(:classes)
      assert [message_classes] = message.message_classes
      assert message_classes.class_id == class.id
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = MessageBoard.create_message(@invalid_attrs)
    end

    test "update_message/2 with valid data updates the message" do
      message = insert(:message) |> Repo.preload(:message_classes)

      update_attrs = %{
        name: "some updated name",
        description: "some updated description"
      }

      assert {:ok, %Message{} = message} = MessageBoard.update_message(message, update_attrs)
      assert message.name == "some updated name"
      assert message.description == "some updated description"
    end

    test "update_message/2 with invalid data returns error changeset" do
      message = insert(:message) |> Repo.preload(:message_classes)
      assert {:error, %Ecto.Changeset{}} = MessageBoard.update_message(message, @invalid_attrs)

      assert expected_message =
               MessageBoard.get_message!(message.id) |> Repo.preload(:message_classes)

      assert message.id == expected_message.id
    end

    test "archive_message/1 sets archived_at for given message" do
      message = insert(:message)

      assert {:ok, %Message{archived_at: %DateTime{}}} =
               MessageBoard.archive_message(message)
    end

    test "unarchive_message/1 sets archived_at to nil for given message" do
      message = insert(:message, %{archived_at: DateTime.utc_now()})

      assert {:ok, %Message{archived_at: nil}} =
               MessageBoard.unarchive_message(message)
    end

    test "delete_message/1 deletes the message" do
      message = insert(:message)
      assert {:ok, %Message{}} = MessageBoard.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> MessageBoard.get_message!(message.id) end
    end

    test "change_message/1 returns a message changeset" do
      message = insert(:message) |> Repo.preload(:message_classes)
      assert %Ecto.Changeset{} = MessageBoard.change_message(message)
    end
  end

  describe "sections" do
    alias Lanttern.MessageBoard.Section

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
