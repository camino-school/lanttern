defmodule Lanttern.MessageBoardV2Test do
  use Lanttern.DataCase

  import Lanttern.Factory

  alias Lanttern.MessageBoard.MessageV2, as: Message
  alias Lanttern.MessageBoard.Section
  alias Lanttern.MessageBoardV2, as: MessageBoard

  describe "sections" do
    @invalid_section_attrs %{name: nil, position: nil, school_id: nil}

    test "list_sections/1 returns all sections ordered by position for a school" do
      school = insert(:school)
      _section1 = insert(:section, school: school, name: "Section A", position: 2)
      _section2 = insert(:section, school: school, name: "Section B", position: 0)
      _section3 = insert(:section, school: school, name: "Section C", position: 1)

      # Section from another school should not be returned
      other_school = insert(:school)
      _other_section = insert(:section, school: other_school, name: "Other Section", position: 0)

      sections = MessageBoard.list_sections(school_id: school.id)

      assert length(sections) == 3
      # Should be ordered by position
      assert Enum.map(sections, &{&1.name, &1.position}) == [
               {"Section B", 0},
               {"Section C", 1},
               {"Section A", 2}
             ]
    end

    test "list_sections/2 returns sections with filtered messages for given classes" do
      school = insert(:school)
      class1 = insert(:class, school: school)
      _class2 = insert(:class, school: school)

      section = insert(:section, school: school)

      # Message sent to school (should be included)
      _message1 =
        insert(:message,
          school: school,
          section: section,
          send_to: :school,
          name: "School message"
        )

      # Message sent to specific classes (should be included when class is filtered)
      {:ok, _message2} =
        MessageBoard.create_message(%{
          school_id: school.id,
          section_id: section.id,
          send_to: :classes,
          name: "Class message",
          description: "Class message description",
          classes_ids: [class1.id]
        })

      # Archived message (should not be included)
      _archived_message =
        insert(:message,
          school: school,
          section: section,
          send_to: :school,
          name: "Archived message",
          archived_at: DateTime.utc_now()
        )

      sections = MessageBoard.list_sections_with_filtered_messages(school.id, [class1.id])
      section = List.first(sections)

      # Should preload only non-archived messages
      assert length(section.messages) == 2
      message_names = Enum.map(section.messages, & &1.name)
      assert "School message" in message_names
      assert "Class message" in message_names
      refute "Archived message" in message_names
    end

    test "get_section!/1 returns the section with given id" do
      section = insert(:section)
      assert MessageBoard.get_section!(section.id).id == section.id
    end

    test "get_section!/1 raises when section does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        MessageBoard.get_section!(999)
      end
    end

    test "get_section/2 with preloads: :messages returns section with ordered messages" do
      section = insert(:section)

      # Create messages with different positions and timestamps
      _message1 =
        insert(:message,
          section: section,
          position: 2,
          name: "Message 1",
          updated_at: ~N[2025-01-01 10:00:00]
        )

      _message2 =
        insert(:message,
          section: section,
          position: 1,
          name: "Message 2",
          updated_at: ~N[2025-01-01 12:00:00]
        )

      _message3 =
        insert(:message,
          section: section,
          position: 1,
          name: "Message 3",
          updated_at: ~N[2025-01-01 11:00:00]
        )

      result = MessageBoard.get_section(section.id, preloads: :messages)

      # Should be ordered by position (asc), then updated_at (desc), then archived_at (asc)
      assert length(result.messages) == 3
      message_names = Enum.map(result.messages, & &1.name)
      assert message_names == ["Message 2", "Message 3", "Message 1"]
    end

    test "create_section/1 with valid data creates a section" do
      school = insert(:school)

      valid_attrs = %{
        name: "Test Section",
        position: 0,
        school_id: school.id
      }

      assert {:ok, %Section{} = section} = MessageBoard.create_section(valid_attrs)
      assert section.name == "Test Section"
      assert section.position == 0
      assert section.school_id == school.id
    end

    test "create_section/1 with invalid data returns error changeset" do
      school = insert(:school)
      invalid_attrs = %{name: nil, position: nil, school_id: school.id}

      assert {:error, %Ecto.Changeset{}} = MessageBoard.create_section(invalid_attrs)
    end

    test "create_section/1 enforces unique constraint on name per school" do
      school = insert(:school)
      insert(:section, name: "Duplicate Name", school: school)

      attrs = %{
        name: "Duplicate Name",
        position: 1,
        school_id: school.id
      }

      assert {:error, %Ecto.Changeset{} = changeset} = MessageBoard.create_section(attrs)
      assert %{name: ["section name must be unique within a school"]} = errors_on(changeset)
    end

    test "update_section/2 with valid data updates the section" do
      section = insert(:section, name: "Original Name")

      update_attrs = %{name: "Updated Name", position: 5}

      assert {:ok, %Section{} = updated_section} =
               MessageBoard.update_section(section, update_attrs)

      assert updated_section.name == "Updated Name"
      assert updated_section.position == 5
    end

    test "update_section/2 with invalid data returns error changeset" do
      section = insert(:section)

      assert {:error, %Ecto.Changeset{}} =
               MessageBoard.update_section(section, @invalid_section_attrs)

      # Section should remain unchanged
      reloaded_section = MessageBoard.get_section!(section.id)
      assert section.name == reloaded_section.name
      assert section.position == reloaded_section.position
    end

    test "delete_section/1 deletes the section" do
      section = insert(:section)
      assert {:ok, %Section{}} = MessageBoard.delete_section(section)
      assert_raise Ecto.NoResultsError, fn -> MessageBoard.get_section!(section.id) end
    end

    test "change_section/2 returns a section changeset" do
      section = insert(:section)
      assert %Ecto.Changeset{} = MessageBoard.change_section(section)
    end

    test "update_section_position/1 updates positions of multiple sections" do
      school = insert(:school)
      section1 = insert(:section, school: school, name: "Section A", position: 0)
      section2 = insert(:section, school: school, name: "Section B", position: 1)
      section3 = insert(:section, school: school, name: "Section C", position: 2)

      # Reorder sections
      reordered_sections = [section3, section1, section2]

      assert :ok = MessageBoard.update_section_position(reordered_sections)

      # Verify positions were updated
      assert MessageBoard.get_section!(section3.id).position == 0
      assert MessageBoard.get_section!(section1.id).position == 1
      assert MessageBoard.get_section!(section2.id).position == 2
    end
  end

  describe "messages" do
    @invalid_message_attrs %{name: nil, description: nil, send_to: nil}

    test "list_messages/1 returns all messages ordered by updated_at and position" do
      school = insert(:school)
      section = insert(:section, school: school)

      message1 =
        insert(:message,
          school: school,
          section: section,
          name: "First Message",
          position: 1,
          inserted_at: ~N[2025-01-01 10:00:00],
          updated_at: ~N[2025-01-01 10:00:00]
        )

      message2 =
        insert(:message,
          school: school,
          section: section,
          name: "Second Message",
          position: 0,
          inserted_at: ~N[2025-01-01 11:00:00],
          updated_at: ~N[2025-01-01 11:00:00]
        )

      messages = MessageBoard.list_messages()

      # Should be ordered by updated_at first, then position
      assert length(messages) == 2
      assert List.first(messages).id == message1.id
      assert List.last(messages).id == message2.id
    end

    test "list_messages/1 with school_id filter returns messages for specific school" do
      school1 = insert(:school)
      school2 = insert(:school)
      section1 = insert(:section, school: school1)
      section2 = insert(:section, school: school2)

      message1 = insert(:message, school: school1, section: section1, name: "School 1 Message")

      _message2 =
        insert(:message, school: school2, section: section2, name: "School 2 Message")

      messages = MessageBoard.list_messages(school_id: school1.id)

      assert length(messages) == 1
      assert List.first(messages).id == message1.id
    end

    test "list_messages/1 with school_id and classes_ids filters messages for school and specific classes" do
      school = insert(:school)
      class1 = insert(:class, school: school)
      class2 = insert(:class, school: school)
      section = insert(:section, school: school)

      # Message sent to school (should be included)
      school_message = insert(:message, school: school, section: section, send_to: :school)

      # Message sent to specific class (should be included when class is in filter)
      class_message =
        insert(:message,
          school: school,
          section: section,
          send_to: :classes
        )
        |> then(fn message ->
          insert(:message_class, message: message, school: school, class: class1)

          message_with_preloads =
            MessageBoard.get_message!(message.id, preloads: [:classes])

          MessageBoard.update_message(message_with_preloads, %{classes_ids: [class1.id]})
          |> elem(1)
        end)

      # Message sent to different class (should not be included)
      _other_class_message =
        insert(:message,
          school: school,
          section: section,
          send_to: :classes
        )
        |> then(fn message ->
          insert(:message_class, message: message, school: school, class: class2)

          message_with_preloads =
            MessageBoard.get_message!(message.id, preloads: [:classes])

          MessageBoard.update_message(message_with_preloads, %{classes_ids: [class2.id]})
          |> elem(1)
        end)

      messages = MessageBoard.list_messages(school_id: school.id, classes_ids: [class1.id])

      assert length(messages) == 2
      message_ids = Enum.map(messages, & &1.id)
      assert school_message.id in message_ids
      assert class_message.id in message_ids
    end

    test "get_message_per_school/2 returns message when it belongs to the school" do
      school = insert(:school)
      section = insert(:section, school: school)
      message = insert(:message, school: school, section: section)

      assert {:ok, found_message} = MessageBoard.get_message_per_school(message.id, school.id)
      assert found_message.id == message.id
    end

    test "get_message_per_school/2 returns error when message doesn't belong to school" do
      school1 = insert(:school)
      school2 = insert(:school)
      section1 = insert(:section, school: school1)
      message = insert(:message, school: school1, section: section1)

      assert {:error, :not_found} = MessageBoard.get_message_per_school(message.id, school2.id)
    end

    test "get_message_per_school/2 returns error when message doesn't exist" do
      school = insert(:school)
      assert {:error, :not_found} = MessageBoard.get_message_per_school(999, school.id)
    end

    test "get_message/1 returns the message with given id" do
      message = insert(:message)
      assert MessageBoard.get_message(message.id).id == message.id
    end

    test "get_message/1 returns nil when message does not exist" do
      assert MessageBoard.get_message(999) == nil
    end

    test "get_message!/1 returns the message with given id" do
      message = insert(:message)
      assert MessageBoard.get_message!(message.id).id == message.id
    end

    test "get_message!/1 raises when message does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        MessageBoard.get_message!(999)
      end
    end

    test "get_message/2 with preloads option preloads associations" do
      school = insert(:school)
      section = insert(:section, school: school)
      message = insert(:message, school: school, section: section)

      result = MessageBoard.get_message(message.id, preloads: [:school, :section])

      assert result.school.id == school.id
      assert result.section.id == section.id
      refute match?(%Ecto.Association.NotLoaded{}, result.school)
      refute match?(%Ecto.Association.NotLoaded{}, result.section)
    end

    test "create_message/1 with valid data creates a message" do
      school = insert(:school)
      section = insert(:section, school: school)

      valid_attrs = %{
        name: "Test Message",
        description: "Test Description",
        send_to: :school,
        school_id: school.id,
        section_id: section.id,
        subtitle: "Test Subtitle",
        color: "#FF0000"
      }

      assert {:ok, %Message{} = message} = MessageBoard.create_message(valid_attrs)
      assert message.name == "Test Message"
      assert message.description == "Test Description"
      assert message.send_to == :school
      assert message.school_id == school.id
      assert message.section_id == section.id
      assert message.subtitle == "Test Subtitle"
      assert message.color == "#FF0000"
      assert message.position == 0
    end

    test "create_message/1 with invalid data returns error changeset" do
      school = insert(:school)
      section = insert(:section, school: school)

      invalid_attrs = %{
        name: nil,
        description: nil,
        send_to: nil,
        school_id: school.id,
        section_id: section.id
      }

      assert {:error, %Ecto.Changeset{}} = MessageBoard.create_message(invalid_attrs)
    end

    test "create_message/1 with send_to classes requires classes_ids" do
      school = insert(:school)
      section = insert(:section, school: school)

      attrs_without_classes = %{
        name: "Test Message",
        description: "Test Description",
        send_to: :classes,
        school_id: school.id,
        section_id: section.id
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               MessageBoard.create_message(attrs_without_classes)

      assert %{classes_ids: ["At least 1 class is required"]} = errors_on(changeset)
    end

    test "create_message/1 with send_to classes creates message with class associations" do
      school = insert(:school)
      section = insert(:section, school: school)
      class1 = insert(:class, school: school)
      class2 = insert(:class, school: school)

      attrs_with_classes = %{
        name: "Test Message",
        description: "Test Description",
        send_to: :classes,
        school_id: school.id,
        section_id: section.id,
        classes_ids: [class1.id, class2.id]
      }

      assert {:ok, %Message{} = message} = MessageBoard.create_message(attrs_with_classes)

      # Verify message was created with class associations
      message_with_classes = MessageBoard.get_message(message.id, preloads: [:classes])
      class_ids = Enum.map(message_with_classes.classes, & &1.id)
      assert class1.id in class_ids
      assert class2.id in class_ids
    end

    test "update_message/2 with valid data updates the message" do
      message = insert(:message, name: "Original Name")

      update_attrs = %{
        name: "Updated Name",
        description: "Updated Description",
        subtitle: "Updated Subtitle"
      }

      assert {:ok, %Message{} = updated_message} =
               MessageBoard.update_message(message, update_attrs)

      assert updated_message.name == "Updated Name"
      assert updated_message.description == "Updated Description"
      assert updated_message.subtitle == "Updated Subtitle"
    end

    test "update_message/2 with invalid data returns error changeset" do
      message = insert(:message)

      assert {:error, %Ecto.Changeset{}} =
               MessageBoard.update_message(message, @invalid_message_attrs)

      # Message should remain unchanged
      assert message.name == MessageBoard.get_message!(message.id).name
    end

    test "delete_message/1 deletes the message" do
      message = insert(:message)
      assert {:ok, %Message{}} = MessageBoard.delete_message(message)
      assert MessageBoard.get_message(message.id) == nil
    end

    test "change_message/1 returns a message changeset" do
      message = insert(:message)
      assert %Ecto.Changeset{} = MessageBoard.change_message(message)
    end

    test "update_messages_position/1 updates positions of multiple messages" do
      section = insert(:section)
      message1 = insert(:message, section: section, position: 0)
      message2 = insert(:message, section: section, position: 1)
      message3 = insert(:message, section: section, position: 2)

      # Create an archived message that should be filtered out
      _archived_message = insert(:message, section: section, archived_at: DateTime.utc_now())

      # Reorder messages
      reordered_messages = [message3, message1, message2]

      assert :ok = MessageBoard.update_messages_position(reordered_messages)

      # Verify positions were updated
      assert MessageBoard.get_message!(message3.id).position == 0
      assert MessageBoard.get_message!(message1.id).position == 1
      assert MessageBoard.get_message!(message2.id).position == 2
    end
  end
end
