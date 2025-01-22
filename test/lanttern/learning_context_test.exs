defmodule Lanttern.LearningContextTest do
  use Lanttern.DataCase

  alias Lanttern.LearningContext
  import Lanttern.LearningContextFixtures

  describe "strands" do
    alias Lanttern.LearningContext.Strand

    alias Lanttern.SchoolsFixtures
    alias Lanttern.ReportingFixtures
    import Lanttern.TaxonomyFixtures
    import Lanttern.AssessmentsFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_strands/1 returns all strands ordered alphabetically" do
      strand_a = strand_fixture(%{name: "AAA"})
      strand_c = strand_fixture(%{name: "CCC"})
      strand_b = strand_fixture(%{name: "BBB"})

      assert [strand_a, strand_b, strand_c] == LearningContext.list_strands()
    end

    test "list_strands/1 with preloads and filters returns all filtered strands with preloaded data" do
      subject_1 = subject_fixture()
      subject_2 = subject_fixture()
      year_1 = year_fixture()
      year_2 = year_fixture()

      strand_a =
        strand_fixture(%{
          name: "AAA",
          subjects_ids: [subject_1.id, subject_2.id],
          years_ids: [year_1.id, year_2.id]
        })

      strand_b =
        strand_fixture(%{name: "BBB", subjects_ids: [subject_1.id], years_ids: [year_2.id]})

      # extra strands for filtering
      strand_fixture()
      strand_fixture(%{subjects_ids: [subject_1.id, subject_2.id]})
      strand_fixture(%{years_ids: [year_1.id, year_2.id]})

      [expected_a, expected_b] =
        LearningContext.list_strands(
          subjects_ids: [subject_1.id, subject_2.id],
          years_ids: [year_1.id, year_2.id],
          preloads: [:subjects, :years]
        )

      assert expected_a.id == strand_a.id
      assert subject_1 in expected_a.subjects
      assert subject_2 in expected_a.subjects
      assert year_1 in expected_a.years
      assert year_2 in expected_a.years

      assert expected_b.id == strand_b.id
      assert [subject_1] == expected_b.subjects
      assert [year_2] == expected_b.years
    end

    test "list_strands/1 using cycle filters returns all strands as expected" do
      school = SchoolsFixtures.school_fixture()
      parent_cycle = SchoolsFixtures.cycle_fixture(%{school_id: school.id})

      cycle_a =
        SchoolsFixtures.cycle_fixture(%{school_id: school.id, parent_cycle_id: parent_cycle.id})

      cycle_b =
        SchoolsFixtures.cycle_fixture(%{school_id: school.id, parent_cycle_id: parent_cycle.id})

      strand_a = strand_fixture(%{name: "AAA"})
      strand_b = strand_fixture(%{name: "BBB"})

      report_card_a = ReportingFixtures.report_card_fixture(%{school_cycle_id: cycle_a.id})
      report_card_b = ReportingFixtures.report_card_fixture(%{school_cycle_id: cycle_b.id})

      _strand_a_report =
        ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card_a.id,
          strand_id: strand_a.id
        })

      _strand_b_report =
        ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card_b.id,
          strand_id: strand_b.id
        })

      # extra strands for filtering
      other_strand = strand_fixture()
      other_report_card = ReportingFixtures.report_card_fixture()

      _other_strand_report =
        ReportingFixtures.strand_report_fixture(%{
          report_card_id: other_report_card.id,
          strand_id: other_strand.id
        })

      # assert using parent cycle
      assert LearningContext.list_strands(parent_cycle_id: parent_cycle.id) == [
               strand_a,
               strand_b
             ]

      # assert using subcycle
      assert LearningContext.list_strands(cycles_ids: [cycle_a.id]) == [strand_a]
    end

    test "list_strands/1 with show_starred_for_profile_id returns all strands with is_starred field" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()
      strand_a = strand_fixture(%{name: "AAA"})
      strand_b = strand_fixture(%{name: "BBB"})

      # star strand a
      LearningContext.star_strand(strand_a.id, profile.id)

      [expected_a, expected_b] =
        LearningContext.list_strands(show_starred_for_profile_id: profile.id)

      assert expected_a.id == strand_a.id
      assert expected_a.is_starred == true
      assert expected_b.id == strand_b.id
      assert expected_b.is_starred == false
    end

    test "list_strands_page/1 with pagination opts returns all strands ordered alphabetically and paginated" do
      strand_a = strand_fixture(%{name: "AAA"})
      strand_c = strand_fixture(%{name: "CCC"})
      strand_b = strand_fixture(%{name: "BBB"})
      strand_d = strand_fixture(%{name: "DDD"})
      strand_e = strand_fixture(%{name: "EEE"})
      strand_f = strand_fixture(%{name: "FFF"})

      %{results: strands, keyset: keyset, has_next: true} =
        LearningContext.list_strands_page(first: 5)

      assert strands == [
               strand_a,
               strand_b,
               strand_c,
               strand_d,
               strand_e
             ]

      %{results: strands, has_next: false} =
        LearningContext.list_strands_page(first: 5, after: keyset)

      assert strands == [strand_f]
    end

    test "list_student_strands/2 returns all user strands related to students report cards (+ moment entries)" do
      student = Lanttern.SchoolsFixtures.student_fixture()

      subject_1 = Lanttern.TaxonomyFixtures.subject_fixture()
      subject_2 = Lanttern.TaxonomyFixtures.subject_fixture()
      year = Lanttern.TaxonomyFixtures.year_fixture()

      strand_1 =
        strand_fixture(%{subjects_ids: [subject_1.id, subject_2.id], years_ids: [year.id]})

      strand_2 = strand_fixture()
      strand_3 = strand_fixture()

      # use same strand in different reports
      strand_4 = strand_2

      # add moments to strand 1, following this structure
      # moment 1 - 2 assessment points, only first with student entry
      # moment 2 - 1 assessment point with student entry
      # moment 3 - no assessment points
      # expected entries return: m1_ap1, m2_ap1

      moment_1 = moment_fixture(%{strand_id: strand_1.id})
      moment_2 = moment_fixture(%{strand_id: strand_1.id})
      _moment_3 = moment_fixture(%{strand_id: strand_1.id})

      scale = Lanttern.GradingFixtures.scale_fixture(%{type: "ordinal"})
      ov = Lanttern.GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id})

      ap_m1_1 =
        Lanttern.AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_1.id,
          scale_id: scale.id
        })

      _ap_m1_2 =
        Lanttern.AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_1.id,
          scale_id: scale.id
        })

      ap_m2_1 =
        Lanttern.AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_2.id,
          scale_id: scale.id
        })

      entry_m1_1 =
        Lanttern.AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: ap_m1_1.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      entry_m2_1 =
        Lanttern.AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: ap_m2_1.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      # entry for other student
      _other_entry_m2_1 =
        Lanttern.AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: ap_m2_1.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      cycle_2024 =
        Lanttern.SchoolsFixtures.cycle_fixture(start_at: ~D[2024-01-01], end_at: ~D[2024-12-31])

      cycle_2023 =
        Lanttern.SchoolsFixtures.cycle_fixture(start_at: ~D[2023-01-01], end_at: ~D[2023-12-31])

      report_card_2024 =
        Lanttern.ReportingFixtures.report_card_fixture(%{school_cycle_id: cycle_2024.id})

      report_card_2023 =
        Lanttern.ReportingFixtures.report_card_fixture(%{school_cycle_id: cycle_2023.id})

      # create strand reports

      strand_report_1_2024 =
        Lanttern.ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card_2024.id,
          strand_id: strand_1.id
        })

      strand_report_2_2024 =
        Lanttern.ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card_2024.id,
          strand_id: strand_2.id
        })

      strand_report_3_2023 =
        Lanttern.ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card_2023.id,
          strand_id: strand_3.id
        })

      strand_report_4_2023 =
        Lanttern.ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card_2023.id,
          strand_id: strand_4.id
        })

      # create students report cards
      _ =
        Lanttern.ReportingFixtures.student_report_card_fixture(%{
          student_id: student.id,
          report_card_id: report_card_2024.id
        })

      _ =
        Lanttern.ReportingFixtures.student_report_card_fixture(%{
          student_id: student.id,
          report_card_id: report_card_2023.id
        })

      # extra fixtures for filter testing
      other_strand = strand_fixture()
      other_report_card = Lanttern.ReportingFixtures.report_card_fixture()

      _other_strand_report =
        Lanttern.ReportingFixtures.strand_report_fixture(%{
          report_card_id: other_report_card.id,
          strand_id: other_strand.id
        })

      _other_student_report_card =
        Lanttern.ReportingFixtures.student_report_card_fixture(%{
          student_id: student.id,
          report_card_id: other_report_card.id
        })

      assert [
               {expected_strand_1, [^entry_m1_1, ^entry_m2_1]},
               {expected_strand_2, []},
               {expected_strand_3, []},
               {expected_strand_4, []}
             ] =
               LearningContext.list_student_strands(
                 student.id,
                 cycles_ids: [cycle_2023.id, cycle_2024.id]
               )

      assert expected_strand_1.id == strand_1.id
      assert subject_1 in expected_strand_1.subjects
      assert subject_2 in expected_strand_1.subjects
      assert [year] == expected_strand_1.years
      assert expected_strand_1.strand_report_id == strand_report_1_2024.id
      assert expected_strand_1.report_cycle == cycle_2024

      assert expected_strand_2.id == strand_2.id
      assert expected_strand_2.strand_report_id == strand_report_2_2024.id
      assert expected_strand_2.report_cycle == cycle_2024

      assert expected_strand_3.id == strand_3.id
      assert expected_strand_3.strand_report_id == strand_report_3_2023.id
      assert expected_strand_3.report_cycle == cycle_2023

      assert expected_strand_4.id == strand_4.id
      assert expected_strand_4.strand_report_id == strand_report_4_2023.id
      assert expected_strand_4.report_cycle == cycle_2023
    end

    test "list_report_card_strands/1 returns all strands related to given report card with correct assessment points count" do
      strand_1 = strand_fixture()
      strand_2 = strand_fixture()
      strand_3 = strand_fixture()

      # moments and assessment points fixture
      # strand_1 = 3 moments, 1 assessment point each = 3 aps
      # strand_2 = 1 moment, 2 assessment points = 2 aps
      # strand_3 = 1 moment, no assessment points = 0 aps

      m_1_1 = moment_fixture(%{strand_id: strand_1.id})
      m_1_2 = moment_fixture(%{strand_id: strand_1.id})
      m_1_3 = moment_fixture(%{strand_id: strand_1.id})
      m_2_1 = moment_fixture(%{strand_id: strand_2.id})
      _m_3_1 = moment_fixture(%{strand_id: strand_3.id})

      _ap_1_1 = assessment_point_fixture(%{moment_id: m_1_1.id})
      _ap_1_2 = assessment_point_fixture(%{moment_id: m_1_2.id})
      _ap_1_3 = assessment_point_fixture(%{moment_id: m_1_3.id})
      _ap_2_1_1 = assessment_point_fixture(%{moment_id: m_2_1.id})
      _ap_2_1_2 = assessment_point_fixture(%{moment_id: m_2_1.id})

      report_card =
        Lanttern.ReportingFixtures.report_card_fixture()

      # create strand reports

      _strand_report_1 =
        Lanttern.ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand_1.id
        })

      _strand_report_2 =
        Lanttern.ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand_2.id
        })

      _strand_report_3 =
        Lanttern.ReportingFixtures.strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand_3.id
        })

      # use same strand in different reports
      _other_strand_3_report =
        Lanttern.ReportingFixtures.strand_report_fixture(%{
          strand_id: strand_3.id
        })

      # extra fixtures for filter testing
      other_strand = strand_fixture()
      other_report_card = Lanttern.ReportingFixtures.report_card_fixture()

      _other_strand_report =
        Lanttern.ReportingFixtures.strand_report_fixture(%{
          report_card_id: other_report_card.id,
          strand_id: other_strand.id
        })

      assert [expected_strand_1, expected_strand_2, expected_strand_3] =
               LearningContext.list_report_card_strands(report_card.id)

      assert expected_strand_1.id == strand_1.id
      assert expected_strand_1.assessment_points_count == 3

      assert expected_strand_2.id == strand_2.id
      assert expected_strand_2.assessment_points_count == 2

      assert expected_strand_3.id == strand_3.id
      assert expected_strand_3.assessment_points_count == 0
    end

    test "search_strands/2 returns all items matched by search" do
      _strand_1 = strand_fixture(%{name: "lorem ipsum xolor sit amet"})
      strand_2 = strand_fixture(%{name: "lorem ipsum dolor sit amet"})
      strand_3 = strand_fixture(%{name: "lorem ipsum dolorxxx sit amet"})
      _strand_4 = strand_fixture(%{name: "lorem ipsum xxxxx sit amet"})

      expected = LearningContext.search_strands("dolor")

      assert length(expected) == 2

      # assert order
      assert [strand_2, strand_3] == expected
    end

    test "get_strand!/2 returns the strand with given id" do
      strand = strand_fixture()
      assert LearningContext.get_strand!(strand.id) == strand
    end

    test "get_strand!/2 with preloads returns the strand with given id and preloaded data" do
      subject = subject_fixture()
      year = year_fixture()
      strand = strand_fixture(%{subjects_ids: [subject.id], years_ids: [year.id]})

      expected = LearningContext.get_strand!(strand.id, preloads: [:subjects, :years])
      assert expected.id == strand.id
      assert expected.subjects == [subject]
      assert expected.years == [year]
    end

    test "get_strand/2 with show_starred_for_profile_id returns the strand with is_starred field" do
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()
      strand = strand_fixture()

      # assert without starring

      expected = LearningContext.get_strand(strand.id, show_starred_for_profile_id: profile.id)

      assert expected.id == strand.id
      assert expected.is_starred == false

      # star strand and assert again
      LearningContext.star_strand(strand.id, profile.id)

      expected = LearningContext.get_strand(strand.id, show_starred_for_profile_id: profile.id)

      assert expected.id == strand.id
      assert expected.is_starred
    end

    test "create_strand/1 with valid data creates a strand" do
      subject = subject_fixture()
      year = year_fixture()

      valid_attrs = %{
        name: "some name",
        description: "some description",
        subjects_ids: [subject.id],
        years_ids: [year.id]
      }

      assert {:ok, %Strand{} = strand} = LearningContext.create_strand(valid_attrs)
      assert strand.name == "some name"
      assert strand.description == "some description"
      assert strand.subjects == [subject]
      assert strand.years == [year]
    end

    test "create_strand/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = LearningContext.create_strand(@invalid_attrs)
    end

    test "update_strand/2 with valid data updates the strand" do
      subject = subject_fixture()
      year_1 = year_fixture()
      year_2 = year_fixture()

      # subject is irrevelant, should be replaced
      # year is revelant, we'll keep it after update
      strand =
        strand_fixture(%{
          subjects_ids: [subject_fixture().id],
          years_ids: [year_1.id]
        })

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        subjects_ids: [subject.id],
        years_ids: [year_1.id, year_2.id]
      }

      assert {:ok, %Strand{} = strand} = LearningContext.update_strand(strand, update_attrs)
      assert strand.name == "some updated name"
      assert strand.description == "some updated description"
      assert strand.subjects == [subject]
      assert strand.years == [year_1, year_2] || strand.years == [year_2, year_1]
    end

    test "update_strand/2 with invalid data returns error changeset" do
      strand = strand_fixture()
      assert {:error, %Ecto.Changeset{}} = LearningContext.update_strand(strand, @invalid_attrs)
      assert strand == LearningContext.get_strand!(strand.id)
    end

    test "delete_strand/1 deletes the strand" do
      strand = strand_fixture()
      assert {:ok, %Strand{}} = LearningContext.delete_strand(strand)
      assert_raise Ecto.NoResultsError, fn -> LearningContext.get_strand!(strand.id) end
    end

    test "change_strand/1 returns a strand changeset" do
      strand = strand_fixture()
      assert %Ecto.Changeset{} = LearningContext.change_strand(strand)
    end
  end

  describe "starred strands" do
    alias Lanttern.LearningContext.Strand

    import Lanttern.IdentityFixtures
    import Lanttern.TaxonomyFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_strands/1 with only_starred opt returns all starred strands ordered alphabetically" do
      profile = teacher_profile_fixture()
      strand_b = strand_fixture(%{name: "BBB"}) |> Map.put(:is_starred, true)
      strand_a = strand_fixture(%{name: "AAA"}) |> Map.put(:is_starred, true)

      # extra strand to test filtering
      strand_fixture()

      # star strands a and b
      LearningContext.star_strand(strand_a.id, profile.id)
      LearningContext.star_strand(strand_b.id, profile.id)

      assert [strand_a, strand_b] ==
               LearningContext.list_strands(
                 show_starred_for_profile_id: profile.id,
                 only_starred: true
               )
    end

    test "list_strands/1 with only_starred, preloads, and filters returns all filtered starred strands with preloaded data" do
      profile = teacher_profile_fixture()
      subject_1 = subject_fixture()
      subject_2 = subject_fixture()
      year = year_fixture()
      strand = strand_fixture(%{subjects_ids: [subject_1.id, subject_2.id], years_ids: [year.id]})

      # extra strands for filtering
      other_strand = strand_fixture()
      strand_fixture(%{subjects_ids: [subject_1.id, subject_2.id], years_ids: [year.id]})

      # star strand
      LearningContext.star_strand(strand.id, profile.id)
      LearningContext.star_strand(other_strand.id, profile.id)

      [expected] =
        LearningContext.list_strands(
          show_starred_for_profile_id: profile.id,
          only_starred: true,
          subjects_ids: [subject_1.id, subject_2.id],
          years_ids: [year.id],
          preloads: [:subjects, :years]
        )

      assert expected.id == strand.id
      assert subject_1 in expected.subjects
      assert subject_2 in expected.subjects
      assert expected.years == [year]
    end

    test "star_strand/2 and unstar_strand/2 functions as expected" do
      profile = teacher_profile_fixture()
      strand_a = strand_fixture(%{name: "AAA"}) |> Map.put(:is_starred, true)
      strand_b = strand_fixture(%{name: "BBB"}) |> Map.put(:is_starred, true)

      # empty list before starring
      assert [] ==
               LearningContext.list_strands(
                 show_starred_for_profile_id: profile.id,
                 only_starred: true
               )

      # star and list again
      LearningContext.star_strand(strand_a.id, profile.id)
      LearningContext.star_strand(strand_b.id, profile.id)

      assert [strand_a, strand_b] ==
               LearningContext.list_strands(
                 show_starred_for_profile_id: profile.id,
                 only_starred: true
               )

      # staring an already starred strand shouldn't cause any change
      assert {:ok, _starred_strand} = LearningContext.star_strand(strand_a.id, profile.id)

      assert [strand_a, strand_b] ==
               LearningContext.list_strands(
                 show_starred_for_profile_id: profile.id,
                 only_starred: true
               )

      # unstar and list
      LearningContext.unstar_strand(strand_a.id, profile.id)

      assert [strand_b] ==
               LearningContext.list_strands(
                 show_starred_for_profile_id: profile.id,
                 only_starred: true
               )
    end
  end

  describe "moments" do
    alias Lanttern.LearningContext.Moment

    import Lanttern.TaxonomyFixtures

    @invalid_attrs %{name: nil, position: nil, description: nil}

    test "list_moments/1 returns all moments" do
      moment = moment_fixture()
      assert LearningContext.list_moments() == [moment]
    end

    test "list_moments/1 with preloads returns all moments with preloaded data" do
      strand = strand_fixture()
      subject = subject_fixture()
      moment = moment_fixture(%{strand_id: strand.id, subjects_ids: [subject.id]})

      [expected] = LearningContext.list_moments(preloads: [:subjects, :strand])
      assert expected.id == moment.id
      assert expected.strand == strand
      assert expected.subjects == [subject]
    end

    test "list_moments/1 with strands filter returns moments filtered" do
      strand = strand_fixture()
      subject = subject_fixture()
      moment = moment_fixture(%{strand_id: strand.id, subjects_ids: [subject.id]})

      # extra moments for filter testing
      moment_fixture()
      moment_fixture()

      [expected] = LearningContext.list_moments(strands_ids: [strand.id], preloads: :subjects)
      assert expected.id == moment.id
      assert expected.subjects == [subject]
    end

    test "get_moment!/2 returns the moment with given id" do
      moment = moment_fixture()
      assert LearningContext.get_moment!(moment.id) == moment
    end

    test "get_moment!/2 with preloads returns the moment with given id and preloaded data" do
      strand = strand_fixture()
      subject = subject_fixture()
      moment = moment_fixture(%{strand_id: strand.id, subjects_ids: [subject.id]})

      expected = LearningContext.get_moment!(moment.id, preloads: [:strand, :subjects])
      assert expected.id == moment.id
      assert expected.strand == strand
      assert expected.subjects == [subject]
    end

    test "create_moment/1 with valid data creates a moment" do
      subject = subject_fixture()

      valid_attrs = %{
        name: "some name",
        position: 42,
        description: "some description",
        strand_id: strand_fixture().id,
        subjects_ids: [subject.id]
      }

      assert {:ok, %Moment{} = moment} = LearningContext.create_moment(valid_attrs)
      assert moment.name == "some name"
      assert moment.position == 42
      assert moment.description == "some description"
      assert moment.subjects == [subject]
    end

    test "create_moment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = LearningContext.create_moment(@invalid_attrs)
    end

    test "update_moment/2 with valid data updates the moment" do
      moment = moment_fixture(%{subjects_ids: [subject_fixture().id]})
      subject = subject_fixture()

      update_attrs = %{
        name: "some updated name",
        position: 43,
        description: "some updated description",
        subjects_ids: [subject.id]
      }

      assert {:ok, %Moment{} = moment} =
               LearningContext.update_moment(moment, update_attrs)

      assert moment.name == "some updated name"
      assert moment.position == 43
      assert moment.description == "some updated description"
      assert moment.subjects == [subject]
    end

    test "update_moment/2 with invalid data returns error changeset" do
      moment = moment_fixture()

      assert {:error, %Ecto.Changeset{}} =
               LearningContext.update_moment(moment, @invalid_attrs)

      assert moment == LearningContext.get_moment!(moment.id)
    end

    test "update_strand_moments_positions/2 update strand moments position based on list order" do
      strand = strand_fixture()
      moment_1 = moment_fixture(%{strand_id: strand.id})
      moment_2 = moment_fixture(%{strand_id: strand.id})
      moment_3 = moment_fixture(%{strand_id: strand.id})
      moment_4 = moment_fixture(%{strand_id: strand.id})

      sorted_moments_ids =
        [
          moment_2.id,
          moment_3.id,
          moment_1.id,
          moment_4.id
        ]

      assert {:ok,
              [
                expected_2,
                expected_3,
                expected_1,
                expected_4
              ]} =
               LearningContext.update_strand_moments_positions(
                 strand.id,
                 sorted_moments_ids
               )

      assert expected_1.id == moment_1.id
      assert expected_2.id == moment_2.id
      assert expected_3.id == moment_3.id
      assert expected_4.id == moment_4.id
    end

    test "delete_moment/1 deletes the moment" do
      moment = moment_fixture()
      assert {:ok, %Moment{}} = LearningContext.delete_moment(moment)
      assert_raise Ecto.NoResultsError, fn -> LearningContext.get_moment!(moment.id) end
    end

    test "change_moment/1 returns a moment changeset" do
      moment = moment_fixture()
      assert %Ecto.Changeset{} = LearningContext.change_moment(moment)
    end
  end

  describe "moment_cards" do
    alias Lanttern.LearningContext.MomentCard

    import Lanttern.LearningContextFixtures
    alias Lanttern.IdentityFixtures
    alias Lanttern.Attachments

    @invalid_attrs %{name: nil, position: nil, description: nil}

    test "list_moment_cards/1 returns all moment_cards" do
      moment_card = moment_card_fixture()
      assert LearningContext.list_moment_cards() == [moment_card]
    end

    test "list_moment_cards/1 with moments filter returns moment cards filtered and ordered by position" do
      moment = moment_fixture()

      # create moment card should handle positioning
      moment_card_1 = moment_card_fixture(%{moment_id: moment.id})
      moment_card_2 = moment_card_fixture(%{moment_id: moment.id})

      # extra moment cards for filter testing
      moment_card_fixture()
      moment_card_fixture()

      assert [moment_card_1, moment_card_2] ==
               LearningContext.list_moment_cards(moments_ids: [moment.id])
    end

    test "list_moment_cards/1 with count_attachments opt returns moment cards with calculated attachments_count field" do
      moment_card = moment_card_fixture()
      profile = IdentityFixtures.teacher_profile_fixture()

      {:ok, _attachment} =
        LearningContext.create_moment_card_attachment(
          profile.id,
          moment_card.id,
          %{"name" => "attachment", "link" => "https://somevaliduri.com"}
        )

      assert LearningContext.list_moment_cards(count_attachments: true) == [
               %{moment_card | attachments_count: 1}
             ]
    end

    test "get_moment_card!/1 returns the moment_card with given id" do
      moment_card = moment_card_fixture()
      assert LearningContext.get_moment_card!(moment_card.id) == moment_card
    end

    test "get_moment_card/2 with count_attachments opt returns moment card with calculated attachments_count field" do
      moment_card = moment_card_fixture()
      profile = IdentityFixtures.teacher_profile_fixture()

      {:ok, _attachment} =
        LearningContext.create_moment_card_attachment(
          profile.id,
          moment_card.id,
          %{"name" => "attachment", "link" => "https://somevaliduri.com"}
        )

      assert LearningContext.get_moment_card(moment_card.id, count_attachments: true) == %{
               moment_card
               | attachments_count: 1
             }
    end

    test "create_moment_card/1 with valid data creates a moment_card" do
      moment = moment_fixture()

      valid_attrs = %{
        name: "some name",
        position: 42,
        description: "some description",
        moment_id: moment.id
      }

      assert {:ok, %MomentCard{} = moment_card} = LearningContext.create_moment_card(valid_attrs)
      assert moment_card.name == "some name"
      assert moment_card.position == 42
      assert moment_card.description == "some description"
      assert moment_card.moment_id == moment.id
    end

    test "create_moment_card/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = LearningContext.create_moment_card(@invalid_attrs)
    end

    test "update_moment_card/2 with valid data updates the moment_card" do
      moment_card = moment_card_fixture()

      update_attrs = %{
        name: "some updated name",
        position: 43,
        description: "some updated description"
      }

      assert {:ok, %MomentCard{} = moment_card} =
               LearningContext.update_moment_card(moment_card, update_attrs)

      assert moment_card.name == "some updated name"
      assert moment_card.position == 43
      assert moment_card.description == "some updated description"
    end

    test "update_moment_card/2 with invalid data returns error changeset" do
      moment_card = moment_card_fixture()

      assert {:error, %Ecto.Changeset{}} =
               LearningContext.update_moment_card(moment_card, @invalid_attrs)

      assert moment_card == LearningContext.get_moment_card!(moment_card.id)
    end

    test "delete_moment_card/1 deletes the moment_card and its linked attachments" do
      moment_card = moment_card_fixture()
      profile = IdentityFixtures.teacher_profile_fixture()

      {:ok, attachment} =
        LearningContext.create_moment_card_attachment(
          profile.id,
          moment_card.id,
          %{"name" => "attachment", "link" => "https://somevaliduri.com"}
        )

      assert {:ok, %MomentCard{}} = LearningContext.delete_moment_card(moment_card)
      assert_raise Ecto.NoResultsError, fn -> LearningContext.get_moment_card!(moment_card.id) end
      assert_raise Ecto.NoResultsError, fn -> Attachments.get_attachment!(attachment.id) end

      on_exit(fn ->
        assert_supervised_tasks_are_down()
      end)
    end

    test "change_moment_card/1 returns a moment_card changeset" do
      moment_card = moment_card_fixture()
      assert %Ecto.Changeset{} = LearningContext.change_moment_card(moment_card)
    end
  end
end
