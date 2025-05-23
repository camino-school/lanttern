defmodule Lanttern.ReportingTest do
  use Lanttern.DataCase

  alias Lanttern.Reporting

  describe "report_cards" do
    alias Lanttern.Reporting.ReportCard

    import Lanttern.ReportingFixtures
    alias Lanttern.SchoolsFixtures
    alias Lanttern.TaxonomyFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_report_cards/1 returns all report_cards" do
      report_card = report_card_fixture()
      assert Reporting.list_report_cards() == [report_card]
    end

    test "list_report_cards/1 with preloads returns all report_cards with preloaded data" do
      school_cycle = SchoolsFixtures.cycle_fixture()
      report_card = report_card_fixture(%{school_cycle_id: school_cycle.id})

      [expected] = Reporting.list_report_cards(preloads: :school_cycle)

      assert expected.id == report_card.id
      assert expected.school_cycle.id == school_cycle.id
    end

    test "list_report_cards/1 with strand filters returns all filtered report_cards" do
      report_card = report_card_fixture()
      strand = Lanttern.LearningContextFixtures.strand_fixture()
      strand_report_fixture(%{report_card_id: report_card.id, strand_id: strand.id})

      # extra report cards for filtering test
      report_card_fixture()
      strand_report_fixture()

      [expected] = Reporting.list_report_cards(strands_ids: [strand.id])

      assert expected.id == report_card.id
    end

    test "list_report_cards/1 with school filter returns all school report_cards" do
      cycle = SchoolsFixtures.cycle_fixture()
      report_card = report_card_fixture(%{school_cycle_id: cycle.id})

      # extra report cards for filtering test
      report_card_fixture()

      [expected] = Reporting.list_report_cards(school_id: cycle.school_id)

      assert expected.id == report_card.id
    end

    test "list_report_cards/1 with year/cycle filters returns all filtered report_cards" do
      year = TaxonomyFixtures.year_fixture()
      cycle = SchoolsFixtures.cycle_fixture()
      report_card = report_card_fixture(%{school_cycle_id: cycle.id, year_id: year.id})

      # extra report cards for filtering test
      report_card_fixture()
      report_card_fixture(%{year_id: year.id})
      report_card_fixture(%{school_cycle_id: cycle.id})

      [expected] = Reporting.list_report_cards(years_ids: [year.id], cycles_ids: [cycle.id])

      assert expected.id == report_card.id
    end

    test "list_report_cards/1 with parent cycle filter returns report_cards linked to the subcycles of given parent cycle" do
      school = Lanttern.SchoolsFixtures.school_fixture()
      parent_cycle = Lanttern.SchoolsFixtures.cycle_fixture(%{school_id: school.id})

      subcycle =
        Lanttern.SchoolsFixtures.cycle_fixture(%{
          school_id: school.id,
          parent_cycle_id: parent_cycle.id
        })

      report_card = report_card_fixture(%{school_cycle_id: subcycle.id})

      # extra report cards for filtering test
      other_parent_cycle = Lanttern.SchoolsFixtures.cycle_fixture(%{school_id: school.id})

      other_subcycle =
        Lanttern.SchoolsFixtures.cycle_fixture(%{
          school_id: school.id,
          parent_cycle_id: other_parent_cycle.id
        })

      report_card_fixture(%{school_cycle_id: other_subcycle.id})

      [expected] = Reporting.list_report_cards(parent_cycle_id: parent_cycle.id)
      assert expected.id == report_card.id
    end

    test "list_report_cards_by_cycle/0 returns report_cards grouped by cycle" do
      school = SchoolsFixtures.school_fixture()

      cycle_2024 =
        SchoolsFixtures.cycle_fixture(%{
          school_id: school.id,
          start_at: ~D[2024-01-01],
          end_at: ~D[2024-12-31]
        })

      cycle_2023 =
        SchoolsFixtures.cycle_fixture(%{
          school_id: school.id,
          start_at: ~D[2023-01-01],
          end_at: ~D[2023-12-31]
        })

      report_card_2024_1 = report_card_fixture(%{school_cycle_id: cycle_2024.id, name: "AAA"})
      report_card_2024_2 = report_card_fixture(%{school_cycle_id: cycle_2024.id, name: "BBB"})
      report_card_2023_1 = report_card_fixture(%{school_cycle_id: cycle_2023.id})

      assert [
               {expected_cycle_2024, [expected_report_2024_1, expected_report_2024_2]},
               {expected_cycle_2023, [expected_report_2023_1]}
             ] = Reporting.list_report_cards_by_cycle()

      assert expected_cycle_2024.id == cycle_2024.id
      assert expected_report_2024_1.id == report_card_2024_1.id
      assert expected_report_2024_2.id == report_card_2024_2.id

      assert expected_cycle_2023.id == cycle_2023.id
      assert expected_report_2023_1.id == report_card_2023_1.id
    end

    test "get_report_card!/2 returns the report_card with given id" do
      report_card = report_card_fixture()
      assert Reporting.get_report_card!(report_card.id) == report_card
    end

    test "get_report_card!/2 with preloads returns the report_card with given id and preloaded data" do
      report_card = report_card_fixture()
      strand_report = strand_report_fixture(%{report_card_id: report_card.id})

      expected = Reporting.get_report_card!(report_card.id, preloads: :strand_reports)

      assert expected.id == report_card.id
      assert expected.strand_reports == [strand_report]
    end

    test "create_report_card/1 with valid data creates a report_card" do
      school_cycle = SchoolsFixtures.cycle_fixture()
      year = TaxonomyFixtures.year_fixture()

      valid_attrs = %{
        name: "some name",
        description: "some description",
        school_cycle_id: school_cycle.id,
        year_id: year.id
      }

      assert {:ok, %ReportCard{} = report_card} = Reporting.create_report_card(valid_attrs)
      assert report_card.name == "some name"
      assert report_card.description == "some description"
    end

    test "create_report_card/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Reporting.create_report_card(@invalid_attrs)
    end

    test "update_report_card/2 with valid data updates the report_card" do
      report_card = report_card_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %ReportCard{} = report_card} =
               Reporting.update_report_card(report_card, update_attrs)

      assert report_card.name == "some updated name"
      assert report_card.description == "some updated description"
    end

    test "update_report_card/2 with invalid data returns error changeset" do
      report_card = report_card_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Reporting.update_report_card(report_card, @invalid_attrs)

      assert report_card == Reporting.get_report_card!(report_card.id)
    end

    test "delete_report_card/1 deletes the report_card" do
      report_card = report_card_fixture()
      assert {:ok, %ReportCard{}} = Reporting.delete_report_card(report_card)
      assert_raise Ecto.NoResultsError, fn -> Reporting.get_report_card!(report_card.id) end
    end

    test "change_report_card/1 returns a report_card changeset" do
      report_card = report_card_fixture()
      assert %Ecto.Changeset{} = Reporting.change_report_card(report_card)
    end
  end

  describe "strand_reports" do
    alias Lanttern.Reporting.StrandReport

    import Lanttern.ReportingFixtures

    @invalid_attrs %{report_card_id: nil}

    test "list_strands_reports/1 returns all strand_reports" do
      strand_report = strand_report_fixture()
      assert Reporting.list_strands_reports() == [strand_report]
    end

    test "list_strands_reports/1 with preloads returns all strand_reports with preloaded data" do
      report_card = report_card_fixture()
      strand_report = strand_report_fixture(%{report_card_id: report_card.id})

      assert [expected_strand_report] = Reporting.list_strands_reports(preloads: :report_card)
      assert expected_strand_report.id == strand_report.id
      assert expected_strand_report.report_card.id == report_card.id
    end

    test "list_strands_reports/1 with report card filter returns all strand_reports filtered by report card" do
      report_card = report_card_fixture()

      strand_report_1 = strand_report_fixture(%{report_card_id: report_card.id})
      strand_report_2 = strand_report_fixture(%{report_card_id: report_card.id})

      # extra strand report fixture to test filter
      strand_report_fixture()

      assert Reporting.list_strands_reports(report_card_id: report_card.id) == [
               strand_report_1,
               strand_report_2
             ]
    end

    test "get_strand_report!/2 returns the strand_report with given id" do
      strand_report = strand_report_fixture()
      assert Reporting.get_strand_report!(strand_report.id) == strand_report
    end

    test "get_strand_report!/2 with preloads returns the strand report with given id and preloaded data" do
      strand = Lanttern.LearningContextFixtures.strand_fixture()
      strand_report = strand_report_fixture(%{strand_id: strand.id})

      expected =
        Reporting.get_strand_report!(strand_report.id, preloads: :strand)

      assert expected.id == strand_report.id
      assert expected.strand == strand
    end

    test "get_strand_report/2 with check_if_has_moments opts calculate has_moments field" do
      strand = Lanttern.LearningContextFixtures.strand_fixture()
      _moment = Lanttern.LearningContextFixtures.moment_fixture(%{strand_id: strand.id})
      strand_report = strand_report_fixture(%{strand_id: strand.id})

      expected =
        Reporting.get_strand_report!(strand_report.id, check_if_has_moments: true)

      assert expected.id == strand_report.id
      assert expected.has_moments
    end

    test "create_strand_report/1 with valid data creates a strand_report" do
      report_card = report_card_fixture()
      strand = Lanttern.LearningContextFixtures.strand_fixture()

      valid_attrs = %{
        report_card_id: report_card.id,
        strand_id: strand.id,
        description: "some description",
        position: 1
      }

      assert {:ok, %StrandReport{} = strand_report} = Reporting.create_strand_report(valid_attrs)
      assert strand_report.description == "some description"
    end

    test "create_strand_report/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Reporting.create_strand_report(@invalid_attrs)
    end

    test "update_strand_report/2 with valid data updates the strand_report" do
      strand_report = strand_report_fixture()
      update_attrs = %{description: "some updated description"}

      assert {:ok, %StrandReport{} = strand_report} =
               Reporting.update_strand_report(strand_report, update_attrs)

      assert strand_report.description == "some updated description"
    end

    test "update_strand_report/2 with invalid data returns error changeset" do
      strand_report = strand_report_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Reporting.update_strand_report(strand_report, @invalid_attrs)

      assert strand_report == Reporting.get_strand_report!(strand_report.id)
    end

    test "update_strands_reports_positions/1 update strands reports positions based on list order" do
      report_card = report_card_fixture()
      strand_report_1 = strand_report_fixture(%{report_card_id: report_card.id, position: 1})
      strand_report_2 = strand_report_fixture(%{report_card_id: report_card.id, position: 2})
      strand_report_3 = strand_report_fixture(%{report_card_id: report_card.id, position: 3})
      strand_report_4 = strand_report_fixture(%{report_card_id: report_card.id, position: 4})

      sorted_strands_reports_ids =
        [
          strand_report_2.id,
          strand_report_3.id,
          strand_report_1.id,
          strand_report_4.id
        ]

      assert :ok == Reporting.update_strands_reports_positions(sorted_strands_reports_ids)

      assert [
               expected_sr_2,
               expected_sr_3,
               expected_sr_1,
               expected_sr_4
             ] =
               Reporting.list_strands_reports(report_card_id: report_card.id)

      assert expected_sr_1.id == strand_report_1.id
      assert expected_sr_2.id == strand_report_2.id
      assert expected_sr_3.id == strand_report_3.id
      assert expected_sr_4.id == strand_report_4.id
    end

    test "delete_strand_report/1 deletes the strand_report" do
      strand_report = strand_report_fixture()
      assert {:ok, %StrandReport{}} = Reporting.delete_strand_report(strand_report)
      assert_raise Ecto.NoResultsError, fn -> Reporting.get_strand_report!(strand_report.id) end
    end

    test "change_strand_report/1 returns a strand_report changeset" do
      strand_report = strand_report_fixture()
      assert %Ecto.Changeset{} = Reporting.change_strand_report(strand_report)
    end
  end

  describe "student_report_cards" do
    alias Lanttern.Reporting.StudentReportCard

    import Lanttern.ReportingFixtures

    alias Lanttern.SchoolsFixtures
    alias Lanttern.TaxonomyFixtures

    @invalid_attrs %{report_card_id: nil, comment: nil, footnote: nil}

    test "list_student_report_cards/1 returns all student_report_cards" do
      student_report_card = student_report_card_fixture()
      assert Reporting.list_student_report_cards() == [student_report_card]
    end

    test "list_student_report_cards/1 with student filter returns all student_report_cards of the given student" do
      student = SchoolsFixtures.student_fixture()

      cycle_2023 =
        SchoolsFixtures.cycle_fixture(%{start_at: ~D[2023-01-01], end_at: ~D[2023-12-31]})

      cycle_2024_q4 =
        SchoolsFixtures.cycle_fixture(%{start_at: ~D[2024-10-01], end_at: ~D[2024-12-31]})

      cycle_2024 =
        SchoolsFixtures.cycle_fixture(%{start_at: ~D[2024-01-01], end_at: ~D[2024-12-31]})

      report_card_2023 = report_card_fixture(%{school_cycle_id: cycle_2023.id})
      report_card_2024_q4 = report_card_fixture(%{school_cycle_id: cycle_2024_q4.id})
      report_card_2024 = report_card_fixture(%{school_cycle_id: cycle_2024.id})

      student_report_card_2023 =
        student_report_card_fixture(%{
          report_card_id: report_card_2023.id,
          student_id: student.id
        })

      student_report_card_2024_q4 =
        student_report_card_fixture(%{
          report_card_id: report_card_2024_q4.id,
          student_id: student.id
        })

      student_report_card_2024 =
        student_report_card_fixture(%{
          report_card_id: report_card_2024.id,
          student_id: student.id
        })

      # extra fixtures for filter testing
      student_report_card_fixture(%{report_card_id: report_card_2023.id})
      student_report_card_fixture()

      # report should be ordered by cycle end date desc and start date asc
      assert Reporting.list_student_report_cards(student_id: student.id) == [
               student_report_card_2024,
               student_report_card_2024_q4,
               student_report_card_2023
             ]
    end

    test "list_student_report_cards/1 with ids opt returns student_report_cards filtered by ids" do
      student_report_card_1 = student_report_card_fixture()
      student_report_card_2 = student_report_card_fixture()
      student_report_card_3 = student_report_card_fixture()

      # extra fixtures for filter testing
      student_report_card_fixture()
      student_report_card_fixture()

      ids = [
        student_report_card_1.id,
        student_report_card_2.id,
        student_report_card_3.id
      ]

      # report should be ordered by cycle end date desc and start date asc
      assert [expected_a, expected_b, expected_c] = Reporting.list_student_report_cards(ids: ids)
      assert expected_a.id in ids
      assert expected_b.id in ids
      assert expected_c.id in ids
    end

    test "list_student_report_cards/1 with parent cycle filter returns all student_report_cards of the given cycle" do
      school = SchoolsFixtures.school_fixture()
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})

      cycle = SchoolsFixtures.cycle_fixture(%{school_id: school.id})
      subcycle = SchoolsFixtures.cycle_fixture(%{school_id: school.id, parent_cycle_id: cycle.id})

      report_card = report_card_fixture(%{school_cycle_id: subcycle.id})

      student_report_card =
        student_report_card_fixture(%{report_card_id: report_card.id, student_id: student.id})

      # extra fixtures for filter testing
      other_cycle = SchoolsFixtures.cycle_fixture(%{school_id: school.id})

      other_subcycle =
        SchoolsFixtures.cycle_fixture(%{school_id: school.id, parent_cycle_id: other_cycle.id})

      other_report_card = report_card_fixture(%{school_cycle_id: other_subcycle.id})

      _other_student_report_card =
        student_report_card_fixture(%{
          report_card_id: other_report_card.id,
          student_id: student.id
        })

      student_report_card_fixture()

      assert Reporting.list_student_report_cards(
               student_id: student.id,
               parent_cycle_id: cycle.id
             ) == [
               student_report_card
             ]
    end

    test "list_students_linked_to_report_card/2 with active_students_only returns all active students with class and linked report cards" do
      school = SchoolsFixtures.school_fixture()
      year = TaxonomyFixtures.year_fixture()
      parent_cycle = SchoolsFixtures.cycle_fixture(%{school_id: school.id})

      cycle =
        SchoolsFixtures.cycle_fixture(%{school_id: school.id, parent_cycle_id: parent_cycle.id})

      class_a =
        SchoolsFixtures.class_fixture(%{
          name: "AAA",
          school_id: school.id,
          cycle_id: parent_cycle.id,
          years_ids: [year.id]
        })

      student_a_a =
        SchoolsFixtures.student_fixture(%{
          name: "AAA",
          school_id: school.id,
          classes_ids: [class_a.id]
        })

      student_a_b =
        SchoolsFixtures.student_fixture(%{
          name: "BBB",
          school_id: school.id,
          classes_ids: [class_a.id]
        })

      deactivated_student_a_c =
        SchoolsFixtures.student_fixture(%{
          name: "CCC",
          school_id: school.id,
          classes_ids: [class_a.id],
          deactivated_at: ~U[2022-01-12 00:01:00.00Z]
        })

      class_j =
        SchoolsFixtures.class_fixture(%{
          name: "JJJ",
          school_id: school.id,
          cycle_id: parent_cycle.id,
          years_ids: [year.id]
        })

      student_j_j =
        SchoolsFixtures.student_fixture(%{
          name: "JJJ",
          school_id: school.id,
          classes_ids: [class_j.id]
        })

      # without report card
      student_j_k =
        SchoolsFixtures.student_fixture(%{
          name: "KKK",
          school_id: school.id,
          classes_ids: [class_j.id]
        })

      class_z =
        SchoolsFixtures.class_fixture(%{
          name: "ZZZ",
          school_id: school.id,
          cycle_id: parent_cycle.id,
          years_ids: [year.id]
        })

      student_z_z =
        SchoolsFixtures.student_fixture(%{
          name: "ZZZ",
          school_id: school.id,
          classes_ids: [class_z.id]
        })

      # cycle info to test profile_picture_url load
      student_a_a_cycle_info =
        Lanttern.StudentsCycleInfoFixtures.student_cycle_info_fixture(%{
          school_id: school.id,
          cycle_id: parent_cycle.id,
          student_id: student_a_a.id,
          profile_picture_url: "http://example-a-a.com/profile_picture.jpg"
        })

      student_j_k_cycle_info =
        Lanttern.StudentsCycleInfoFixtures.student_cycle_info_fixture(%{
          school_id: school.id,
          cycle_id: parent_cycle.id,
          student_id: student_j_k.id,
          profile_picture_url: "http://example-j-k.com/profile_picture.jpg"
        })

      # extra fixtures
      other_year_class =
        SchoolsFixtures.class_fixture(%{school_id: school.id, cycle_id: parent_cycle.id})

      _other_year_student =
        SchoolsFixtures.student_fixture(%{
          name: "student from other year",
          school_id: school.id,
          classes_ids: [other_year_class.id]
        })

      other_cycle_class =
        SchoolsFixtures.class_fixture(%{school_id: school.id, years_ids: [year.id]})

      _other_cycle_student =
        SchoolsFixtures.student_fixture(%{
          name: "student from other cycle",
          school_id: school.id,
          classes_ids: [other_cycle_class.id]
        })

      _deactivated_student =
        SchoolsFixtures.student_fixture(%{
          school_id: school.id,
          classes_ids: [class_j.id],
          deactivated_at: ~U[2022-01-12 00:01:00.00Z]
        })

      report_card =
        report_card_fixture(%{school_cycle_id: cycle.id, year_id: year.id})
        |> Repo.preload([:school_cycle, :year])

      student_a_a_report_card =
        student_report_card_fixture(%{report_card_id: report_card.id, student_id: student_a_a.id})

      student_a_b_report_card =
        student_report_card_fixture(%{report_card_id: report_card.id, student_id: student_a_b.id})

      _deactivated_student_a_c_report_card =
        student_report_card_fixture(%{
          report_card_id: report_card.id,
          student_id: deactivated_student_a_c.id
        })

      student_j_j_report_card =
        student_report_card_fixture(%{report_card_id: report_card.id, student_id: student_j_j.id})

      _student_z_z_report_card =
        student_report_card_fixture(%{report_card_id: report_card.id, student_id: student_z_z.id})

      # other fixtures for filter testing
      other_class = SchoolsFixtures.class_fixture(%{school_id: school.id})

      other_student =
        SchoolsFixtures.student_fixture(%{school_id: school.id, classes_ids: [other_class.id]})

      _other_student_report_card =
        student_report_card_fixture(%{student_id: other_student.id})

      assert [
               {expected_student_a_a, expected_student_a_a_report_card},
               {expected_student_a_b, expected_student_a_b_report_card},
               {expected_student_j_j, expected_student_j_j_report_card}
             ] =
               Reporting.list_students_linked_to_report_card(report_card,
                 classes_ids: [class_a.id, class_j.id],
                 active_students_only: true
               )

      assert expected_student_a_a.id == student_a_a.id

      assert expected_student_a_a.profile_picture_url ==
               student_a_a_cycle_info.profile_picture_url

      assert [expected_class_a_a] = expected_student_a_a.classes
      assert expected_class_a_a.id == class_a.id
      assert expected_student_a_a_report_card.id == student_a_a_report_card.id

      assert expected_student_a_b.id == student_a_b.id
      assert [expected_class_a_b] = expected_student_a_b.classes
      assert expected_class_a_b.id == class_a.id
      assert expected_student_a_b_report_card.id == student_a_b_report_card.id

      assert expected_student_j_j.id == student_j_j.id
      assert [expected_class_j_j] = expected_student_j_j.classes
      assert expected_class_j_j.id == class_j.id
      assert expected_student_j_j_report_card.id == student_j_j_report_card.id

      # use same setup and test without report card

      assert [expected_student_j_k] =
               Reporting.list_students_not_linked_to_report_card(report_card)

      assert expected_student_j_k.id == student_j_k.id

      assert expected_student_j_k.profile_picture_url ==
               student_j_k_cycle_info.profile_picture_url
    end

    test "list_students_linked_to_report_card/2 with students_only = true opt omits report cards from the returned list" do
      school = SchoolsFixtures.school_fixture()
      parent_cycle = SchoolsFixtures.cycle_fixture(%{school_id: school.id})

      subcycle =
        SchoolsFixtures.cycle_fixture(%{school_id: school.id, parent_cycle_id: parent_cycle.id})

      year = TaxonomyFixtures.year_fixture()

      class =
        SchoolsFixtures.class_fixture(%{
          school_id: school.id,
          cycle_id: parent_cycle.id,
          years_ids: [year.id]
        })

      other_cycle_class =
        SchoolsFixtures.class_fixture(%{school_id: school.id, years_ids: [year.id]})

      other_year_class =
        SchoolsFixtures.class_fixture(%{school_id: school.id, cycle_id: parent_cycle.id})

      student_a =
        SchoolsFixtures.student_fixture(%{
          name: "AAA",
          classes_ids: [class.id, other_cycle_class.id]
        })

      student_b =
        SchoolsFixtures.student_fixture(%{
          name: "BBB",
          classes_ids: [class.id, other_year_class.id]
        })

      report_card =
        report_card_fixture(%{
          year_id: year.id,
          school_cycle_id: subcycle.id
        })
        |> Repo.preload(:school_cycle)

      Reporting.create_student_report_card(%{
        student_id: student_a.id,
        report_card_id: report_card.id
      })

      Reporting.create_student_report_card(%{
        student_id: student_b.id,
        report_card_id: report_card.id
      })

      # other report card for testing
      other_student = SchoolsFixtures.student_fixture(%{classes_ids: [class.id]})
      other_report_card = report_card_fixture()

      Reporting.create_student_report_card(%{
        student_id: other_student.id,
        report_card_id: other_report_card.id
      })

      # assert
      [expected_a, expected_b] =
        Reporting.list_students_linked_to_report_card(report_card, students_only: true)

      assert expected_a.id == student_a.id
      assert expected_b.id == student_b.id

      # classes preload should be restricted to classes related
      # to report card year and parent cycle
      [expected_class] = expected_a.classes
      assert expected_class.id == class.id
      [expected_class] = expected_b.classes
      assert expected_class.id == class.id
    end

    test "list_student_report_card_cycles/1 returns all cycles linked to given student's report cards" do
      student = SchoolsFixtures.student_fixture()

      cycle_2023 = SchoolsFixtures.cycle_fixture(start_at: ~D[2023-01-01], end_at: ~D[2023-12-31])
      cycle_2024 = SchoolsFixtures.cycle_fixture(start_at: ~D[2024-01-01], end_at: ~D[2024-12-31])

      report_card_2023 =
        Lanttern.ReportingFixtures.report_card_fixture(%{school_cycle_id: cycle_2023.id})

      report_card_2024 =
        Lanttern.ReportingFixtures.report_card_fixture(%{school_cycle_id: cycle_2024.id})

      # link student to report cards
      student_report_card_fixture(%{report_card_id: report_card_2023.id, student_id: student.id})
      student_report_card_fixture(%{report_card_id: report_card_2024.id, student_id: student.id})

      assert [cycle_2023, cycle_2024] == Reporting.list_student_report_cards_cycles(student.id)
    end

    test "list_student_report_card_cycles/1 with parent cycle filter returns all cycles linked to given student's report cards filtered by cycle" do
      school = SchoolsFixtures.school_fixture()
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})

      parent_cycle = SchoolsFixtures.cycle_fixture(%{school_id: school.id})

      cycle_1 =
        SchoolsFixtures.cycle_fixture(%{
          school_id: school.id,
          parent_cycle_id: parent_cycle.id,
          start_at: ~D[2025-01-01],
          end_at: ~D[2025-06-30]
        })

      cycle_2 =
        SchoolsFixtures.cycle_fixture(%{
          school_id: school.id,
          parent_cycle_id: parent_cycle.id,
          start_at: ~D[2025-07-01],
          end_at: ~D[2025-12-01]
        })

      report_card_1 =
        Lanttern.ReportingFixtures.report_card_fixture(%{school_cycle_id: cycle_1.id})

      report_card_2 =
        Lanttern.ReportingFixtures.report_card_fixture(%{school_cycle_id: cycle_2.id})

      # link student to report cards
      student_report_card_fixture(%{report_card_id: report_card_1.id, student_id: student.id})
      student_report_card_fixture(%{report_card_id: report_card_2.id, student_id: student.id})

      # other fixtures for filter testing
      other_parent_cycle = SchoolsFixtures.cycle_fixture(%{school_id: school.id})

      other_cycle =
        SchoolsFixtures.cycle_fixture(%{
          school_id: school.id,
          parent_cycle_id: other_parent_cycle.id
        })

      other_report_card =
        Lanttern.ReportingFixtures.report_card_fixture(%{school_cycle_id: other_cycle.id})

      # link student to report cards
      student_report_card_fixture(%{report_card_id: other_report_card.id, student_id: student.id})

      assert [cycle_1, cycle_2] ==
               Reporting.list_student_report_cards_cycles(student.id,
                 parent_cycle_id: parent_cycle.id
               )
    end

    test "list_student_report_cards_linked_to_strand/1 returns all student report cards linked to given strand note" do
      cycle_2023 = SchoolsFixtures.cycle_fixture(start_at: ~D[2023-01-01], end_at: ~D[2023-12-31])
      cycle_2024 = SchoolsFixtures.cycle_fixture(start_at: ~D[2024-01-01], end_at: ~D[2024-12-31])

      report_card_2023 =
        report_card_fixture(%{school_cycle_id: cycle_2023.id})

      report_card_2024 =
        report_card_fixture(%{school_cycle_id: cycle_2024.id})

      strand = Lanttern.LearningContextFixtures.strand_fixture()

      # create strand reports
      strand_report_2023 =
        strand_report_fixture(%{strand_id: strand.id, report_card_id: report_card_2023.id})

      strand_report_2024 =
        strand_report_fixture(%{strand_id: strand.id, report_card_id: report_card_2024.id})

      student = SchoolsFixtures.student_fixture()

      # link student to report cards

      student_report_card_2023 =
        student_report_card_fixture(%{
          report_card_id: report_card_2023.id,
          student_id: student.id
        })

      student_report_card_2024 =
        student_report_card_fixture(%{
          report_card_id: report_card_2024.id,
          student_id: student.id
        })

      # other fixtures for query testing
      other_report_card = report_card_fixture()

      _other_strand_report =
        strand_report_fixture(%{strand_id: strand.id, report_card_id: other_report_card.id})

      _other_student_report_card =
        student_report_card_fixture(%{report_card_id: other_report_card.id})

      assert [
               {expected_student_report_card_2023, ^strand_report_2023},
               {expected_student_report_card_2024, ^strand_report_2024}
             ] = Reporting.list_student_report_cards_linked_to_strand(student.id, strand.id)

      assert expected_student_report_card_2023.id == student_report_card_2023.id
      assert expected_student_report_card_2023.report_card.id == report_card_2023.id

      assert expected_student_report_card_2024.id == student_report_card_2024.id
      assert expected_student_report_card_2024.report_card.id == report_card_2024.id
    end

    test "get_student_report_card!/2 returns the student_report_card with given id" do
      student_report_card = student_report_card_fixture()
      assert Reporting.get_student_report_card!(student_report_card.id) == student_report_card
    end

    test "get_student_report_card!/2 with preloads returns the student report card with given id and preloaded data" do
      report_card = report_card_fixture()
      student_report_card = student_report_card_fixture(%{report_card_id: report_card.id})

      expected =
        Reporting.get_student_report_card!(student_report_card.id, preloads: :report_card)

      assert expected.id == student_report_card.id
      assert expected.report_card == report_card
    end

    test "get_student_report_card_by_student_and_strand_report/2 returns the student_report_card" do
      student = SchoolsFixtures.student_fixture()
      report_card = report_card_fixture()

      student_report_card =
        student_report_card_fixture(%{student_id: student.id, report_card_id: report_card.id})

      strand_report = strand_report_fixture(%{report_card_id: report_card.id})

      assert Reporting.get_student_report_card_by_student_and_strand_report(
               student.id,
               strand_report.id
             ) == student_report_card
    end

    test "get_student_report_card_by_student_and_parent_report/2 returns the student_report_card" do
      student = SchoolsFixtures.student_fixture()
      report_card = report_card_fixture()

      student_report_card =
        student_report_card_fixture(%{student_id: student.id, report_card_id: report_card.id})

      assert Reporting.get_student_report_card_by_student_and_parent_report(
               student.id,
               report_card.id
             ) == student_report_card
    end

    test "create_student_report_card/1 with valid data creates a student_report_card" do
      report_card = report_card_fixture()
      student = Lanttern.SchoolsFixtures.student_fixture()

      valid_attrs = %{
        report_card_id: report_card.id,
        student_id: student.id,
        comment: "some comment",
        footnote: "some footnote"
      }

      assert {:ok, %StudentReportCard{} = student_report_card} =
               Reporting.create_student_report_card(valid_attrs)

      assert student_report_card.report_card_id == report_card.id
      assert student_report_card.student_id == student.id
      assert student_report_card.comment == "some comment"
      assert student_report_card.footnote == "some footnote"
    end

    test "create_student_report_card/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Reporting.create_student_report_card(@invalid_attrs)
    end

    test "update_student_report_card/2 with valid data updates the student_report_card" do
      student_report_card = student_report_card_fixture()
      update_attrs = %{comment: "some updated comment", footnote: "some updated footnote"}

      assert {:ok, %StudentReportCard{} = student_report_card} =
               Reporting.update_student_report_card(student_report_card, update_attrs)

      assert student_report_card.comment == "some updated comment"
      assert student_report_card.footnote == "some updated footnote"
    end

    test "update_student_report_card/2 with invalid data returns error changeset" do
      student_report_card = student_report_card_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Reporting.update_student_report_card(student_report_card, @invalid_attrs)

      assert student_report_card == Reporting.get_student_report_card!(student_report_card.id)
    end

    test "batch_update_student_report_card/2 with valid data updates the student_report_cards" do
      student_report_card_1 = student_report_card_fixture()
      student_report_card_2 = student_report_card_fixture()

      update_attrs = %{allow_student_access: true, allow_guardian_access: true}

      src_1_id = student_report_card_1.id
      src_2_id = student_report_card_2.id

      assert {:ok, %{^src_1_id => expected_1, ^src_2_id => expected_2}} =
               Reporting.batch_update_student_report_card(
                 [student_report_card_1, student_report_card_2],
                 update_attrs
               )

      assert expected_1.id == student_report_card_1.id
      assert expected_1.allow_student_access
      assert expected_1.allow_guardian_access

      assert expected_2.id == student_report_card_2.id
      assert expected_2.allow_student_access
      assert expected_2.allow_guardian_access
    end

    test "delete_student_report_card/1 deletes the student_report_card" do
      student_report_card = student_report_card_fixture()

      assert {:ok, %StudentReportCard{}} =
               Reporting.delete_student_report_card(student_report_card)

      assert_raise Ecto.NoResultsError, fn ->
        Reporting.get_student_report_card!(student_report_card.id)
      end
    end

    test "change_student_report_card/1 returns a student_report_card changeset" do
      student_report_card = student_report_card_fixture()
      assert %Ecto.Changeset{} = Reporting.change_student_report_card(student_report_card)
    end
  end

  describe "student strand reports" do
    import Lanttern.ReportingFixtures

    alias Lanttern.AssessmentsFixtures
    alias Lanttern.CurriculaFixtures
    alias Lanttern.GradingFixtures
    alias Lanttern.IdentityFixtures
    alias Lanttern.LearningContextFixtures
    alias Lanttern.RubricsFixtures
    alias Lanttern.SchoolsFixtures
    alias Lanttern.TaxonomyFixtures

    alias Lanttern.Assessments

    @evidence_params %{
      "name" => "attachment name",
      "link" => "https://somesite.com",
      "is_external" => true
    }

    test "list_student_report_card_strand_reports_and_entries/1 returns the list of the strands in the report with the student assessment point entries" do
      report_card = report_card_fixture()

      subject_1 = TaxonomyFixtures.subject_fixture()
      subject_2 = TaxonomyFixtures.subject_fixture()
      subject_3 = TaxonomyFixtures.subject_fixture()
      year = TaxonomyFixtures.year_fixture()

      strand_1 =
        LearningContextFixtures.strand_fixture(%{
          subjects_ids: [subject_1.id],
          years_ids: [year.id]
        })

      strand_2 =
        LearningContextFixtures.strand_fixture(%{
          subjects_ids: [subject_2.id],
          years_ids: [year.id]
        })

      strand_3 =
        LearningContextFixtures.strand_fixture(%{
          subjects_ids: [subject_3.id],
          years_ids: [year.id]
        })

      strand_1_report =
        strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand_1.id,
          position: 1
        })

      strand_2_report =
        strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand_2.id,
          position: 2
        })

      # no student assessment point entry for strand 3 (test list filtering)
      strand_3_report =
        strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand_3.id,
          position: 3
        })

      student = SchoolsFixtures.student_fixture()

      student_report_card =
        student_report_card_fixture(%{report_card_id: report_card.id, student_id: student.id})

      n_scale = GradingFixtures.scale_fixture(%{type: "numeric", start: 0, stop: 10})
      o_scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ov_1 = GradingFixtures.ordinal_value_fixture(%{scale_id: o_scale.id})
      ov_2 = GradingFixtures.ordinal_value_fixture(%{scale_id: o_scale.id})

      assessment_point_1_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_1.id,
          scale_id: o_scale.id
        })

      assessment_point_1_2 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_1.id,
          scale_id: o_scale.id
        })

      assessment_point_2_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_2.id,
          scale_id: n_scale.id
        })

      # 2_2 will have an empty entry
      assessment_point_2_2 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_2.id,
          scale_id: n_scale.id
        })

      # no student assessment point entry for strand 3 (test list filtering)
      _assessment_point_3_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_3.id,
          scale_id: o_scale.id
        })

      assessment_point_1_1_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point_1_1.id,
          scale_id: o_scale.id,
          scale_type: o_scale.type,
          ordinal_value_id: ov_1.id
        })

      assessment_point_1_2_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point_1_2.id,
          scale_id: o_scale.id,
          scale_type: o_scale.type,
          ordinal_value_id: ov_2.id
        })

      assessment_point_2_1_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point_2_1.id,
          scale_id: n_scale.id,
          scale_type: n_scale.type,
          score: 5
        })

      # no marking
      _assessment_point_2_2_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point_2_2.id,
          scale_id: n_scale.id,
          scale_type: n_scale.type
        })

      assert [
               {expected_strand_1_report, [expected_entry_1_1, expected_entry_1_2]},
               {expected_strand_2_report, [expected_entry_2_1]}
             ] =
               Reporting.list_student_report_card_strand_reports_and_entries(student_report_card)

      # strand 1 assertions

      assert expected_strand_1_report.id == strand_1_report.id
      assert expected_strand_1_report.strand.id == strand_1.id
      assert expected_strand_1_report.strand.subjects == [subject_1]
      assert expected_strand_1_report.strand.years == [year]

      assert expected_entry_1_1.id == assessment_point_1_1_entry.id
      assert expected_entry_1_1.scale == o_scale
      assert expected_entry_1_1.ordinal_value == ov_1

      assert expected_entry_1_2.id == assessment_point_1_2_entry.id
      assert expected_entry_1_2.scale == o_scale
      assert expected_entry_1_2.ordinal_value == ov_2

      # strand 2 assertions

      assert expected_strand_2_report.id == strand_2_report.id
      assert expected_strand_2_report.strand.id == strand_2.id
      assert expected_strand_2_report.strand.subjects == [subject_2]
      assert expected_strand_2_report.strand.years == [year]

      assert expected_entry_2_1.id == assessment_point_2_1_entry.id
      assert expected_entry_2_1.scale == n_scale
      assert expected_entry_2_1.score == 5

      # return strand 3 report if include_strands_without_entries is true
      assert [
               {expected_strand_1_report, [expected_entry_1_1, expected_entry_1_2]},
               {expected_strand_2_report, [expected_entry_2_1]},
               {expected_strand_3_report, []}
             ] =
               Reporting.list_student_report_card_strand_reports_and_entries(student_report_card,
                 include_strands_without_entries: true
               )

      # strand 1 assertions

      assert expected_strand_1_report.id == strand_1_report.id
      assert expected_entry_1_1.id == assessment_point_1_1_entry.id
      assert expected_entry_1_2.id == assessment_point_1_2_entry.id

      # strand 2 assertions

      assert expected_strand_2_report.id == strand_2_report.id
      assert expected_entry_2_1.id == assessment_point_2_1_entry.id

      # strand 3 assertions

      assert expected_strand_3_report.id == strand_3_report.id
    end

    test "list_student_strand_report_moments_and_entries/2 returns all moments and entries for the given strand report and student" do
      strand = LearningContextFixtures.strand_fixture()

      subject_1 = TaxonomyFixtures.subject_fixture(%{name: "AAA"})
      subject_2 = TaxonomyFixtures.subject_fixture(%{name: "BBB"})

      moment_1 =
        LearningContextFixtures.moment_fixture(%{
          strand_id: strand.id,
          subjects_ids: [subject_1.id]
        })

      moment_2 =
        LearningContextFixtures.moment_fixture(%{
          strand_id: strand.id,
          subjects_ids: [subject_2.id]
        })

      moment_3 =
        LearningContextFixtures.moment_fixture(%{
          strand_id: strand.id,
          subjects_ids: [subject_1.id, subject_2.id]
        })

      moment_4 =
        LearningContextFixtures.moment_fixture(%{
          strand_id: strand.id
        })

      strand_report = strand_report_fixture(%{strand_id: strand.id})

      student = SchoolsFixtures.student_fixture()

      n_scale = GradingFixtures.scale_fixture(%{type: "numeric", start: 0, stop: 10})
      o_scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ov_1 = GradingFixtures.ordinal_value_fixture(%{scale_id: o_scale.id})
      ov_2 = GradingFixtures.ordinal_value_fixture(%{scale_id: o_scale.id})

      # assessment points

      assessment_point_1_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_1.id,
          scale_id: o_scale.id
        })

      assessment_point_1_2 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_1.id,
          scale_id: o_scale.id
        })

      assessment_point_2_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_2.id,
          scale_id: n_scale.id
        })

      # entry without marking for moment 3
      assessment_point_3_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_3.id,
          scale_id: o_scale.id
        })

      # no student assessment point entry for moment 4
      _assessment_point_4_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_4.id,
          scale_id: o_scale.id
        })

      assessment_point_1_1_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point_1_1.id,
          scale_id: o_scale.id,
          scale_type: o_scale.type,
          ordinal_value_id: ov_1.id
        })

      assessment_point_1_2_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point_1_2.id,
          scale_id: o_scale.id,
          scale_type: o_scale.type,
          ordinal_value_id: ov_2.id
        })

      assessment_point_2_1_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point_2_1.id,
          scale_id: n_scale.id,
          scale_type: n_scale.type,
          score: 5
        })

      # no marking
      _assessment_point_3_1_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point_3_1.id,
          scale_id: o_scale.id,
          scale_type: o_scale.type
        })

      assert [
               {expected_moment_1, [expected_entry_1_1, expected_entry_1_2]},
               {expected_moment_2, [expected_entry_2_1]},
               {expected_moment_3, []},
               {expected_moment_4, []}
             ] =
               Reporting.list_student_strand_report_moments_and_entries(strand_report, student.id)

      # moment 1 assertions

      assert expected_moment_1.id == moment_1.id
      assert expected_moment_1.subjects == [subject_1]

      assert expected_entry_1_1.id == assessment_point_1_1_entry.id
      assert expected_entry_1_1.scale_id == o_scale.id
      assert expected_entry_1_1.ordinal_value_id == ov_1.id

      assert expected_entry_1_2.id == assessment_point_1_2_entry.id
      assert expected_entry_1_2.scale_id == o_scale.id
      assert expected_entry_1_2.ordinal_value_id == ov_2.id

      # moment 2 assertions

      assert expected_moment_2.id == moment_2.id
      assert expected_moment_2.subjects == [subject_2]

      assert expected_entry_2_1.id == assessment_point_2_1_entry.id
      assert expected_entry_2_1.scale_id == n_scale.id
      assert expected_entry_2_1.score == 5

      # moment 3 assertions

      assert expected_moment_3.id == moment_3.id
      assert expected_moment_3.subjects == [subject_1, subject_2]

      # moment 4 assertions

      assert expected_moment_4.id == moment_4.id
      assert expected_moment_4.subjects == []
    end

    test "list_student_strand_evidences/2 returns all student evidences linked to the given strand" do
      strand = LearningContextFixtures.strand_fixture()

      moment_1 =
        LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      moment_2 =
        LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      student = SchoolsFixtures.student_fixture()

      # assessment points

      curriculum_item = CurriculaFixtures.curriculum_item_fixture()
      scale = GradingFixtures.scale_fixture(%{type: "numeric"})

      goal =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id
        })

      moment_1_assessment_point =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_1.id,
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id
        })

      moment_2_assessment_point =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_2.id,
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id
        })

      # entries

      goal_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: goal.id,
          scale_id: scale.id,
          scale_type: scale.type,
          score: 10
        })

      moment_1_assessment_point_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: moment_1_assessment_point.id,
          scale_id: scale.id,
          scale_type: scale.type,
          score: 10
        })

      _moment_2_assessment_point_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: moment_2_assessment_point.id,
          scale_id: scale.id,
          scale_type: scale.type,
          score: 10
        })

      # evidences

      current_user = %{current_profile: IdentityFixtures.staff_member_profile_fixture()}

      {:ok, goal_evidence} =
        Assessments.create_assessment_point_entry_evidence(
          current_user,
          goal_entry.id,
          @evidence_params
        )

      {:ok, moment_1_assessment_point_evidence} =
        Assessments.create_assessment_point_entry_evidence(
          current_user,
          moment_1_assessment_point_entry.id,
          @evidence_params
        )

      assert Reporting.list_student_strand_evidences(strand.id, student.id) == [
               {moment_1_assessment_point_evidence, goal.id, moment_1.name},
               {goal_evidence, goal.id, nil}
             ]
    end

    test "list_moment_assessment_points_and_student_entries/2 returns all assessment points and entries for the given moment and student" do
      moment = LearningContextFixtures.moment_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()

      student = SchoolsFixtures.student_fixture()

      n_scale = GradingFixtures.scale_fixture(%{type: "numeric", start: 0, stop: 10})
      o_scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ov_1 = GradingFixtures.ordinal_value_fixture(%{scale_id: o_scale.id})
      ov_2 = GradingFixtures.ordinal_value_fixture(%{scale_id: o_scale.id})

      # rubrics

      rubric_1 =
        RubricsFixtures.rubric_fixture(%{
          strand_id: moment.strand_id,
          scale_id: o_scale.id,
          curriculum_item_id: curriculum_item.id
        })

      diff_rubric_1 =
        RubricsFixtures.rubric_fixture(%{
          strand_id: moment.strand_id,
          scale_id: o_scale.id,
          curriculum_item_id: curriculum_item.id,
          is_differentiation: true
        })

      rubric_3 =
        RubricsFixtures.rubric_fixture(%{
          strand_id: moment.strand_id,
          scale_id: n_scale.id,
          curriculum_item_id: curriculum_item.id
        })

      # assesment points

      assessment_point_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment.id,
          scale_id: o_scale.id,
          curriculum_item_id: curriculum_item.id,
          rubric_id: rubric_1.id
        })

      assessment_point_2 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment.id,
          scale_id: o_scale.id
        })

      assessment_point_3 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment.id,
          scale_id: n_scale.id,
          curriculum_item_id: curriculum_item.id,
          rubric_id: rubric_3.id
        })

      # only empty entries for moment 4
      assessment_point_4 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment.id,
          scale_id: o_scale.id
        })

      # no student assessment point entry for moment 5
      _assessment_point_5 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment.id,
          scale_id: o_scale.id
        })

      assessment_point_1_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point_1.id,
          scale_id: o_scale.id,
          scale_type: o_scale.type,
          ordinal_value_id: ov_1.id,
          differentiation_rubric_id: diff_rubric_1.id
        })

      assessment_point_2_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point_2.id,
          scale_id: o_scale.id,
          scale_type: o_scale.type,
          ordinal_value_id: ov_2.id
        })

      assessment_point_3_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point_3.id,
          scale_id: n_scale.id,
          scale_type: n_scale.type,
          score: 5
        })

      _no_marking_assessment_point_4_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point_4.id,
          scale_id: o_scale.id,
          scale_type: o_scale.type
        })

      assert [
               {expected_assessment_point_1, expected_entry_1},
               {expected_assessment_point_2, expected_entry_2},
               {expected_assessment_point_3, expected_entry_3}
             ] =
               Reporting.list_moment_assessment_points_and_student_entries(moment.id, student.id)

      # assessment point 1 assertions

      assert expected_assessment_point_1.id == assessment_point_1.id
      assert expected_assessment_point_1.rubric.id == rubric_1.id

      assert expected_entry_1.id == assessment_point_1_entry.id
      assert expected_entry_1.scale == o_scale
      assert expected_entry_1.ordinal_value == ov_1
      assert expected_entry_1.differentiation_rubric.id == diff_rubric_1.id

      # assessment point 2 assertions

      assert expected_assessment_point_2.id == assessment_point_2.id

      assert expected_entry_2.id == assessment_point_2_entry.id
      assert expected_entry_2.scale == o_scale
      assert expected_entry_2.ordinal_value == ov_2

      # assessment point 3 assertions

      assert expected_assessment_point_3.id == assessment_point_3.id
      assert expected_assessment_point_3.rubric.id == rubric_3.id

      assert expected_entry_3.id == assessment_point_3_entry.id
      assert expected_entry_3.scale == n_scale
      assert expected_entry_3.score == 5
    end

    test "list_strand_goal_moments_and_student_entries/2 returns all moments with assessment points and entries for the given strand goal and student" do
      strand = LearningContextFixtures.strand_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()

      strand_goal =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id
        })

      moment_1 =
        LearningContextFixtures.moment_fixture(%{
          strand_id: strand.id
        })

      # should not display, no entries linked to strand goal
      moment_2 =
        LearningContextFixtures.moment_fixture(%{
          strand_id: strand.id
        })

      # should no display, no assessment points linked to strand goal
      moment_3 =
        LearningContextFixtures.moment_fixture(%{
          strand_id: strand.id
        })

      student = SchoolsFixtures.student_fixture()

      n_scale = GradingFixtures.scale_fixture(%{type: "numeric", start: 0, stop: 10})
      o_scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ov_1 = GradingFixtures.ordinal_value_fixture(%{scale_id: o_scale.id})
      ov_2 = GradingFixtures.ordinal_value_fixture(%{scale_id: o_scale.id})

      # rubrics

      rubric_1 =
        RubricsFixtures.rubric_fixture(%{
          strand_id: strand.id,
          scale_id: o_scale.id,
          curriculum_item_id: curriculum_item.id
        })

      diff_rubric_1 =
        RubricsFixtures.rubric_fixture(%{
          strand_id: strand.id,
          scale_id: o_scale.id,
          curriculum_item_id: curriculum_item.id,
          is_differentiation: true
        })

      rubric_2 =
        RubricsFixtures.rubric_fixture(%{
          strand_id: strand.id,
          scale_id: n_scale.id,
          curriculum_item_id: curriculum_item.id
        })

      # assessment points

      assessment_point_1_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_1.id,
          scale_id: o_scale.id,
          curriculum_item_id: curriculum_item.id,
          rubric_id: rubric_1.id
        })

      assessment_point_1_2 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_1.id,
          scale_id: n_scale.id,
          curriculum_item_id: curriculum_item.id,
          rubric_id: rubric_2.id
        })

      # no student assessment point entry for assessment point 2_1
      _assessment_point_2_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_2.id,
          scale_id: n_scale.id,
          curriculum_item_id: curriculum_item.id
        })

      # not linked to strand goal
      assessment_point_3_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_3.id,
          scale_id: o_scale.id
        })

      # entries

      assessment_point_1_1_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point_1_1.id,
          scale_id: o_scale.id,
          scale_type: o_scale.type,
          ordinal_value_id: ov_1.id,
          differentiation_rubric_id: diff_rubric_1.id
        })

      assessment_point_1_2_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point_1_2.id,
          scale_id: n_scale.id,
          scale_type: n_scale.type,
          score: 5
        })

      # not linked to strand goal
      _assessment_point_3_1_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point_3_1.id,
          scale_id: o_scale.id,
          scale_type: o_scale.type,
          ordinal_value_id: ov_2.id
        })

      # add evidences to entry 1_1
      current_user = %{current_profile: IdentityFixtures.staff_member_profile_fixture()}

      {:ok, evidence} =
        Assessments.create_assessment_point_entry_evidence(
          current_user,
          assessment_point_1_1_entry.id,
          @evidence_params
        )

      # other strand goal with same curriculum item
      # to test filtering

      other_strand = LearningContextFixtures.strand_fixture()

      _other_goal =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: other_strand.id,
          curriculum_item_id: curriculum_item.id
        })

      other_moment =
        LearningContextFixtures.moment_fixture(%{
          strand_id: other_strand.id
        })

      _other_assessment_point =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: other_moment.id,
          curriculum_item_id: curriculum_item.id
        })

      assert [
               {expected_moment_1,
                [
                  {expected_assessment_point_1_1, expected_entry_1_1},
                  {expected_assessment_point_1_2, expected_entry_1_2}
                ]}
             ] =
               Reporting.list_strand_goal_moments_and_student_entries(strand_goal, student.id)

      # moment 1 assertions

      assert expected_moment_1.id == moment_1.id
      assert expected_assessment_point_1_1.id == assessment_point_1_1.id
      assert expected_assessment_point_1_1.rubric.id == rubric_1.id
      assert expected_entry_1_1.id == assessment_point_1_1_entry.id
      assert expected_entry_1_1.scale == o_scale
      assert expected_entry_1_1.ordinal_value == ov_1
      assert expected_entry_1_1.evidences == [evidence]
      assert expected_entry_1_1.differentiation_rubric.id == diff_rubric_1.id

      assert expected_entry_1_2.id == assessment_point_1_2_entry.id
      assert expected_assessment_point_1_2.id == assessment_point_1_2.id
      assert expected_assessment_point_1_2.rubric.id == rubric_2.id
      assert expected_entry_1_2.scale == n_scale
      assert expected_entry_1_2.score == 5.0
    end
  end

  describe "report card students assessments tracking" do
    import Lanttern.ReportingFixtures

    alias Lanttern.AssessmentsFixtures
    alias Lanttern.CurriculaFixtures
    alias Lanttern.GradingFixtures
    alias Lanttern.LearningContextFixtures
    alias Lanttern.SchoolsFixtures
    alias Lanttern.TaxonomyFixtures

    test "build_students_moments_entries_map_for_report_card/2 returns the map of students with strands and entries correctly" do
      # expected grid for this test case:

      # students  |      strand 1      | st 2 |  strand 3   |
      # -----------------------------------------------------
      # student A | m1_1 | m1_2 | nil  | m1_1 | nil  | m2_1 |
      # student B | nil  | m1_2 | m2_1 | nil  | nil  | nil  |
      # student C | m1_1 | m1_2 | m2_1 | m1_1 | m1_1 | nil  |

      student_a = SchoolsFixtures.student_fixture()
      student_b = SchoolsFixtures.student_fixture()
      student_c = SchoolsFixtures.student_fixture()

      # strands and moments fixtures

      strand_1 = LearningContextFixtures.strand_fixture()
      moment_1_1 = LearningContextFixtures.moment_fixture(%{strand_id: strand_1.id})
      moment_1_2 = LearningContextFixtures.moment_fixture(%{strand_id: strand_1.id})

      strand_2 = LearningContextFixtures.strand_fixture()
      moment_2_1 = LearningContextFixtures.moment_fixture(%{strand_id: strand_2.id})

      strand_3 = LearningContextFixtures.strand_fixture()
      moment_3_1 = LearningContextFixtures.moment_fixture(%{strand_id: strand_3.id})
      moment_3_2 = LearningContextFixtures.moment_fixture(%{strand_id: strand_3.id})

      # assessments fixtures

      scale = GradingFixtures.scale_fixture(%{type: "numeric"})

      ap_1_1_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_1_1.id,
          scale_id: scale.id
        })

      ap_1_1_2 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_1_1.id,
          scale_id: scale.id
        })

      ap_1_2_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_1_2.id,
          scale_id: scale.id
        })

      ap_2_1_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_2_1.id,
          scale_id: scale.id
        })

      ap_3_1_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_3_1.id,
          scale_id: scale.id
        })

      ap_3_2_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_3_2.id,
          scale_id: scale.id
        })

      entry_std_a_ap_1_1_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student_a.id,
          assessment_point_id: ap_1_1_1.id,
          scale_id: scale.id,
          scale_type: "numeric"
        })

      entry_std_a_ap_1_1_2 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student_a.id,
          assessment_point_id: ap_1_1_2.id,
          scale_id: scale.id,
          scale_type: "numeric"
        })

      entry_std_a_ap_2_1_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student_a.id,
          assessment_point_id: ap_2_1_1.id,
          scale_id: scale.id,
          scale_type: "numeric"
        })

      entry_std_a_ap_3_2_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student_a.id,
          assessment_point_id: ap_3_2_1.id,
          scale_id: scale.id,
          scale_type: "numeric"
        })

      entry_std_b_ap_1_1_2 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student_b.id,
          assessment_point_id: ap_1_1_2.id,
          scale_id: scale.id,
          scale_type: "numeric"
        })

      entry_std_b_ap_1_2_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student_b.id,
          assessment_point_id: ap_1_2_1.id,
          scale_id: scale.id,
          scale_type: "numeric"
        })

      entry_std_c_ap_1_1_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student_c.id,
          assessment_point_id: ap_1_1_1.id,
          scale_id: scale.id,
          scale_type: "numeric"
        })

      entry_std_c_ap_1_1_2 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student_c.id,
          assessment_point_id: ap_1_1_2.id,
          scale_id: scale.id,
          scale_type: "numeric"
        })

      entry_std_c_ap_1_2_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student_c.id,
          assessment_point_id: ap_1_2_1.id,
          scale_id: scale.id,
          scale_type: "numeric"
        })

      entry_std_c_ap_2_1_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student_c.id,
          assessment_point_id: ap_2_1_1.id,
          scale_id: scale.id,
          scale_type: "numeric"
        })

      entry_std_c_ap_3_1_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student_c.id,
          assessment_point_id: ap_3_1_1.id,
          scale_id: scale.id,
          scale_type: "numeric"
        })

      # report fixtures

      report_card = report_card_fixture()

      _strand_1_report =
        strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand_1.id
        })

      _strand_2_report =
        strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand_2.id
        })

      _strand_3_report =
        strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand_3.id
        })

      _student_a_report_card =
        student_report_card_fixture(%{report_card_id: report_card.id, student_id: student_a.id})

      _student_b_report_card =
        student_report_card_fixture(%{report_card_id: report_card.id, student_id: student_b.id})

      _student_c_report_card =
        student_report_card_fixture(%{report_card_id: report_card.id, student_id: student_c.id})

      expected =
        Reporting.build_students_moments_entries_map_for_report_card(report_card.id, [
          student_a.id,
          student_b.id,
          student_c.id
        ])

      # ids for pattern match
      moment_1_1_id = moment_1_1.id
      moment_1_2_id = moment_1_2.id
      moment_2_1_id = moment_2_1.id
      moment_3_1_id = moment_3_1.id
      moment_3_2_id = moment_3_2.id
      ap_1_1_1_id = ap_1_1_1.id
      ap_1_1_2_id = ap_1_1_2.id
      ap_1_2_1_id = ap_1_2_1.id
      ap_2_1_1_id = ap_2_1_1.id
      ap_3_1_1_id = ap_3_1_1.id
      ap_3_2_1_id = ap_3_2_1.id

      # assertions

      expected_std_a_strands_map = expected[student_a.id]

      assert [
               {^moment_1_1_id, ^ap_1_1_1_id, ^entry_std_a_ap_1_1_1},
               {^moment_1_1_id, ^ap_1_1_2_id, ^entry_std_a_ap_1_1_2},
               {^moment_1_2_id, ^ap_1_2_1_id, nil}
             ] = expected_std_a_strands_map[strand_1.id]

      assert [
               {^moment_2_1_id, ^ap_2_1_1_id, ^entry_std_a_ap_2_1_1}
             ] = expected_std_a_strands_map[strand_2.id]

      assert [
               {^moment_3_1_id, ^ap_3_1_1_id, nil},
               {^moment_3_2_id, ^ap_3_2_1_id, ^entry_std_a_ap_3_2_1}
             ] = expected_std_a_strands_map[strand_3.id]

      expected_std_b_strands_map = expected[student_b.id]

      assert [
               {^moment_1_1_id, ^ap_1_1_1_id, nil},
               {^moment_1_1_id, ^ap_1_1_2_id, ^entry_std_b_ap_1_1_2},
               {^moment_1_2_id, ^ap_1_2_1_id, ^entry_std_b_ap_1_2_1}
             ] = expected_std_b_strands_map[strand_1.id]

      assert [
               {^moment_2_1_id, ^ap_2_1_1_id, nil}
             ] = expected_std_b_strands_map[strand_2.id]

      assert [
               {^moment_3_1_id, ^ap_3_1_1_id, nil},
               {^moment_3_2_id, ^ap_3_2_1_id, nil}
             ] = expected_std_b_strands_map[strand_3.id]

      expected_std_c_strands_map = expected[student_c.id]

      assert [
               {^moment_1_1_id, ^ap_1_1_1_id, ^entry_std_c_ap_1_1_1},
               {^moment_1_1_id, ^ap_1_1_2_id, ^entry_std_c_ap_1_1_2},
               {^moment_1_2_id, ^ap_1_2_1_id, ^entry_std_c_ap_1_2_1}
             ] = expected_std_c_strands_map[strand_1.id]

      assert [
               {^moment_2_1_id, ^ap_2_1_1_id, ^entry_std_c_ap_2_1_1}
             ] = expected_std_c_strands_map[strand_2.id]

      assert [
               {^moment_3_1_id, ^ap_3_1_1_id, ^entry_std_c_ap_3_1_1},
               {^moment_3_2_id, ^ap_3_2_1_id, nil}
             ] = expected_std_c_strands_map[strand_3.id]
    end
  end

  describe "extra" do
    import Lanttern.ReportingFixtures
    alias Lanttern.AssessmentsFixtures
    alias Lanttern.CurriculaFixtures
    alias Lanttern.GradingFixtures
    alias Lanttern.LearningContext
    alias Lanttern.LearningContextFixtures
    alias Lanttern.SchoolsFixtures
    alias Lanttern.TaxonomyFixtures

    test "list_report_card_assessment_points/1 returns all report card's assessment points" do
      report_card = report_card_fixture()

      strand_1 = LearningContextFixtures.strand_fixture()
      strand_2 = LearningContextFixtures.strand_fixture()

      cur_component_1 = CurriculaFixtures.curriculum_component_fixture()
      cur_component_2 = CurriculaFixtures.curriculum_component_fixture()

      ci_1_1 =
        CurriculaFixtures.curriculum_item_fixture(curriculum_component_id: cur_component_1.id)

      ci_1_2 =
        CurriculaFixtures.curriculum_item_fixture(curriculum_component_id: cur_component_1.id)

      ci_2_1 =
        CurriculaFixtures.curriculum_item_fixture(curriculum_component_id: cur_component_2.id)

      ci_2_2 =
        CurriculaFixtures.curriculum_item_fixture(curriculum_component_id: cur_component_2.id)

      ast_point_1_1 =
        AssessmentsFixtures.assessment_point_fixture(
          strand_id: strand_1.id,
          curriculum_item_id: ci_1_1.id
        )

      ast_point_1_2 =
        AssessmentsFixtures.assessment_point_fixture(
          strand_id: strand_1.id,
          curriculum_item_id: ci_1_2.id
        )

      ast_point_2_1 =
        AssessmentsFixtures.assessment_point_fixture(
          strand_id: strand_2.id,
          curriculum_item_id: ci_2_1.id
        )

      ast_point_2_2 =
        AssessmentsFixtures.assessment_point_fixture(
          strand_id: strand_2.id,
          curriculum_item_id: ci_2_2.id
        )

      _strand_report_1 =
        strand_report_fixture(%{report_card_id: report_card.id, strand_id: strand_1.id})

      _strand_report_2 =
        strand_report_fixture(%{report_card_id: report_card.id, strand_id: strand_2.id})

      # extra fixtures to test filter
      other_report_card = report_card_fixture()
      other_strand = LearningContextFixtures.strand_fixture()
      _other_ast_point = AssessmentsFixtures.assessment_point_fixture(strand_id: other_strand.id)

      _other_strand_report =
        strand_report_fixture(%{report_card_id: other_report_card.id, strand_id: other_strand.id})

      assert [
               expected_ast_point_1_1,
               expected_ast_point_1_2,
               expected_ast_point_2_1,
               expected_ast_point_2_2
             ] = Reporting.list_report_card_assessment_points(report_card.id)

      assert expected_ast_point_1_1.id == ast_point_1_1.id
      assert expected_ast_point_1_1.strand.id == strand_1.id
      assert expected_ast_point_1_1.curriculum_item.id == ci_1_1.id
      assert expected_ast_point_1_1.curriculum_item.curriculum_component.id == cur_component_1.id

      assert expected_ast_point_1_2.id == ast_point_1_2.id
      assert expected_ast_point_1_2.strand.id == strand_1.id
      assert expected_ast_point_1_2.curriculum_item.id == ci_1_2.id
      assert expected_ast_point_1_2.curriculum_item.curriculum_component.id == cur_component_1.id

      assert expected_ast_point_2_1.id == ast_point_2_1.id
      assert expected_ast_point_2_1.strand.id == strand_2.id
      assert expected_ast_point_2_1.curriculum_item.id == ci_2_1.id
      assert expected_ast_point_2_1.curriculum_item.curriculum_component.id == cur_component_2.id

      assert expected_ast_point_2_2.id == ast_point_2_2.id
      assert expected_ast_point_2_2.strand.id == strand_2.id
      assert expected_ast_point_2_2.curriculum_item.id == ci_2_2.id
      assert expected_ast_point_2_2.curriculum_item.curriculum_component.id == cur_component_2.id
    end

    test "list_report_card_linked_students_classes/1 returns all report classes from students linked to the report card" do
      year_1 = Lanttern.TaxonomyFixtures.year_fixture()
      year_2 = Lanttern.TaxonomyFixtures.year_fixture()
      year_3 = Lanttern.TaxonomyFixtures.year_fixture()

      report_card = report_card_fixture(%{year_id: year_2.id})

      class_1 =
        Lanttern.SchoolsFixtures.class_fixture(%{name: "AAA", years_ids: [year_1.id, year_2.id]})

      class_2 =
        Lanttern.SchoolsFixtures.class_fixture(%{name: "BBB", years_ids: [year_2.id, year_3.id]})

      student_1 = Lanttern.SchoolsFixtures.student_fixture(%{classes_ids: [class_1.id]})
      student_2 = Lanttern.SchoolsFixtures.student_fixture(%{classes_ids: [class_2.id]})
      # student in same class to test distinct results
      student_3 =
        Lanttern.SchoolsFixtures.student_fixture(%{classes_ids: [class_1.id, class_2.id]})

      student_report_card_fixture(%{report_card_id: report_card.id, student_id: student_1.id})
      student_report_card_fixture(%{report_card_id: report_card.id, student_id: student_2.id})
      student_report_card_fixture(%{report_card_id: report_card.id, student_id: student_3.id})

      # other fixtures for filtering test
      other_report_card = report_card_fixture()
      other_class = Lanttern.SchoolsFixtures.class_fixture()
      other_student = Lanttern.SchoolsFixtures.student_fixture(%{classes_ids: [other_class.id]})

      student_report_card_fixture(%{
        report_card_id: other_report_card.id,
        student_id: other_student.id
      })

      assert [expected_class_1, expected_class_2] =
               Reporting.list_report_card_linked_students_classes(report_card)

      assert expected_class_1.id == class_1.id
      assert expected_class_2.id == class_2.id
    end

    test "list_moment_cards_and_attachments_shared_with_students/1 returns all cards and attachments for the given moment" do
      school = SchoolsFixtures.school_fixture()
      moment = LearningContextFixtures.moment_fixture()

      moment_card =
        LearningContextFixtures.moment_card_fixture(%{
          moment_id: moment.id,
          school_id: school.id,
          shared_with_students: true
        })

      _not_shared_card =
        LearningContextFixtures.moment_card_fixture(%{
          moment_id: moment.id,
          school_id: school.id,
          shared_with_students: false
        })

      _other_school_card =
        LearningContextFixtures.moment_card_fixture(%{
          moment_id: moment.id,
          shared_with_students: true
        })

      profile = Lanttern.IdentityFixtures.staff_member_profile_fixture()

      {:ok, attachment} =
        LearningContext.create_moment_card_attachment(
          profile.id,
          moment_card.id,
          %{"name" => "attachment", "link" => "https://somevaliduri.com"},
          true
        )

      {:ok, _not_shared_attachment} =
        LearningContext.create_moment_card_attachment(
          profile.id,
          moment_card.id,
          %{"name" => "attachment", "link" => "https://somevaliduri.com"}
        )

      [expected_card] =
        Reporting.list_moment_cards_and_attachments_shared_with_students(moment.id,
          school_id: school.id
        )

      assert expected_card.id == moment_card.id
      [expected_attachment] = expected_card.attachments
      assert expected_attachment.id == attachment.id
    end
  end
end
