defmodule Lanttern.ReportingTest do
  use Lanttern.DataCase

  alias Lanttern.Repo
  alias Lanttern.Reporting

  describe "report_cards" do
    alias Lanttern.Reporting.ReportCard

    import Lanttern.ReportingFixtures
    alias Lanttern.SchoolsFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_report_cards/1 returns all report_cards" do
      report_card = report_card_fixture()
      assert Reporting.list_report_cards() == [report_card]
    end

    test "list_report_cards/1 with preloads returns all report_cards with preloaded data" do
      school_cycle = Lanttern.SchoolsFixtures.cycle_fixture()
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

    test "list_report_cards/1 with year/cycle filters returns all filtered report_cards" do
      year = Lanttern.TaxonomyFixtures.year_fixture()
      cycle = Lanttern.SchoolsFixtures.cycle_fixture()
      report_card = report_card_fixture(%{school_cycle_id: cycle.id, year_id: year.id})

      # extra report cards for filtering test
      report_card_fixture()
      report_card_fixture(%{year_id: year.id})
      report_card_fixture(%{school_cycle_id: cycle.id})

      [expected] = Reporting.list_report_cards(years_ids: [year.id], cycles_ids: [cycle.id])

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
      school_cycle = Lanttern.SchoolsFixtures.cycle_fixture()
      year = Lanttern.TaxonomyFixtures.year_fixture()

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

    @invalid_attrs %{report_card_id: nil, comment: nil, footnote: nil}

    test "list_student_report_cards/0 returns all student_report_cards" do
      student_report_card = student_report_card_fixture()
      assert Reporting.list_student_report_cards() == [student_report_card]
    end

    test "list_students_for_report_card/2 returns all students with class and linked report cards" do
      school = SchoolsFixtures.school_fixture()
      class_a = SchoolsFixtures.class_fixture(%{name: "AAA", school_id: school.id})

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

      class_j = SchoolsFixtures.class_fixture(%{name: "JJJ", school_id: school.id})

      student_j_j =
        SchoolsFixtures.student_fixture(%{
          name: "JJJ",
          school_id: school.id,
          classes_ids: [class_j.id]
        })

      student_j_k =
        SchoolsFixtures.student_fixture(%{
          name: "KKK",
          school_id: school.id,
          classes_ids: [class_j.id]
        })

      report_card = report_card_fixture()

      student_a_a_report_card =
        student_report_card_fixture(%{report_card_id: report_card.id, student_id: student_a_a.id})

      student_a_b_report_card =
        student_report_card_fixture(%{report_card_id: report_card.id, student_id: student_a_b.id})

      student_j_j_report_card =
        student_report_card_fixture(%{report_card_id: report_card.id, student_id: student_j_j.id})

      # other fixtures for filter testing
      other_class = SchoolsFixtures.class_fixture(%{school_id: school.id})

      other_student =
        SchoolsFixtures.student_fixture(%{school_id: school.id, classes_ids: [other_class.id]})

      _other_student_report_card =
        student_report_card_fixture(%{
          report_card_id: report_card.id,
          student_id: other_student.id
        })

      assert [
               {expected_student_a_a, expected_class_a_a, expected_student_a_a_report_card},
               {expected_student_a_b, expected_class_a_b, expected_student_a_b_report_card},
               {expected_student_j_j, expected_class_j_j, expected_student_j_j_report_card},
               {expected_student_j_k, expected_class_j_k, nil}
             ] =
               Reporting.list_students_for_report_card(report_card.id,
                 classes_ids: [class_a.id, class_j.id]
               )

      assert expected_student_a_a.id == student_a_a.id
      assert expected_class_a_a.id == class_a.id
      assert expected_student_a_a_report_card.id == student_a_a_report_card.id

      assert expected_student_a_b.id == student_a_b.id
      assert expected_class_a_b.id == class_a.id
      assert expected_student_a_b_report_card.id == student_a_b_report_card.id

      assert expected_student_j_j.id == student_j_j.id
      assert expected_class_j_j.id == class_j.id
      assert expected_student_j_j_report_card.id == student_j_j_report_card.id

      assert expected_student_j_k.id == student_j_k.id
      assert expected_class_j_k.id == class_j.id
    end

    test "get_student_report_card!/1 returns the student_report_card with given id" do
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
    alias Lanttern.GradingFixtures
    alias Lanttern.LearningContextFixtures
    alias Lanttern.SchoolsFixtures
    alias Lanttern.TaxonomyFixtures

    test "list_student_report_card_strand_reports_and_entries/1 returns the list of the strands in the report with the student assessment point entries" do
      report_card = report_card_fixture()

      subject_1 = TaxonomyFixtures.subject_fixture()
      subject_2 = TaxonomyFixtures.subject_fixture()
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
    end
  end

  describe "report card grade subject and cycle" do
    alias Lanttern.Reporting.ReportCardGradeSubject
    alias Lanttern.Reporting.ReportCardGradeCycle

    import Lanttern.ReportingFixtures
    alias Lanttern.SchoolsFixtures
    alias Lanttern.TaxonomyFixtures

    test "list_report_card_grades_subjects/1 returns all report card grades subjects ordered by position and subjects preloaded" do
      report_card = report_card_fixture()
      subject_1 = TaxonomyFixtures.subject_fixture()
      subject_2 = TaxonomyFixtures.subject_fixture()

      report_card_grade_subject_1 =
        report_card_grade_subject_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_1.id
        })

      report_card_grade_subject_2 =
        report_card_grade_subject_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_2.id
        })

      assert [expected_rcgs_1, expected_rcgs_2] =
               Reporting.list_report_card_grades_subjects(report_card.id)

      assert expected_rcgs_1.id == report_card_grade_subject_1.id
      assert expected_rcgs_1.subject.id == subject_1.id

      assert expected_rcgs_2.id == report_card_grade_subject_2.id
      assert expected_rcgs_2.subject.id == subject_2.id
    end

    test "add_subject_to_report_card_grades/1 with valid data creates a report card grade subject" do
      report_card = report_card_fixture()
      subject = TaxonomyFixtures.subject_fixture()

      valid_attrs = %{
        report_card_id: report_card.id,
        subject_id: subject.id
      }

      assert {:ok, %ReportCardGradeSubject{} = report_card_grade_subject} =
               Reporting.add_subject_to_report_card_grades(valid_attrs)

      assert report_card_grade_subject.report_card_id == report_card.id
      assert report_card_grade_subject.subject_id == subject.id
      assert report_card_grade_subject.position == 0

      # insert one more report card grade subject in a different report card to test position auto increment scope

      # extra fixture in different report card
      report_card_grade_subject_fixture()

      subject = TaxonomyFixtures.subject_fixture()

      valid_attrs = %{
        report_card_id: report_card.id,
        subject_id: subject.id
      }

      assert {:ok, %ReportCardGradeSubject{} = report_card_grade_subject} =
               Reporting.add_subject_to_report_card_grades(valid_attrs)

      assert report_card_grade_subject.report_card_id == report_card.id
      assert report_card_grade_subject.subject_id == subject.id
      assert report_card_grade_subject.position == 1
    end

    test "update_report_card_grades_subjects_positions/1 update report card grades subjects positions based on list order" do
      report_card = report_card_fixture()

      report_card_grade_subject_1 =
        report_card_grade_subject_fixture(%{report_card_id: report_card.id})

      report_card_grade_subject_2 =
        report_card_grade_subject_fixture(%{report_card_id: report_card.id})

      report_card_grade_subject_3 =
        report_card_grade_subject_fixture(%{report_card_id: report_card.id})

      report_card_grade_subject_4 =
        report_card_grade_subject_fixture(%{report_card_id: report_card.id})

      sorted_report_card_grades_subjects_ids =
        [
          report_card_grade_subject_2.id,
          report_card_grade_subject_3.id,
          report_card_grade_subject_1.id,
          report_card_grade_subject_4.id
        ]

      assert :ok ==
               Reporting.update_report_card_grades_subjects_positions(
                 sorted_report_card_grades_subjects_ids
               )

      assert [
               expected_rcgs_2,
               expected_rcgs_3,
               expected_rcgs_1,
               expected_rcgs_4
             ] =
               Reporting.list_report_card_grades_subjects(report_card.id)

      assert expected_rcgs_1.id == report_card_grade_subject_1.id
      assert expected_rcgs_2.id == report_card_grade_subject_2.id
      assert expected_rcgs_3.id == report_card_grade_subject_3.id
      assert expected_rcgs_4.id == report_card_grade_subject_4.id
    end

    test "delete_report_card_grade_subject/1 deletes the report_card_grade_subject" do
      report_card_grade_subject = report_card_grade_subject_fixture()

      assert {:ok, %ReportCardGradeSubject{}} =
               Reporting.delete_report_card_grade_subject(report_card_grade_subject)

      assert_raise Ecto.NoResultsError, fn ->
        Repo.get!(ReportCardGradeSubject, report_card_grade_subject.id)
      end
    end

    test "list_report_card_grades_cycles/1 returns all report card grades cycles ordered by dates and preloaded cycles" do
      report_card = report_card_fixture()

      cycle_2023 =
        SchoolsFixtures.cycle_fixture(%{start_at: ~D[2023-01-01], end_at: ~D[2023-12-31]})

      cycle_2024_q4 =
        SchoolsFixtures.cycle_fixture(%{start_at: ~D[2024-09-01], end_at: ~D[2024-12-31]})

      cycle_2024 =
        SchoolsFixtures.cycle_fixture(%{start_at: ~D[2024-01-01], end_at: ~D[2024-12-31]})

      report_card_grade_cycle_2023 =
        report_card_grade_cycle_fixture(%{
          report_card_id: report_card.id,
          school_cycle_id: cycle_2023.id
        })

      report_card_grade_cycle_2024_q4 =
        report_card_grade_cycle_fixture(%{
          report_card_id: report_card.id,
          school_cycle_id: cycle_2024_q4.id
        })

      report_card_grade_cycle_2024 =
        report_card_grade_cycle_fixture(%{
          report_card_id: report_card.id,
          school_cycle_id: cycle_2024.id
        })

      assert [expected_rcgc_2023, expected_rcgc_2024_q4, expected_rcgc_2024] =
               Reporting.list_report_card_grades_cycles(report_card.id)

      assert expected_rcgc_2023.id == report_card_grade_cycle_2023.id
      assert expected_rcgc_2023.school_cycle.id == cycle_2023.id

      assert expected_rcgc_2024_q4.id == report_card_grade_cycle_2024_q4.id
      assert expected_rcgc_2024_q4.school_cycle.id == cycle_2024_q4.id

      assert expected_rcgc_2024.id == report_card_grade_cycle_2024.id
      assert expected_rcgc_2024.school_cycle.id == cycle_2024.id
    end

    test "add_cycle_to_report_card_grades/1 with valid data creates a report card grade cycle" do
      report_card = report_card_fixture()
      school_cycle = SchoolsFixtures.cycle_fixture()

      valid_attrs = %{
        report_card_id: report_card.id,
        school_cycle_id: school_cycle.id
      }

      assert {:ok, %ReportCardGradeCycle{} = report_card_grade_cycle} =
               Reporting.add_cycle_to_report_card_grades(valid_attrs)

      assert report_card_grade_cycle.report_card_id == report_card.id
      assert report_card_grade_cycle.school_cycle_id == school_cycle.id
    end

    test "delete_report_card_grade_cycle/1 deletes the report_card_grade_cycle" do
      report_card_grade_cycle = report_card_grade_cycle_fixture()

      assert {:ok, %ReportCardGradeCycle{}} =
               Reporting.delete_report_card_grade_cycle(report_card_grade_cycle)

      assert_raise Ecto.NoResultsError, fn ->
        Repo.get!(ReportCardGradeCycle, report_card_grade_cycle.id)
      end
    end
  end

  describe "grades_reports" do
    alias Lanttern.Reporting.GradesReport

    import Lanttern.ReportingFixtures
    alias Lanttern.SchoolsFixtures

    @invalid_attrs %{info: "blah", scale_id: nil}

    test "list_grades_reports/1 returns all grades_reports" do
      grades_report = grades_report_fixture()
      assert Reporting.list_grades_reports() == [grades_report]
    end

    test "get_grades_report!/2 returns the grades_report with given id" do
      grades_report = grades_report_fixture()
      assert Reporting.get_grades_report!(grades_report.id) == grades_report
    end

    test "get_grades_report!/2 with preloads returns the grade report with given id and preloaded data" do
      school_cycle = SchoolsFixtures.cycle_fixture()
      grades_report = grades_report_fixture(%{school_cycle_id: school_cycle.id})

      expected = Reporting.get_grades_report!(grades_report.id, preloads: :school_cycle)

      assert expected.id == grades_report.id
      assert expected.school_cycle == school_cycle
    end

    test "create_grades_report/1 with valid data creates a grades_report" do
      school_cycle = Lanttern.SchoolsFixtures.cycle_fixture()
      scale = Lanttern.GradingFixtures.scale_fixture()

      valid_attrs = %{
        name: "grade report name abc",
        school_cycle_id: school_cycle.id,
        scale_id: scale.id
      }

      assert {:ok, %GradesReport{} = grades_report} = Reporting.create_grades_report(valid_attrs)
      assert grades_report.name == "grade report name abc"
      assert grades_report.school_cycle_id == school_cycle.id
      assert grades_report.scale_id == scale.id
    end

    test "create_grades_report/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Reporting.create_grades_report(@invalid_attrs)
    end

    test "update_grades_report/2 with valid data updates the grades_report" do
      grades_report = grades_report_fixture()
      update_attrs = %{info: "some updated info", is_differentiation: "true"}

      assert {:ok, %GradesReport{} = grades_report} =
               Reporting.update_grades_report(grades_report, update_attrs)

      assert grades_report.info == "some updated info"
      assert grades_report.is_differentiation
    end

    test "update_grades_report/2 with invalid data returns error changeset" do
      grades_report = grades_report_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Reporting.update_grades_report(grades_report, @invalid_attrs)

      assert grades_report == Reporting.get_grades_report!(grades_report.id)
    end

    test "delete_grades_report/1 deletes the grades_report" do
      grades_report = grades_report_fixture()
      assert {:ok, %GradesReport{}} = Reporting.delete_grades_report(grades_report)
      assert_raise Ecto.NoResultsError, fn -> Reporting.get_grades_report!(grades_report.id) end
    end

    test "change_report_card/1 returns a report_card changeset" do
      report_card = report_card_fixture()
      assert %Ecto.Changeset{} = Reporting.change_report_card(report_card)
    end
  end

  describe "grades report subjects" do
    alias Lanttern.Reporting.GradesReportSubject

    import Lanttern.ReportingFixtures
    alias Lanttern.SchoolsFixtures
    alias Lanttern.TaxonomyFixtures

    test "list_grades_report_subjects/1 returns all grades report subjects ordered by position and subjects preloaded" do
      grades_report = grades_report_fixture()
      subject_1 = TaxonomyFixtures.subject_fixture()
      subject_2 = TaxonomyFixtures.subject_fixture()

      grades_report_subject_1 =
        grades_report_subject_fixture(%{
          grades_report_id: grades_report.id,
          subject_id: subject_1.id
        })

      grades_report_subject_2 =
        grades_report_subject_fixture(%{
          grades_report_id: grades_report.id,
          subject_id: subject_2.id
        })

      assert [expected_grs_1, expected_grs_2] =
               Reporting.list_grades_report_subjects(grades_report.id)

      assert expected_grs_1.id == grades_report_subject_1.id
      assert expected_grs_1.subject.id == subject_1.id

      assert expected_grs_2.id == grades_report_subject_2.id
      assert expected_grs_2.subject.id == subject_2.id
    end

    test "add_subject_to_grades_report/1 with valid data creates a report card grade subject" do
      grades_report = grades_report_fixture()
      subject = TaxonomyFixtures.subject_fixture()

      valid_attrs = %{
        grades_report_id: grades_report.id,
        subject_id: subject.id
      }

      assert {:ok, %GradesReportSubject{} = grades_report_subject} =
               Reporting.add_subject_to_grades_report(valid_attrs)

      assert grades_report_subject.grades_report_id == grades_report.id
      assert grades_report_subject.subject_id == subject.id
      assert grades_report_subject.position == 0

      # insert one more grades report subject in a different grades report to test position auto increment scope

      # extra fixture in different grades report
      grades_report_subject_fixture()

      subject = TaxonomyFixtures.subject_fixture()

      valid_attrs = %{
        grades_report_id: grades_report.id,
        subject_id: subject.id
      }

      assert {:ok, %GradesReportSubject{} = grades_report_subject} =
               Reporting.add_subject_to_grades_report(valid_attrs)

      assert grades_report_subject.grades_report_id == grades_report.id
      assert grades_report_subject.subject_id == subject.id
      assert grades_report_subject.position == 1
    end

    test "update_grades_report_subjects_positions/1 update grades report subjects positions based on list order" do
      grades_report = grades_report_fixture()

      grades_report_subject_1 =
        grades_report_subject_fixture(%{grades_report_id: grades_report.id})

      grades_report_subject_2 =
        grades_report_subject_fixture(%{grades_report_id: grades_report.id})

      grades_report_subject_3 =
        grades_report_subject_fixture(%{grades_report_id: grades_report.id})

      grades_report_subject_4 =
        grades_report_subject_fixture(%{grades_report_id: grades_report.id})

      sorted_grades_report_subjects_ids =
        [
          grades_report_subject_2.id,
          grades_report_subject_3.id,
          grades_report_subject_1.id,
          grades_report_subject_4.id
        ]

      assert :ok ==
               Reporting.update_grades_report_subjects_positions(
                 sorted_grades_report_subjects_ids
               )

      assert [
               expected_grs_2,
               expected_grs_3,
               expected_grs_1,
               expected_grs_4
             ] =
               Reporting.list_grades_report_subjects(grades_report.id)

      assert expected_grs_1.id == grades_report_subject_1.id
      assert expected_grs_2.id == grades_report_subject_2.id
      assert expected_grs_3.id == grades_report_subject_3.id
      assert expected_grs_4.id == grades_report_subject_4.id
    end

    test "delete_grades_report_subject/1 deletes the grades_report_subject" do
      grades_report_subject = grades_report_subject_fixture()

      assert {:ok, %GradesReportSubject{}} =
               Reporting.delete_grades_report_subject(grades_report_subject)

      assert_raise Ecto.NoResultsError, fn ->
        Repo.get!(GradesReportSubject, grades_report_subject.id)
      end
    end
  end

  describe "grades report cycles" do
    alias Lanttern.Reporting.GradesReportCycle

    import Lanttern.ReportingFixtures
    alias Lanttern.SchoolsFixtures
    alias Lanttern.TaxonomyFixtures

    test "list_grades_report_cycles/1 returns all grades report cycles ordered by dates and preloaded cycles" do
      grades_report = grades_report_fixture()

      cycle_2023 =
        SchoolsFixtures.cycle_fixture(%{start_at: ~D[2023-01-01], end_at: ~D[2023-12-31]})

      cycle_2024_q4 =
        SchoolsFixtures.cycle_fixture(%{start_at: ~D[2024-09-01], end_at: ~D[2024-12-31]})

      cycle_2024 =
        SchoolsFixtures.cycle_fixture(%{start_at: ~D[2024-01-01], end_at: ~D[2024-12-31]})

      grades_report_cycle_2023 =
        grades_report_cycle_fixture(%{
          grades_report_id: grades_report.id,
          school_cycle_id: cycle_2023.id
        })

      grades_report_cycle_2024_q4 =
        grades_report_cycle_fixture(%{
          grades_report_id: grades_report.id,
          school_cycle_id: cycle_2024_q4.id
        })

      grades_report_cycle_2024 =
        grades_report_cycle_fixture(%{
          grades_report_id: grades_report.id,
          school_cycle_id: cycle_2024.id
        })

      assert [expected_grc_2023, expected_grc_2024_q4, expected_grc_2024] =
               Reporting.list_grades_report_cycles(grades_report.id)

      assert expected_grc_2023.id == grades_report_cycle_2023.id
      assert expected_grc_2023.school_cycle.id == cycle_2023.id

      assert expected_grc_2024_q4.id == grades_report_cycle_2024_q4.id
      assert expected_grc_2024_q4.school_cycle.id == cycle_2024_q4.id

      assert expected_grc_2024.id == grades_report_cycle_2024.id
      assert expected_grc_2024.school_cycle.id == cycle_2024.id
    end

    test "add_cycle_to_grades_report/1 with valid data creates a grades report cycle" do
      grades_report = grades_report_fixture()
      school_cycle = SchoolsFixtures.cycle_fixture()

      valid_attrs = %{
        grades_report_id: grades_report.id,
        school_cycle_id: school_cycle.id
      }

      assert {:ok, %GradesReportCycle{} = grades_report_cycle} =
               Reporting.add_cycle_to_grades_report(valid_attrs)

      assert grades_report_cycle.grades_report_id == grades_report.id
      assert grades_report_cycle.school_cycle_id == school_cycle.id
    end

    test "update_grades_report_cycle/2 with valid data updates the grades_report_cycle" do
      grades_report_cycle = grades_report_cycle_fixture()
      update_attrs = %{weight: 123.0}

      assert {:ok, %GradesReportCycle{} = grades_report_cycle} =
               Reporting.update_grades_report_cycle(grades_report_cycle, update_attrs)

      assert grades_report_cycle.weight == 123.0
    end

    test "update_grades_report_cycle/2 with invalid data returns error changeset" do
      grades_report_cycle = grades_report_cycle_fixture()
      invalid_attrs = %{weight: "abc"}

      assert {:error, %Ecto.Changeset{}} =
               Reporting.update_grades_report_cycle(grades_report_cycle, invalid_attrs)

      assert grades_report_cycle == Repo.get!(GradesReportCycle, grades_report_cycle.id)
    end

    test "delete_grades_report_cycle/1 deletes the grades_report_cycle" do
      grades_report_cycle = grades_report_cycle_fixture()

      assert {:ok, %GradesReportCycle{}} =
               Reporting.delete_grades_report_cycle(grades_report_cycle)

      assert_raise Ecto.NoResultsError, fn ->
        Repo.get!(GradesReportCycle, grades_report_cycle.id)
      end
    end
  end
end
