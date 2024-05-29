defmodule Lanttern.AttachmentsTest do
  use Lanttern.DataCase

  alias Lanttern.Attachments

  describe "attachments" do
    alias Lanttern.Attachments.Attachment

    import Lanttern.AttachmentsFixtures

    alias Lanttern.IdentityFixtures
    alias Lanttern.Notes
    alias Lanttern.NotesFixtures

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
