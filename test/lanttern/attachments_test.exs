defmodule Lanttern.AttachmentsTest do
  use Lanttern.DataCase

  alias Lanttern.Attachments

  describe "attachments" do
    alias Lanttern.Attachments.Attachment

    import Lanttern.AttachmentsFixtures

    alias Lanttern.Assessments
    alias Lanttern.AssessmentsFixtures
    alias Lanttern.IdentityFixtures
    alias Lanttern.LearningContext
    alias Lanttern.LearningContextFixtures
    alias Lanttern.Notes
    alias Lanttern.NotesFixtures
    alias Lanttern.StudentsCycleInfo
    alias Lanttern.StudentsCycleInfoFixtures

    @invalid_attrs %{name: nil, link: nil, description: nil, is_external: nil}

    test "list_attachments/1 returns all attachments" do
      attachment = attachment_fixture()
      assert Attachments.list_attachments() == [attachment]
    end

    test "list_attachments/1 with note_id opts returns all attachments filtered by given note" do
      profile = IdentityFixtures.student_profile_fixture()
      note = NotesFixtures.note_fixture(%{author_id: profile.id})

      {:ok, attachment_1} =
        Notes.create_note_attachment(
          %{current_profile: profile},
          note.id,
          %{"name" => "attachment 1", "link" => "https://somevaliduri.com", "is_external" => true}
        )

      {:ok, attachment_2} =
        Notes.create_note_attachment(
          %{current_profile: profile},
          note.id,
          %{"name" => "attachment 2", "link" => "https://somevaliduri.com", "is_external" => true}
        )

      {:ok, attachment_3} =
        Notes.create_note_attachment(
          %{current_profile: profile},
          note.id,
          %{"name" => "attachment 3", "link" => "https://somevaliduri.com", "is_external" => true}
        )

      assert [attachment_1, attachment_2, attachment_3] ==
               Attachments.list_attachments(note_id: note.id)

      # use same setup to test update_note_attachments_positions/1

      Notes.update_note_attachments_positions([attachment_2.id, attachment_3.id, attachment_1.id])

      assert [attachment_2, attachment_3, attachment_1] ==
               Attachments.list_attachments(note_id: note.id)
    end

    test "list_attachments/1 with assessment_point_entry_id opts returns all attachments filtered by given assessment point entry" do
      profile = IdentityFixtures.student_profile_fixture()
      entry = AssessmentsFixtures.assessment_point_entry_fixture()

      {:ok, attachment_1} =
        Assessments.create_assessment_point_entry_evidence(
          %{current_profile: profile},
          entry.id,
          %{"name" => "evidence 1", "link" => "https://somevaliduri.com", "is_external" => true}
        )

      {:ok, attachment_2} =
        Assessments.create_assessment_point_entry_evidence(
          %{current_profile: profile},
          entry.id,
          %{"name" => "evidence 2", "link" => "https://somevaliduri.com", "is_external" => true}
        )

      {:ok, attachment_3} =
        Assessments.create_assessment_point_entry_evidence(
          %{current_profile: profile},
          entry.id,
          %{"name" => "evidence 3", "link" => "https://somevaliduri.com", "is_external" => true}
        )

      assert [attachment_1, attachment_2, attachment_3] ==
               Attachments.list_attachments(assessment_point_entry_id: entry.id)

      # use same setup to test update_assessment_point_entry_evidences_positions/1

      Assessments.update_assessment_point_entry_evidences_positions([
        attachment_2.id,
        attachment_3.id,
        attachment_1.id
      ])

      assert [attachment_2, attachment_3, attachment_1] ==
               Attachments.list_attachments(assessment_point_entry_id: entry.id)
    end

    test "list_attachments/1 with student_cycle_info_id opts returns all attachments linked to given student cycle info" do
      profile = IdentityFixtures.teacher_profile_fixture()
      student_cycle_info = StudentsCycleInfoFixtures.student_cycle_info_fixture()

      {:ok, attachment_1} =
        StudentsCycleInfo.create_student_cycle_info_attachment(
          profile.id,
          student_cycle_info.id,
          %{"name" => "attachment 1", "link" => "https://somevaliduri.com", "is_external" => true}
        )

      {:ok, attachment_2} =
        StudentsCycleInfo.create_student_cycle_info_attachment(
          profile.id,
          student_cycle_info.id,
          %{"name" => "attachment 2", "link" => "https://somevaliduri.com", "is_external" => true}
        )

      {:ok, shared_attachment} =
        StudentsCycleInfo.create_student_cycle_info_attachment(
          profile.id,
          student_cycle_info.id,
          %{
            "name" => "family attachment",
            "link" => "https://somevaliduri.com",
            "is_external" => true
          },
          true
        )

      # extra attachments to test filtering
      attachment_fixture()

      StudentsCycleInfo.create_student_cycle_info_attachment(
        profile.id,
        StudentsCycleInfoFixtures.student_cycle_info_fixture().id,
        %{
          "name" => "other attachment",
          "link" => "https://somevaliduri.com",
          "is_external" => true
        }
      )

      assert [attachment_1, attachment_2, shared_attachment] ==
               Attachments.list_attachments(student_cycle_info_id: student_cycle_info.id)

      # use same setup to test update_student_cycle_info_attachments_positions/1 and shared_with_student filtering

      StudentsCycleInfo.update_student_cycle_info_attachments_positions([
        attachment_2.id,
        attachment_1.id
      ])

      assert [attachment_2, attachment_1] ==
               Attachments.list_attachments(
                 student_cycle_info_id: student_cycle_info.id,
                 shared_with_student: {:student_cycle_info, false}
               )
    end

    test "list_attachments/1 with moment_card_id opts returns all attachments linked to given moment card" do
      profile = IdentityFixtures.teacher_profile_fixture()
      moment_card = LearningContextFixtures.moment_card_fixture()

      {:ok, attachment_1} =
        LearningContext.create_moment_card_attachment(
          profile.id,
          moment_card.id,
          %{"name" => "attachment 1", "link" => "https://somevaliduri.com", "is_external" => true}
        )

      {:ok, attachment_2} =
        LearningContext.create_moment_card_attachment(
          profile.id,
          moment_card.id,
          %{"name" => "attachment 2", "link" => "https://somevaliduri.com", "is_external" => true}
        )

      {:ok, shared_attachment} =
        LearningContext.create_moment_card_attachment(
          profile.id,
          moment_card.id,
          %{
            "name" => "family attachment",
            "link" => "https://somevaliduri.com",
            "is_external" => true
          },
          true
        )

      # extra attachments to test filtering
      attachment_fixture()

      LearningContext.create_moment_card_attachment(
        profile.id,
        LearningContextFixtures.moment_card_fixture().id,
        %{
          "name" => "other attachment",
          "link" => "https://somevaliduri.com",
          "is_external" => true
        }
      )

      [expected_attachment_1, expected_attachment_2, expected_shared_attachment] =
        Attachments.list_attachments(moment_card_id: moment_card.id)

      assert expected_attachment_1.id == attachment_1.id
      assert expected_attachment_2.id == attachment_2.id
      assert expected_shared_attachment.id == shared_attachment.id

      # expect is_shared is defined in the context of moment card attachments
      assert expected_attachment_1.is_shared == false
      assert expected_attachment_2.is_shared == false
      assert expected_shared_attachment.is_shared

      # use same setup to test update_moment_card_attachments_positions/1 and shared_with_students filtering

      LearningContext.update_moment_card_attachments_positions([
        attachment_2.id,
        attachment_1.id
      ])

      [expected_attachment_2, expected_attachment_1] =
        Attachments.list_attachments(
          moment_card_id: moment_card.id,
          shared_with_student: {:moment_card, false}
        )

      assert expected_attachment_1.id == attachment_1.id
      assert expected_attachment_2.id == attachment_2.id
    end

    test "get_attachment!/1 returns the attachment with given id" do
      attachment = attachment_fixture()
      assert Attachments.get_attachment!(attachment.id) == attachment
    end

    test "create_attachment/1 with valid data creates a attachment" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      valid_attrs = %{
        name: "some name",
        link: "https://create-valid.link",
        description: "some description",
        is_external: true,
        owner_id: profile.id
      }

      assert {:ok, %Attachment{} = attachment} = Attachments.create_attachment(valid_attrs)
      assert attachment.name == "some name"
      assert attachment.link == "https://create-valid.link"
      assert attachment.description == "some description"
      assert attachment.is_external == true
      assert attachment.owner_id == profile.id
    end

    test "create_attachment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Attachments.create_attachment(@invalid_attrs)
    end

    test "update_attachment/2 with valid data updates the attachment" do
      attachment = attachment_fixture()

      update_attrs = %{
        name: "some updated name",
        link: "https://valid-updated.link",
        description: "some updated description",
        is_external: false
      }

      assert {:ok, %Attachment{} = attachment} =
               Attachments.update_attachment(attachment, update_attrs)

      assert attachment.name == "some updated name"
      assert attachment.link == "https://valid-updated.link"
      assert attachment.description == "some updated description"
      assert attachment.is_external == false
    end

    test "update_attachment/2 with invalid data returns error changeset" do
      attachment = attachment_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Attachments.update_attachment(attachment, @invalid_attrs)

      assert attachment == Attachments.get_attachment!(attachment.id)
    end

    test "delete_attachment/1 deletes the attachment" do
      attachment = attachment_fixture()
      assert {:ok, %Attachment{}} = Attachments.delete_attachment(attachment)
      assert_raise Ecto.NoResultsError, fn -> Attachments.get_attachment!(attachment.id) end
    end

    test "change_attachment/1 returns a attachment changeset" do
      attachment = attachment_fixture()
      assert %Ecto.Changeset{} = Attachments.change_attachment(attachment)
    end
  end
end
