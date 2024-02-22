defmodule Lanttern.ReportingTest do
  use Lanttern.DataCase

  alias Lanttern.Reporting

  describe "report_cards" do
    alias Lanttern.Reporting.ReportCard

    import Lanttern.ReportingFixtures

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

    test "list_report_cards/1 with filters returns all filtered report_cards" do
      report_card = report_card_fixture()
      strand = Lanttern.LearningContextFixtures.strand_fixture()
      strand_report_fixture(%{report_card_id: report_card.id, strand_id: strand.id})

      # extra report cards for filtering test
      report_card_fixture()
      strand_report_fixture()

      [expected] = Reporting.list_report_cards(strands_ids: [strand.id])

      assert expected.id == report_card.id
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

      valid_attrs = %{
        name: "some name",
        description: "some description",
        school_cycle_id: school_cycle.id
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

    test "list_strand_reports/0 returns all strand_reports" do
      strand_report = strand_report_fixture()
      assert Reporting.list_strand_reports() == [strand_report]
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

    @invalid_attrs %{report_card_id: nil, comment: nil, footnote: nil}

    test "list_student_report_cards/0 returns all student_report_cards" do
      student_report_card = student_report_card_fixture()
      assert Reporting.list_student_report_cards() == [student_report_card]
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

    test "list_student_strand_reports/1 returns the list of the strands in the report with the student assessment point entries" do
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

      _strand_1_report =
        strand_report_fixture(%{
          report_card_id: report_card.id,
          strand_id: strand_1.id,
          position: 1
        })

      _strand_2_report =
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
               {expected_strand_1, [expected_entry_1_1, expected_entry_1_2]},
               {expected_strand_2, [expected_entry_2_1]}
             ] = Reporting.list_student_strand_reports(student_report_card)

      # strand 1 assertions

      assert expected_strand_1.id == strand_1.id
      assert expected_strand_1.subjects == [subject_1]
      assert expected_strand_1.years == [year]

      assert expected_entry_1_1.id == assessment_point_1_1_entry.id
      assert expected_entry_1_1.scale == o_scale
      assert expected_entry_1_1.ordinal_value == ov_1

      assert expected_entry_1_2.id == assessment_point_1_2_entry.id
      assert expected_entry_1_2.scale == o_scale
      assert expected_entry_1_2.ordinal_value == ov_2

      # strand 2 assertions

      assert expected_strand_2.id == strand_2.id
      assert expected_strand_2.subjects == [subject_2]
      assert expected_strand_2.years == [year]

      assert expected_entry_2_1.id == assessment_point_2_1_entry.id
      assert expected_entry_2_1.scale == n_scale
      assert expected_entry_2_1.score == 5
    end
  end
end
