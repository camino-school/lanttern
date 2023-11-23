defmodule Lanttern.PersonalizationTest do
  use Lanttern.DataCase

  alias Lanttern.Personalization

  describe "notes" do
    alias Lanttern.Personalization.Note

    import Lanttern.PersonalizationFixtures
    import Lanttern.IdentityFixtures

    @invalid_attrs %{description: nil}

    test "list_notes/1 returns all notes" do
      note = note_fixture()
      assert Personalization.list_notes() == [note]
    end

    test "list_notes/1 with preloads returns all notes with preloaded data" do
      author = teacher_profile_fixture()
      note = note_fixture(%{author_id: author.id})

      [expected] = Personalization.list_notes(preloads: :author)
      assert expected.id == note.id
      assert expected.author.id == author.id
    end

    test "get_note!/2 returns the note with given id" do
      note = note_fixture()
      assert Personalization.get_note!(note.id) == note
    end

    test "get_note!/2 with preloads returns the note with given id and preloaded data" do
      author = teacher_profile_fixture()
      note = note_fixture(%{author_id: author.id})

      expected = Personalization.get_note!(note.id, preloads: :author)
      assert expected.id == note.id
      assert expected.author.id == author.id
    end

    test "create_note/1 with valid data creates a note" do
      author = teacher_profile_fixture()
      valid_attrs = %{author_id: author.id, description: "some description"}

      assert {:ok, %Note{} = note} = Personalization.create_note(valid_attrs)
      assert note.author_id == author.id
      assert note.description == "some description"
    end

    test "create_note/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Personalization.create_note(@invalid_attrs)
    end

    test "update_note/2 with valid data updates the note" do
      note = note_fixture()
      update_attrs = %{description: "some updated description"}

      assert {:ok, %Note{} = note} = Personalization.update_note(note, update_attrs)
      assert note.description == "some updated description"
    end

    test "update_note/2 with invalid data returns error changeset" do
      note = note_fixture()
      assert {:error, %Ecto.Changeset{}} = Personalization.update_note(note, @invalid_attrs)
      assert note == Personalization.get_note!(note.id)
    end

    test "delete_note/1 deletes the note" do
      note = note_fixture()
      assert {:ok, %Note{}} = Personalization.delete_note(note)
      assert_raise Ecto.NoResultsError, fn -> Personalization.get_note!(note.id) end
    end

    test "change_note/1 returns a note changeset" do
      note = note_fixture()
      assert %Ecto.Changeset{} = Personalization.change_note(note)
    end
  end

  describe "strand notes" do
    alias Lanttern.Personalization.Note

    import Lanttern.PersonalizationFixtures
    import Lanttern.IdentityFixtures
    import Lanttern.LearningContextFixtures

    test "create_strand_note/2 with valid data creates a note linked to a strand" do
      author = teacher_profile_fixture()
      strand = strand_fixture()
      valid_attrs = %{"description" => "some strand note"}

      assert {:ok, %Note{} = note} =
               Personalization.create_strand_note(
                 %{current_profile: author},
                 strand.id,
                 valid_attrs
               )

      assert note.author_id == author.id
      assert note.description == "some strand note"

      expected =
        Personalization.get_user_note(%{current_profile: author}, strand_id: strand.id)

      assert expected.id == note.id
    end

    test "create_strand_note/2 with invalid data returns error changeset" do
      strand = strand_fixture()
      invalid_attrs = %{"description" => "some strand note"}

      assert {:error, %Ecto.Changeset{}} =
               Personalization.create_strand_note(
                 %{current_profile: nil},
                 strand.id,
                 invalid_attrs
               )
    end

    test "create_strand_note/2 prevents multiple notes in the same strand" do
      author = teacher_profile_fixture()
      strand = strand_fixture()
      attrs = %{"author_id" => author.id, "description" => "some strand note"}

      assert {:ok, %Note{}} =
               Personalization.create_strand_note(%{current_profile: author}, strand.id, attrs)

      assert {:error, %Ecto.Changeset{}} =
               Personalization.create_strand_note(%{current_profile: author}, strand.id, attrs)
    end
  end

  describe "activity notes" do
    alias Lanttern.Personalization.Note

    import Lanttern.PersonalizationFixtures
    import Lanttern.IdentityFixtures
    import Lanttern.LearningContextFixtures

    test "create_activity_note/2 with valid data creates a note linked to a activity" do
      author = teacher_profile_fixture()
      activity = activity_fixture()
      valid_attrs = %{"author_id" => author.id, "description" => "some activity note"}

      assert {:ok, %Note{} = note} =
               Personalization.create_activity_note(
                 %{current_profile: author},
                 activity.id,
                 valid_attrs
               )

      assert note.author_id == author.id
      assert note.description == "some activity note"

      expected =
        Personalization.get_user_note(%{current_profile: author}, activity_id: activity.id)

      assert expected.id == note.id
    end

    test "create_activity_note/2 with invalid data returns error changeset" do
      activity = activity_fixture()
      invalid_attrs = %{"description" => "some activity note"}

      assert {:error, %Ecto.Changeset{}} =
               Personalization.create_activity_note(
                 %{current_profile: nil},
                 activity.id,
                 invalid_attrs
               )
    end

    test "create_activity_note/2 prevents multiple notes in the same activity" do
      author = teacher_profile_fixture()
      activity = activity_fixture()
      attrs = %{"author_id" => author.id, "description" => "some activity note"}

      assert {:ok, %Note{}} =
               Personalization.create_activity_note(
                 %{current_profile: author},
                 activity.id,
                 attrs
               )

      assert {:error, %Ecto.Changeset{}} =
               Personalization.create_activity_note(
                 %{current_profile: author},
                 activity.id,
                 attrs
               )
    end
  end
end
