defmodule Lanttern.NotesTest do
  use Lanttern.DataCase

  alias Lanttern.Notes

  describe "notes" do
    alias Lanttern.Notes.Note

    import Lanttern.NotesFixtures
    import Lanttern.IdentityFixtures

    @invalid_attrs %{description: nil}

    test "list_notes/1 returns all notes" do
      note = note_fixture()
      assert Notes.list_notes() == [note]
    end

    test "list_notes/1 with preloads returns all notes with preloaded data" do
      author = teacher_profile_fixture()
      note = note_fixture(%{author_id: author.id})

      [expected] = Notes.list_notes(preloads: :author)
      assert expected.id == note.id
      assert expected.author.id == author.id
    end

    test "get_note!/2 returns the note with given id" do
      note = note_fixture()
      assert Notes.get_note!(note.id) == note
    end

    test "get_note!/2 with preloads returns the note with given id and preloaded data" do
      author = teacher_profile_fixture()
      note = note_fixture(%{author_id: author.id})

      expected = Notes.get_note!(note.id, preloads: :author)
      assert expected.id == note.id
      assert expected.author.id == author.id
    end

    test "create_note/1 with valid data creates a note" do
      author = teacher_profile_fixture()
      valid_attrs = %{author_id: author.id, description: "some description"}

      assert {:ok, %Note{} = note} = Notes.create_note(valid_attrs)
      assert note.author_id == author.id
      assert note.description == "some description"
    end

    test "create_note/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notes.create_note(@invalid_attrs)
    end

    test "update_note/2 with valid data updates the note" do
      note = note_fixture()
      update_attrs = %{description: "some updated description"}

      assert {:ok, %Note{} = note} = Notes.update_note(note, update_attrs)
      assert note.description == "some updated description"
    end

    test "update_note/2 with invalid data returns error changeset" do
      note = note_fixture()
      assert {:error, %Ecto.Changeset{}} = Notes.update_note(note, @invalid_attrs)
      assert note == Notes.get_note!(note.id)
    end

    test "delete_note/1 deletes the note" do
      note = note_fixture()
      assert {:ok, %Note{}} = Notes.delete_note(note)
      assert_raise Ecto.NoResultsError, fn -> Notes.get_note!(note.id) end
    end

    test "change_note/1 returns a note changeset" do
      note = note_fixture()
      assert %Ecto.Changeset{} = Notes.change_note(note)
    end
  end

  describe "strand notes" do
    alias Lanttern.Notes.Note

    import Lanttern.NotesFixtures
    import Lanttern.IdentityFixtures
    import Lanttern.LearningContextFixtures

    test "create_strand_note/2 with valid data creates a note linked to a strand" do
      author = teacher_profile_fixture()
      strand = strand_fixture()
      valid_attrs = %{"description" => "some strand note"}

      assert {:ok, %Note{} = note} =
               Notes.create_strand_note(
                 %{current_profile: author},
                 strand.id,
                 valid_attrs
               )

      assert note.author_id == author.id
      assert note.description == "some strand note"

      expected =
        Notes.get_user_note(%{current_profile: author}, strand_id: strand.id)

      assert expected.id == note.id
    end

    test "create_strand_note/2 with invalid data returns error changeset" do
      strand = strand_fixture()
      invalid_attrs = %{"description" => "some strand note"}

      assert {:error, %Ecto.Changeset{}} =
               Notes.create_strand_note(
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
               Notes.create_strand_note(%{current_profile: author}, strand.id, attrs)

      assert {:error, %Ecto.Changeset{}} =
               Notes.create_strand_note(%{current_profile: author}, strand.id, attrs)
    end

    test "list_user_notes/2 returns all user moments notes in a strand" do
      author = teacher_profile_fixture()
      strand = strand_fixture()
      moment_1 = moment_fixture(%{strand_id: strand.id, position: 1})
      note_1 = moment_note_fixture(%{current_profile: author}, moment_1.id)
      moment_2 = moment_fixture(%{strand_id: strand.id, position: 2})
      note_2 = moment_note_fixture(%{current_profile: author}, moment_2.id)

      assert [expected_1, expected_2] =
               Notes.list_user_notes(%{current_profile: author}, strand_id: strand.id)

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
               {^strand_1_note, expected_strand_1},
               {nil, expected_strand_2},
               {^strand_3_note, expected_strand_3},
               {nil, expected_strand_4}
             ] =
               Notes.list_student_strands_notes(
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
               Notes.get_student_note(author.student_id, strand_id: strand.id)

      assert expected_note.id == note.id
      assert expected_note.strand.id == strand.id
    end
  end

  describe "moment notes" do
    alias Lanttern.Notes.Note

    import Lanttern.NotesFixtures
    import Lanttern.IdentityFixtures
    import Lanttern.LearningContextFixtures

    test "create_moment_note/2 with valid data creates a note linked to a moment" do
      author = teacher_profile_fixture()
      moment = moment_fixture()
      valid_attrs = %{"author_id" => author.id, "description" => "some moment note"}

      assert {:ok, %Note{} = note} =
               Notes.create_moment_note(
                 %{current_profile: author},
                 moment.id,
                 valid_attrs
               )

      assert note.author_id == author.id
      assert note.description == "some moment note"

      expected =
        Notes.get_user_note(%{current_profile: author}, moment_id: moment.id)

      assert expected.id == note.id
    end

    test "create_moment_note/2 with invalid data returns error changeset" do
      moment = moment_fixture()
      invalid_attrs = %{"description" => "some moment note"}

      assert {:error, %Ecto.Changeset{}} =
               Notes.create_moment_note(
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
               Notes.create_moment_note(
                 %{current_profile: author},
                 moment.id,
                 attrs
               )

      assert {:error, %Ecto.Changeset{}} =
               Notes.create_moment_note(
                 %{current_profile: author},
                 moment.id,
                 attrs
               )
    end
  end
end
