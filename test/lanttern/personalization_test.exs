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

    test "list_user_notes/2 returns all user activities notes in a strand" do
      author = teacher_profile_fixture()
      strand = strand_fixture()
      activity_1 = activity_fixture(%{strand_id: strand.id, position: 1})
      note_1 = activity_note_fixture(%{current_profile: author}, activity_1.id)
      activity_2 = activity_fixture(%{strand_id: strand.id, position: 2})
      note_2 = activity_note_fixture(%{current_profile: author}, activity_2.id)

      assert [expected_1, expected_2] =
               Personalization.list_user_notes(%{current_profile: author}, strand_id: strand.id)

      assert expected_1.id == note_1.id
      assert expected_1.activity.id == activity_1.id
      assert expected_2.id == note_2.id
      assert expected_2.activity.id == activity_2.id
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

  describe "profile_views" do
    alias Lanttern.Personalization.ProfileView

    import Lanttern.PersonalizationFixtures

    @invalid_attrs %{name: nil}

    test "list_profile_views/1 returns all profile_views" do
      profile_view = profile_view_fixture()
      [expected] = Personalization.list_profile_views()
      assert expected.id == profile_view.id
    end

    test "list_profile_views/1 with preloads returns all profile_views with preloaded data" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      profile_view =
        profile_view_fixture(%{profile_id: profile.id})

      [expected] = Personalization.list_profile_views(preloads: :profile)
      assert expected.id == profile_view.id
      assert expected.profile == profile
    end

    test "list_profile_views/1 with profile filter returns all profile_views belonging to given profile" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      profile_view =
        profile_view_fixture(%{profile_id: profile.id})

      # extra fixture for filter testing
      profile_view_fixture()

      [expected] = Personalization.list_profile_views(profile_id: profile.id)
      assert expected.id == profile_view.id
    end

    test "get_profile_view!/2 returns the profile_view with given id" do
      profile_view = profile_view_fixture()

      expected = Personalization.get_profile_view!(profile_view.id)
      assert expected.id == profile_view.id
    end

    test "get_profile_view!/2 with preloads returns the profile_view with given id with preloaded data" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      profile_view =
        profile_view_fixture(%{profile_id: profile.id})

      expected =
        Personalization.get_profile_view!(profile_view.id,
          preloads: :profile
        )

      assert expected.id == profile_view.id
      assert expected.profile == profile
    end

    test "create_profile_view/1 with valid data creates a profile_view" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()
      subject = Lanttern.TaxonomyFixtures.subject_fixture()
      class = Lanttern.SchoolsFixtures.class_fixture()

      valid_attrs = %{
        name: "some name",
        profile_id: profile.id,
        subjects_ids: [subject.id],
        classes_ids: [class.id]
      }

      assert {:ok, %ProfileView{} = profile_view} =
               Personalization.create_profile_view(valid_attrs)

      assert profile_view.name == "some name"

      # assert subject and class relationship were created

      assert [{profile_view.id, subject.id}] ==
               from(
                 vs in "profile_views_subjects",
                 where: vs.profile_view_id == ^profile_view.id,
                 select: {vs.profile_view_id, vs.subject_id}
               )
               |> Repo.all()

      assert [{profile_view.id, class.id}] ==
               from(
                 vc in "profile_views_classes",
                 where: vc.profile_view_id == ^profile_view.id,
                 select: {vc.profile_view_id, vc.class_id}
               )
               |> Repo.all()
    end

    test "create_profile_view/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Personalization.create_profile_view(@invalid_attrs)
    end

    test "update_profile_view/2 with valid data updates the profile_view" do
      profile_view = profile_view_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %ProfileView{} = profile_view} =
               Personalization.update_profile_view(
                 profile_view,
                 update_attrs
               )

      assert profile_view.name == "some updated name"
    end

    test "update_profile_view/2 with invalid data returns error changeset" do
      profile_view = profile_view_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Personalization.update_profile_view(
                 profile_view,
                 @invalid_attrs
               )

      expected = Personalization.get_profile_view!(profile_view.id)
      assert expected.id == profile_view.id
      assert expected.name == profile_view.name
    end

    test "delete_profile_view/1 deletes the profile_view" do
      profile_view = profile_view_fixture()

      assert {:ok, %ProfileView{}} =
               Personalization.delete_profile_view(profile_view)

      assert_raise Ecto.NoResultsError, fn ->
        Personalization.get_profile_view!(profile_view.id)
      end
    end

    test "change_profile_view/1 returns a profile_view changeset" do
      profile_view = profile_view_fixture()

      assert %Ecto.Changeset{} =
               Personalization.change_profile_view(profile_view)
    end
  end

  describe "profile_settings" do
    alias Lanttern.Personalization.ProfileSettings

    import Lanttern.PersonalizationFixtures
    import Lanttern.IdentityFixtures

    test "set_profile_current_filters/2 sets current filters in profile settings" do
      current_profile =
        teacher_profile_fixture()
        |> Map.put(:settings, nil)

      subjects_ids = [1, 2, 3]
      classes_ids = [4, 5, 6]

      assert {:ok, %ProfileSettings{} = settings} =
               Personalization.set_profile_current_filters(
                 %{current_profile: current_profile},
                 %{
                   subjects_ids: subjects_ids,
                   classes_ids: classes_ids
                 }
               )

      assert settings.current_filters.subjects_ids == subjects_ids
      assert settings.current_filters.classes_ids == classes_ids
    end

    test "set_profile_current_filters/2 with only one type of filter keeps the other filters as is" do
      current_profile =
        teacher_profile_fixture()
        |> Map.put(:settings, nil)

      # create profile settings with classes ids
      {:ok, %ProfileSettings{} = settings} =
        Personalization.set_profile_current_filters(
          %{current_profile: current_profile},
          %{classes_ids: [4, 5, 6]}
        )

      current_profile =
        current_profile
        |> Map.put(:settings, settings)

      subjects_ids = [1, 2, 3]

      assert {:ok, %ProfileSettings{} = settings} =
               Personalization.set_profile_current_filters(
                 %{current_profile: current_profile},
                 %{subjects_ids: subjects_ids}
               )

      assert settings.current_filters.subjects_ids == subjects_ids
      assert settings.current_filters.classes_ids == [4, 5, 6]
    end
  end
end
