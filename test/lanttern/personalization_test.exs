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

    test "list_user_notes/2 returns all user moments notes in a strand" do
      author = teacher_profile_fixture()
      strand = strand_fixture()
      moment_1 = moment_fixture(%{strand_id: strand.id, position: 1})
      note_1 = moment_note_fixture(%{current_profile: author}, moment_1.id)
      moment_2 = moment_fixture(%{strand_id: strand.id, position: 2})
      note_2 = moment_note_fixture(%{current_profile: author}, moment_2.id)

      assert [expected_1, expected_2] =
               Personalization.list_user_notes(%{current_profile: author}, strand_id: strand.id)

      assert expected_1.id == note_1.id
      assert expected_1.moment.id == moment_1.id
      assert expected_2.id == note_2.id
      assert expected_2.moment.id == moment_2.id
    end

    test "list_student_strands_notes/2 returns all user strand notes related to students report cards" do
      author = student_profile_fixture()

      subject_1 = Lanttern.TaxonomyFixtures.subject_fixture()
      subject_2 = Lanttern.TaxonomyFixtures.subject_fixture()
      year = Lanttern.TaxonomyFixtures.year_fixture()

      strand_1 =
        strand_fixture(%{subjects_ids: [subject_1.id, subject_2.id], years_ids: [year.id]})

      strand_2 = strand_fixture()
      strand_3 = strand_fixture()
      strand_4 = strand_fixture()

      cycle_2024 =
        Lanttern.SchoolsFixtures.cycle_fixture(start_at: ~D[2024-01-01], end_at: ~D[2024-12-31])

      cycle_2023 =
        Lanttern.SchoolsFixtures.cycle_fixture(start_at: ~D[2023-01-01], end_at: ~D[2023-12-31])

      report_card_2024 =
        Lanttern.ReportingFixtures.report_card_fixture(%{school_cycle_id: cycle_2024.id})

      report_card_2023 =
        Lanttern.ReportingFixtures.report_card_fixture(%{school_cycle_id: cycle_2023.id})

      # create strand reports

      _strand_report_1_2024 =
        Lanttern.ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card_2024.id,
          strand_id: strand_1.id
        })

      _strand_report_2_2024 =
        Lanttern.ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card_2024.id,
          strand_id: strand_2.id
        })

      _strand_report_3_2023 =
        Lanttern.ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card_2023.id,
          strand_id: strand_3.id
        })

      _strand_report_4_2023 =
        Lanttern.ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card_2023.id,
          strand_id: strand_4.id
        })

      # create students report cards
      _ =
        Lanttern.ReportingFixtures.student_report_card_fixture(%{
          student_id: author.student_id,
          report_card_id: report_card_2024.id
        })

      _ =
        Lanttern.ReportingFixtures.student_report_card_fixture(%{
          student_id: author.student_id,
          report_card_id: report_card_2023.id
        })

      # create student notes in strand 1 and 3

      strand_1_note = strand_note_fixture(%{current_profile: author}, strand_1.id)
      strand_3_note = strand_note_fixture(%{current_profile: author}, strand_3.id)

      # extra fixtures for filter testing
      other_strand = strand_fixture()
      other_report_card = Lanttern.ReportingFixtures.report_card_fixture()

      _other_strand_1_note =
        strand_note_fixture(%{current_profile: student_profile_fixture()}, strand_1.id)

      _other_strand_report =
        Lanttern.ReportingFixtures.strand_report_fixture(%{
          report_card_id: other_report_card.id,
          strand_id: other_strand.id
        })

      _ =
        Lanttern.ReportingFixtures.student_report_card_fixture(%{
          student_id: author.student_id,
          report_card_id: other_report_card.id
        })

      assert [
               {^strand_1_note, expected_strand_1, ^cycle_2024},
               {nil, expected_strand_2, ^cycle_2024},
               {^strand_3_note, expected_strand_3, ^cycle_2023},
               {nil, expected_strand_4, ^cycle_2023}
             ] =
               Personalization.list_student_strands_notes(
                 %{current_profile: author},
                 cycles_ids: [cycle_2023.id, cycle_2024.id]
               )

      assert expected_strand_1.id == strand_1.id
      assert subject_1 in expected_strand_1.subjects
      assert subject_2 in expected_strand_1.subjects
      assert [year] == expected_strand_1.years
      assert expected_strand_2.id == strand_2.id
      assert expected_strand_3.id == strand_3.id
      assert expected_strand_4.id == strand_4.id
    end

    test "get_student_note/2 returns the student note for the given strand" do
      author = student_profile_fixture()
      strand = strand_fixture()

      note =
        strand_note_fixture(%{current_profile: author}, strand.id)

      assert expected_note =
               Personalization.get_student_note(author.student_id, strand_id: strand.id)

      assert expected_note.id == note.id
      assert expected_note.strand.id == strand.id
    end
  end

  describe "moment notes" do
    alias Lanttern.Personalization.Note

    import Lanttern.PersonalizationFixtures
    import Lanttern.IdentityFixtures
    import Lanttern.LearningContextFixtures

    test "create_moment_note/2 with valid data creates a note linked to a moment" do
      author = teacher_profile_fixture()
      moment = moment_fixture()
      valid_attrs = %{"author_id" => author.id, "description" => "some moment note"}

      assert {:ok, %Note{} = note} =
               Personalization.create_moment_note(
                 %{current_profile: author},
                 moment.id,
                 valid_attrs
               )

      assert note.author_id == author.id
      assert note.description == "some moment note"

      expected =
        Personalization.get_user_note(%{current_profile: author}, moment_id: moment.id)

      assert expected.id == note.id
    end

    test "create_moment_note/2 with invalid data returns error changeset" do
      moment = moment_fixture()
      invalid_attrs = %{"description" => "some moment note"}

      assert {:error, %Ecto.Changeset{}} =
               Personalization.create_moment_note(
                 %{current_profile: nil},
                 moment.id,
                 invalid_attrs
               )
    end

    test "create_moment_note/2 prevents multiple notes in the same moment" do
      author = teacher_profile_fixture()
      moment = moment_fixture()
      attrs = %{"author_id" => author.id, "description" => "some moment note"}

      assert {:ok, %Note{}} =
               Personalization.create_moment_note(
                 %{current_profile: author},
                 moment.id,
                 attrs
               )

      assert {:error, %Ecto.Changeset{}} =
               Personalization.create_moment_note(
                 %{current_profile: author},
                 moment.id,
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
      current_profile = teacher_profile_fixture()

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
      current_profile = teacher_profile_fixture()

      # create profile settings with classes ids
      Personalization.set_profile_current_filters(
        %{current_profile: current_profile},
        %{classes_ids: [4, 5, 6]}
      )

      subjects_ids = [1, 2, 3]

      assert {:ok, %ProfileSettings{} = settings} =
               Personalization.set_profile_current_filters(
                 %{current_profile: current_profile},
                 %{subjects_ids: subjects_ids}
               )

      assert settings.current_filters.subjects_ids == subjects_ids
      assert settings.current_filters.classes_ids == [4, 5, 6]
    end

    test "sync_params_and_profile_filters/3 when there's no current filters in profile sets current filters based on params" do
      current_profile = teacher_profile_fixture()

      params = %{"foo" => "bar", "classes_ids" => ["1", "2", "3"]}

      {:noop, expected} =
        Personalization.sync_params_and_profile_filters(
          params,
          %{current_profile: current_profile},
          [:classes_ids]
        )

      assert expected["foo"] == "bar"
      assert expected["classes_ids"] == ["1", "2", "3"]

      profile_settings = Personalization.get_profile_settings(current_profile.id)

      assert profile_settings.current_filters.classes_ids == [1, 2, 3]
    end

    test "sync_params_and_profile_filters/3 when there's no params updates params with profile filters " do
      current_profile = teacher_profile_fixture()

      # create profile settings with classes ids
      Personalization.set_profile_current_filters(
        %{current_profile: current_profile},
        %{classes_ids: [4, 5, 6]}
      )

      params = %{"foo" => "bar"}

      {:updated, expected} =
        Personalization.sync_params_and_profile_filters(
          params,
          %{current_profile: current_profile},
          [:classes_ids]
        )

      assert expected["foo"] == "bar"
      assert expected["classes_ids"] == ["4", "5", "6"]
    end

    test "sync_params_and_profile_filters/3 adds params to filters and filters to params" do
      current_profile = teacher_profile_fixture()

      # create profile settings with classes and years ids
      Personalization.set_profile_current_filters(
        %{current_profile: current_profile},
        %{classes_ids: [4, 5, 6], years_ids: [7, 8, 9]}
      )

      params = %{"foo" => "bar", "subjects_ids" => ["1", "2", "3"], "years_ids" => ""}

      {:updated, expected} =
        Personalization.sync_params_and_profile_filters(
          params,
          %{current_profile: current_profile},
          [:classes_ids, :subjects_ids, :years_ids]
        )

      assert expected["foo"] == "bar"
      assert expected["subjects_ids"] == ["1", "2", "3"]
      assert expected["classes_ids"] == ["4", "5", "6"]
      assert expected["years_ids"] == ""

      profile_settings = Personalization.get_profile_settings(current_profile.id)

      assert profile_settings.current_filters.subjects_ids == [1, 2, 3]
      assert profile_settings.current_filters.classes_ids == [4, 5, 6]
      assert profile_settings.current_filters.years_ids == []
    end
  end

  describe "profile_strand_filters" do
    alias Lanttern.Personalization.ProfileStrandFilter

    import Lanttern.PersonalizationFixtures
    alias Lanttern.IdentityFixtures
    alias Lanttern.LearningContextFixtures
    alias Lanttern.SchoolsFixtures

    @invalid_attrs %{profile_id: nil}

    test "list_profile_strand_filters/0 returns all profile_strand_filters" do
      profile_strand_filter = profile_strand_filter_fixture()
      assert Personalization.list_profile_strand_filters() == [profile_strand_filter]
    end

    test "list_profile_strand_filters_classes_ids/2 returns all classes ids filtered by profile in the strand context" do
      strand = LearningContextFixtures.strand_fixture()
      class_1 = SchoolsFixtures.class_fixture()
      class_2 = SchoolsFixtures.class_fixture()
      profile = IdentityFixtures.teacher_profile_fixture()

      profile_strand_filter_fixture(%{
        profile_id: profile.id,
        strand_id: strand.id,
        class_id: class_1.id
      })

      profile_strand_filter_fixture(%{
        profile_id: profile.id,
        strand_id: strand.id,
        class_id: class_2.id
      })

      # extra fixtures to test filter
      profile_strand_filter_fixture()

      assert expected =
               Personalization.list_profile_strand_filters_classes_ids(profile.id, strand.id)

      assert length(expected) == 2
      assert class_1.id in expected
      assert class_2.id in expected
    end

    test "get_profile_strand_filter!/1 returns the profile_strand_filter with given id" do
      profile_strand_filter = profile_strand_filter_fixture()

      assert Personalization.get_profile_strand_filter!(profile_strand_filter.id) ==
               profile_strand_filter
    end

    test "set_profile_strand_filters/3 sets current filters in profile strand filters" do
      current_profile = IdentityFixtures.teacher_profile_fixture()
      strand = LearningContextFixtures.strand_fixture()
      class_1 = SchoolsFixtures.class_fixture()
      class_2 = SchoolsFixtures.class_fixture()

      assert {:ok, results} =
               Personalization.set_profile_strand_filters(
                 %{current_profile: current_profile},
                 strand.id,
                 %{classes_ids: [class_1.id, class_2.id]}
               )

      for {_, profile_strand_filter} <- results do
        assert profile_strand_filter.profile_id == current_profile.id
        assert profile_strand_filter.strand_id == strand.id
        assert profile_strand_filter.class_id in [class_1.id, class_2.id]
      end

      # repeat with a new class to test filter "update"
      class_3 = SchoolsFixtures.class_fixture()
      class_3_id = class_3.id

      assert {:ok, _results} =
               Personalization.set_profile_strand_filters(
                 %{current_profile: current_profile},
                 strand.id,
                 %{classes_ids: [class_3_id]}
               )

      assert [class_3_id] ==
               Personalization.list_profile_strand_filters_classes_ids(
                 current_profile.id,
                 strand.id
               )
    end

    test "create_profile_strand_filter/1 with valid data creates a profile_strand_filter" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()
      strand = Lanttern.LearningContextFixtures.strand_fixture()
      class = Lanttern.SchoolsFixtures.class_fixture()

      valid_attrs = %{profile_id: profile.id, strand_id: strand.id, class_id: class.id}

      assert {:ok, %ProfileStrandFilter{} = profile_strand_filter} =
               Personalization.create_profile_strand_filter(valid_attrs)

      assert profile_strand_filter.profile_id == profile.id
      assert profile_strand_filter.strand_id == strand.id
      assert profile_strand_filter.class_id == class.id
    end

    test "create_profile_strand_filter/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Personalization.create_profile_strand_filter(@invalid_attrs)
    end

    test "update_profile_strand_filter/2 with valid data updates the profile_strand_filter" do
      profile_strand_filter = profile_strand_filter_fixture()
      strand = Lanttern.LearningContextFixtures.strand_fixture()
      update_attrs = %{strand_id: strand.id}

      assert {:ok, %ProfileStrandFilter{} = profile_strand_filter} =
               Personalization.update_profile_strand_filter(profile_strand_filter, update_attrs)

      assert profile_strand_filter.strand_id == strand.id
    end

    test "update_profile_strand_filter/2 with invalid data returns error changeset" do
      profile_strand_filter = profile_strand_filter_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Personalization.update_profile_strand_filter(profile_strand_filter, @invalid_attrs)

      assert profile_strand_filter ==
               Personalization.get_profile_strand_filter!(profile_strand_filter.id)
    end

    test "delete_profile_strand_filter/1 deletes the profile_strand_filter" do
      profile_strand_filter = profile_strand_filter_fixture()

      assert {:ok, %ProfileStrandFilter{}} =
               Personalization.delete_profile_strand_filter(profile_strand_filter)

      assert_raise Ecto.NoResultsError, fn ->
        Personalization.get_profile_strand_filter!(profile_strand_filter.id)
      end
    end

    test "change_profile_strand_filter/1 returns a profile_strand_filter changeset" do
      profile_strand_filter = profile_strand_filter_fixture()

      assert %Ecto.Changeset{} =
               Personalization.change_profile_strand_filter(profile_strand_filter)
    end
  end

  describe "profile_report_card_filter" do
    alias Lanttern.Personalization.ProfileReportCardFilter

    import Lanttern.PersonalizationFixtures
    alias Lanttern.IdentityFixtures
    alias Lanttern.ReportingFixtures
    alias Lanttern.SchoolsFixtures

    @invalid_attrs %{profile_id: nil}

    test "list_profile_report_card_filter/0 returns all profile_report_card_filter" do
      profile_report_card_filter = profile_report_card_filter_fixture()
      assert Personalization.list_profile_report_card_filter() == [profile_report_card_filter]
    end

    test "list_profile_report_card_filters/2 returns all classes ids filtered by profile in the report card context" do
      report_card = ReportingFixtures.report_card_fixture()
      class_1 = SchoolsFixtures.class_fixture()
      class_2 = SchoolsFixtures.class_fixture()
      profile = IdentityFixtures.teacher_profile_fixture()

      profile_report_card_filter_fixture(%{
        profile_id: profile.id,
        report_card_id: report_card.id,
        class_id: class_1.id
      })

      profile_report_card_filter_fixture(%{
        profile_id: profile.id,
        report_card_id: report_card.id,
        class_id: class_2.id
      })

      profile_report_card_filter_fixture(%{
        profile_id: profile.id,
        report_card_id: report_card.id,
        class_id: nil,
        linked_students_class_id: class_2.id
      })

      # extra fixtures to test filter
      profile_report_card_filter_fixture()

      assert %{
               classes_ids: expected_classes_ids,
               linked_students_classes_ids: expected_linked_students_classes_ids
             } =
               Personalization.list_profile_report_card_filters(
                 profile.id,
                 report_card.id
               )

      assert length(expected_classes_ids) == 2
      assert class_1.id in expected_classes_ids
      assert class_2.id in expected_classes_ids
      assert [class_2.id] == expected_linked_students_classes_ids
    end

    test "get_profile_report_card_filter!/1 returns the profile_report_card_filter with given id" do
      profile_report_card_filter = profile_report_card_filter_fixture()

      assert Personalization.get_profile_report_card_filter!(profile_report_card_filter.id) ==
               profile_report_card_filter
    end

    test "set_profile_report_card_filters/3 sets current filters in profile report card filters" do
      current_profile = IdentityFixtures.teacher_profile_fixture()
      report_card = ReportingFixtures.report_card_fixture()
      class_1 = SchoolsFixtures.class_fixture()
      class_2 = SchoolsFixtures.class_fixture()

      assert {:ok, results} =
               Personalization.set_profile_report_card_filters(
                 %{current_profile: current_profile},
                 report_card.id,
                 %{
                   classes_ids: [class_1.id, class_2.id],
                   linked_students_classes_ids: [class_1.id]
                 }
               )

      assert length(Map.keys(results)) == 3

      for {_, profile_report_card_filter} <- results do
        assert profile_report_card_filter.profile_id == current_profile.id
        assert profile_report_card_filter.report_card_id == report_card.id

        assert profile_report_card_filter.class_id in [class_1.id, class_2.id] or
                 profile_report_card_filter.linked_students_class_id == class_1.id
      end

      # repeat with a new class to test filter "update"
      class_3 = SchoolsFixtures.class_fixture()
      class_3_id = class_3.id

      assert {:ok, _results} =
               Personalization.set_profile_report_card_filters(
                 %{current_profile: current_profile},
                 report_card.id,
                 %{classes_ids: [class_3_id]}
               )

      assert %{classes_ids: [class_3_id], linked_students_classes_ids: [class_1.id]} ==
               Personalization.list_profile_report_card_filters(
                 current_profile.id,
                 report_card.id
               )
    end

    test "create_profile_report_card_filter/1 with valid data creates a profile_report_card_filter" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()
      report_card = Lanttern.ReportingFixtures.report_card_fixture()
      class = Lanttern.SchoolsFixtures.class_fixture()

      valid_attrs = %{
        profile_id: profile.id,
        report_card_id: report_card.id,
        class_id: class.id
      }

      assert {:ok, %ProfileReportCardFilter{} = profile_report_card_filter} =
               Personalization.create_profile_report_card_filter(valid_attrs)

      assert profile_report_card_filter.profile_id == profile.id
      assert profile_report_card_filter.report_card_id == report_card.id
      assert profile_report_card_filter.class_id == class.id
    end

    test "create_profile_report_card_filter/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Personalization.create_profile_report_card_filter(@invalid_attrs)
    end

    test "update_profile_report_card_filter/2 with valid data updates the profile_report_card_filter" do
      profile_report_card_filter = profile_report_card_filter_fixture()
      class = Lanttern.SchoolsFixtures.class_fixture()
      update_attrs = %{class_id: class.id}

      assert {:ok, %ProfileReportCardFilter{} = profile_report_card_filter} =
               Personalization.update_profile_report_card_filter(
                 profile_report_card_filter,
                 update_attrs
               )

      assert profile_report_card_filter.class_id == class.id
    end

    test "update_profile_report_card_filter/2 with invalid data returns error changeset" do
      profile_report_card_filter = profile_report_card_filter_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Personalization.update_profile_report_card_filter(
                 profile_report_card_filter,
                 @invalid_attrs
               )

      assert profile_report_card_filter ==
               Personalization.get_profile_report_card_filter!(profile_report_card_filter.id)
    end

    test "delete_profile_report_card_filter/1 deletes the profile_report_card_filter" do
      profile_report_card_filter = profile_report_card_filter_fixture()

      assert {:ok, %ProfileReportCardFilter{}} =
               Personalization.delete_profile_report_card_filter(profile_report_card_filter)

      assert_raise Ecto.NoResultsError, fn ->
        Personalization.get_profile_report_card_filter!(profile_report_card_filter.id)
      end
    end

    test "change_profile_report_card_filter/1 returns a profile_report_card_filter changeset" do
      profile_report_card_filter = profile_report_card_filter_fixture()

      assert %Ecto.Changeset{} =
               Personalization.change_profile_report_card_filter(profile_report_card_filter)
    end
  end
end
