defmodule Lanttern.GradesReportsTest do
  use Lanttern.DataCase

  alias Lanttern.GradesReports

  describe "student_grade_report_entries" do
    alias Lanttern.GradesReports.StudentGradeReportEntry

    import Lanttern.GradesReportsFixtures

    @invalid_attrs %{comment: nil, composition_normalized_value: nil, score: nil}

    test "list_student_grade_report_entries/0 returns all student_grade_report_entries" do
      student_grade_report_entry = student_grade_report_entry_fixture()
      assert GradesReports.list_student_grade_report_entries() == [student_grade_report_entry]
    end

    test "get_student_grade_report_entry!/2 returns the student_grade_report_entry with given id" do
      student_grade_report_entry = student_grade_report_entry_fixture()

      assert GradesReports.get_student_grade_report_entry!(student_grade_report_entry.id) ==
               student_grade_report_entry
    end

    test "get_student_grade_report_entry!/2 with preloads returns the student_grade_report_entry with given id and preloaded data" do
      student = Lanttern.SchoolsFixtures.student_fixture()
      student_grade_report_entry = student_grade_report_entry_fixture(%{student_id: student.id})

      assert expected_student_grade_report_entry =
               GradesReports.get_student_grade_report_entry!(student_grade_report_entry.id,
                 preloads: :student
               )

      assert expected_student_grade_report_entry.id == student_grade_report_entry.id
      assert expected_student_grade_report_entry.student.id == student.id
    end

    test "create_student_grade_report_entry/1 with valid data creates a student_grade_report_entry" do
      student = Lanttern.SchoolsFixtures.student_fixture()
      grades_report = Lanttern.ReportingFixtures.grades_report_fixture()

      grades_report_cycle =
        Lanttern.ReportingFixtures.grades_report_cycle_fixture(%{
          grades_report_id: grades_report.id
        })

      grades_report_subject =
        Lanttern.ReportingFixtures.grades_report_subject_fixture(%{
          grades_report_id: grades_report.id
        })

      valid_attrs = %{
        comment: "some comment",
        composition_normalized_value: 0.5,
        student_id: student.id,
        grades_report_id: grades_report.id,
        grades_report_cycle_id: grades_report_cycle.id,
        grades_report_subject_id: grades_report_subject.id
      }

      assert {:ok, %StudentGradeReportEntry{} = student_grade_report_entry} =
               GradesReports.create_student_grade_report_entry(valid_attrs)

      assert student_grade_report_entry.comment == "some comment"
      assert student_grade_report_entry.composition_normalized_value == 0.5
      assert student_grade_report_entry.student_id == student.id
      assert student_grade_report_entry.grades_report_id == grades_report.id
      assert student_grade_report_entry.grades_report_cycle_id == grades_report_cycle.id
      assert student_grade_report_entry.grades_report_subject_id == grades_report_subject.id
    end

    test "create_student_grade_report_entry/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               GradesReports.create_student_grade_report_entry(@invalid_attrs)
    end

    test "update_student_grade_report_entry/2 with valid data updates the student_grade_report_entry" do
      student_grade_report_entry = student_grade_report_entry_fixture()

      update_attrs = %{
        comment: "some updated comment",
        composition_normalized_value: 0.7,
        score: 456.7
      }

      assert {:ok, %StudentGradeReportEntry{} = student_grade_report_entry} =
               GradesReports.update_student_grade_report_entry(
                 student_grade_report_entry,
                 update_attrs
               )

      assert student_grade_report_entry.comment == "some updated comment"
      assert student_grade_report_entry.composition_normalized_value == 0.7
      assert student_grade_report_entry.score == 456.7
    end

    test "update_student_grade_report_entry/2 with invalid data returns error changeset" do
      student_grade_report_entry = student_grade_report_entry_fixture()

      assert {:error, %Ecto.Changeset{}} =
               GradesReports.update_student_grade_report_entry(
                 student_grade_report_entry,
                 @invalid_attrs
               )

      assert student_grade_report_entry ==
               GradesReports.get_student_grade_report_entry!(student_grade_report_entry.id)
    end

    test "delete_student_grade_report_entry/1 deletes the student_grade_report_entry" do
      student_grade_report_entry = student_grade_report_entry_fixture()

      assert {:ok, %StudentGradeReportEntry{}} =
               GradesReports.delete_student_grade_report_entry(student_grade_report_entry)

      assert_raise Ecto.NoResultsError, fn ->
        GradesReports.get_student_grade_report_entry!(student_grade_report_entry.id)
      end
    end

    test "change_student_grade_report_entry/1 returns a student_grade_report_entry changeset" do
      student_grade_report_entry = student_grade_report_entry_fixture()

      assert %Ecto.Changeset{} =
               GradesReports.change_student_grade_report_entry(student_grade_report_entry)
    end
  end

  describe "students grades calculations" do
    alias Lanttern.GradesReports.StudentGradeReportEntry

    import Lanttern.GradesReportsFixtures
    alias Lanttern.Assessments
    alias Lanttern.AssessmentsFixtures
    alias Lanttern.GradingFixtures
    alias Lanttern.LearningContextFixtures
    alias Lanttern.ReportingFixtures
    alias Lanttern.SchoolsFixtures
    alias Lanttern.TaxonomyFixtures

    test "calculate_student_grade/4 returns the correct student_grade_report_entry" do
      # marking scale
      # ordinal scale, 4 levels
      # 1 eme: 0.4
      # 2 pro: 0.6
      # 3 ach: 0.85
      # 4 exc: 1.0
      #
      # grades scale
      # ordinal scale, 5 levels A, B, C, D, E (1.0, 0.85, 0.7, 0.5, 0)
      # breakpoints: E - 0.5 - D - 0.6 - C - 0.8 - B - 0.9 - A
      #
      # compositions: ap1 = w1, ap2 = w2, ap3 = w3, ap3_diff = w3
      #
      # test cases (in ap order)
      # eme - pro - ach = 0.69167 = C
      # ach - ach - exc = 0.92500 = A
      # eme - pro - pro = 0.56667 = D (use diff in ap3)
      #
      # extra test cases
      # update - running the function for an existing student/subject/cycle should update it
      # nil - when there's no entries, it should return {:ok, nil}
      # nil + update - when there's no entries but there's an existing student/subject/cycle, delete it

      marking_scale = GradingFixtures.scale_fixture(%{type: "ordinal"})

      ov_eme =
        GradingFixtures.ordinal_value_fixture(%{scale_id: marking_scale.id, normalized_value: 0.4})

      ov_pro =
        GradingFixtures.ordinal_value_fixture(%{scale_id: marking_scale.id, normalized_value: 0.6})

      ov_ach =
        GradingFixtures.ordinal_value_fixture(%{
          scale_id: marking_scale.id,
          normalized_value: 0.85
        })

      ov_exc =
        GradingFixtures.ordinal_value_fixture(%{scale_id: marking_scale.id, normalized_value: 1.0})

      grading_scale =
        GradingFixtures.scale_fixture(%{type: "ordinal", breakpoints: [0.5, 0.6, 0.8, 0.9]})

      ov_a =
        GradingFixtures.ordinal_value_fixture(%{scale_id: grading_scale.id, normalized_value: 1.0})

      _ov_b =
        GradingFixtures.ordinal_value_fixture(%{
          scale_id: grading_scale.id,
          normalized_value: 0.85
        })

      ov_c =
        GradingFixtures.ordinal_value_fixture(%{scale_id: grading_scale.id, normalized_value: 0.7})

      ov_d =
        GradingFixtures.ordinal_value_fixture(%{scale_id: grading_scale.id, normalized_value: 0.5})

      _ov_e =
        GradingFixtures.ordinal_value_fixture(%{scale_id: grading_scale.id, normalized_value: 0.0})

      strand = LearningContextFixtures.strand_fixture()

      goal_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand.id,
          scale_id: marking_scale.id
        })

      goal_2 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand.id,
          scale_id: marking_scale.id
        })

      goal_3 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand.id,
          scale_id: marking_scale.id
        })

      goal_diff =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand.id,
          scale_id: marking_scale.id,
          is_differentiation: true
        })

      subject = TaxonomyFixtures.subject_fixture()
      cycle = SchoolsFixtures.cycle_fixture()
      grades_report = ReportingFixtures.grades_report_fixture(%{scale_id: grading_scale.id})

      grades_report_cycle =
        ReportingFixtures.grades_report_cycle_fixture(%{
          school_cycle_id: cycle.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject =
        ReportingFixtures.grades_report_subject_fixture(%{
          subject_id: subject.id,
          grades_report_id: grades_report.id
        })

      report_card =
        ReportingFixtures.report_card_fixture(%{
          school_cycle_id: cycle.id,
          grades_report_id: grades_report.id
        })

      _grade_component_1 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject.id,
          assessment_point_id: goal_1.id,
          weight: 1.0
        })

      _grade_component_2 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject.id,
          assessment_point_id: goal_2.id,
          weight: 2.0
        })

      _grade_component_3 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject.id,
          assessment_point_id: goal_3.id,
          weight: 3.0
        })

      _grade_component_diff =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject.id,
          assessment_point_id: goal_diff.id,
          weight: 3.0
        })

      # extra fixtures for query test

      other_goal =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand.id,
          scale_id: marking_scale.id
        })

      other_subject = TaxonomyFixtures.subject_fixture()
      other_cycle = SchoolsFixtures.cycle_fixture()

      _other_grades_report_cycle =
        ReportingFixtures.grades_report_cycle_fixture(%{
          school_cycle_id: other_cycle.id,
          grades_report_id: grades_report.id
        })

      _other_grades_report_subject =
        ReportingFixtures.grades_report_subject_fixture(%{
          subject_id: other_subject.id,
          grades_report_id: grades_report.id
        })

      _other_grade_component =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: other_subject.id,
          assessment_point_id: other_goal.id
        })

      # case 1
      std_1 = SchoolsFixtures.student_fixture()

      _entry_1_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_1.id,
          assessment_point_id: goal_1.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_eme.id
        })

      _entry_1_2 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_1.id,
          assessment_point_id: goal_2.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_pro.id
        })

      _entry_1_3 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_1.id,
          assessment_point_id: goal_3.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_ach.id
        })

      # extra fixtures for query test

      _other_entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_1.id,
          assessment_point_id: other_goal.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_ach.id
        })

      expected_ov_id = ov_c.id
      expected_std_id = std_1.id

      assert {:ok,
              %StudentGradeReportEntry{
                student_id: ^expected_std_id,
                composition_normalized_value: 0.69167,
                ordinal_value_id: ^expected_ov_id
              },
              :created} =
               GradesReports.calculate_student_grade(
                 std_1.id,
                 grades_report.id,
                 grades_report_cycle.id,
                 grades_report_subject.id
               )

      # case 2
      std_2 = SchoolsFixtures.student_fixture()

      _entry_2_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_2.id,
          assessment_point_id: goal_1.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_ach.id
        })

      _entry_2_2 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_2.id,
          assessment_point_id: goal_2.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_ach.id
        })

      _entry_2_3 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_2.id,
          assessment_point_id: goal_3.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_exc.id
        })

      expected_ov_id = ov_a.id
      expected_std_id = std_2.id

      assert {:ok,
              %StudentGradeReportEntry{
                student_id: ^expected_std_id,
                composition_normalized_value: 0.925,
                ordinal_value_id: ^expected_ov_id
              },
              :created} =
               GradesReports.calculate_student_grade(
                 std_2.id,
                 grades_report.id,
                 grades_report_cycle.id,
                 grades_report_subject.id
               )

      # case 3 (diff)
      std_3 = SchoolsFixtures.student_fixture()

      entry_3_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_3.id,
          assessment_point_id: goal_1.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_eme.id
        })

      entry_3_2 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_3.id,
          assessment_point_id: goal_2.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_pro.id
        })

      entry_3_diff =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_3.id,
          assessment_point_id: goal_diff.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_pro.id
        })

      expected_ov_id = ov_d.id
      expected_std_id = std_3.id

      assert {:ok,
              %StudentGradeReportEntry{
                id: sgre_3_id,
                student_id: ^expected_std_id,
                composition_normalized_value: 0.56667,
                ordinal_value_id: ^expected_ov_id
              },
              :created} =
               GradesReports.calculate_student_grade(
                 std_3.id,
                 grades_report.id,
                 grades_report_cycle.id,
                 grades_report_subject.id
               )

      # UPDATE CASE
      # when calculating for an existing student/cycle/subject, update the entry
      assert {:ok,
              %StudentGradeReportEntry{
                id: ^sgre_3_id,
                student_id: ^expected_std_id,
                composition_normalized_value: 0.56667,
                ordinal_value_id: ^expected_ov_id
              },
              :updated} =
               GradesReports.calculate_student_grade(
                 std_3.id,
                 grades_report.id,
                 grades_report_cycle.id,
                 grades_report_subject.id
               )

      # UPDATE + EMPTY CASE
      # when calculating for an existing student/cycle/subject,
      # that is now empty, delete the entry

      # delete std 3 entries
      Assessments.delete_assessment_point_entry(entry_3_1)
      Assessments.delete_assessment_point_entry(entry_3_2)
      Assessments.delete_assessment_point_entry(entry_3_diff)

      assert {:ok, nil, :deleted} =
               GradesReports.calculate_student_grade(
                 std_3.id,
                 grades_report.id,
                 grades_report_cycle.id,
                 grades_report_subject.id
               )

      assert Repo.get(StudentGradeReportEntry, sgre_3_id) |> is_nil()

      # EMPTY CASE
      # case 4 (no entries)
      std_4 = SchoolsFixtures.student_fixture()

      # when there's no assessment point entries, return {:ok, nil}
      assert {:ok, nil, :noop} =
               GradesReports.calculate_student_grade(
                 std_4.id,
                 grades_report.id,
                 grades_report_cycle.id,
                 grades_report_subject.id
               )
    end

    test "calculate_student_grades/3 returns the correct student grades report entries for given cycle" do
      # marking scale
      # ordinal scale, 4 levels
      # 1 eme: 0.4
      # 2 pro: 0.6
      # 3 ach: 0.85
      # 4 exc: 1.0
      #
      # grades scale
      # ordinal scale, 5 levels A, B, C, D, E (1.0, 0.85, 0.7, 0.5, 0)
      # breakpoints: E - 0.5 - D - 0.6 - C - 0.8 - B - 0.9 - A
      #
      # compositions (same for each subject): ap1 = w1, ap2 = w2, ap3 = w3
      #
      # test cases (in ap order)
      # exc - ach - pro = 0.75000 = C (actually irrelevant, will be delete to test update + no entries case)
      # eme - ach - exc = 0.85000 = B
      # eme - eme - eme = 0.40000 = E
      #
      # no entries case: there's a 4th subject without entries. it should return nil
      # update case: subject 3 will be pre calculated. the function should update the std grade report entry
      # update + no entries case: when there's no entries but an existing student grades report entry, delete it

      marking_scale = GradingFixtures.scale_fixture(%{type: "ordinal"})

      ov_eme =
        GradingFixtures.ordinal_value_fixture(%{scale_id: marking_scale.id, normalized_value: 0.4})

      ov_pro =
        GradingFixtures.ordinal_value_fixture(%{scale_id: marking_scale.id, normalized_value: 0.6})

      ov_ach =
        GradingFixtures.ordinal_value_fixture(%{
          scale_id: marking_scale.id,
          normalized_value: 0.85
        })

      ov_exc =
        GradingFixtures.ordinal_value_fixture(%{scale_id: marking_scale.id, normalized_value: 1.0})

      grading_scale =
        GradingFixtures.scale_fixture(%{type: "ordinal", breakpoints: [0.5, 0.6, 0.8, 0.9]})

      _ov_a =
        GradingFixtures.ordinal_value_fixture(%{scale_id: grading_scale.id, normalized_value: 1.0})

      ov_b =
        GradingFixtures.ordinal_value_fixture(%{
          scale_id: grading_scale.id,
          normalized_value: 0.85
        })

      _ov_c =
        GradingFixtures.ordinal_value_fixture(%{scale_id: grading_scale.id, normalized_value: 0.7})

      _ov_d =
        GradingFixtures.ordinal_value_fixture(%{scale_id: grading_scale.id, normalized_value: 0.5})

      ov_e =
        GradingFixtures.ordinal_value_fixture(%{scale_id: grading_scale.id, normalized_value: 0.0})

      strand_1 = LearningContextFixtures.strand_fixture()
      strand_2 = LearningContextFixtures.strand_fixture()
      strand_3 = LearningContextFixtures.strand_fixture()

      goal_1_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_1.id,
          scale_id: marking_scale.id
        })

      goal_1_2 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_1.id,
          scale_id: marking_scale.id
        })

      goal_1_3 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_1.id,
          scale_id: marking_scale.id
        })

      goal_2_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_2.id,
          scale_id: marking_scale.id
        })

      goal_2_2 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_2.id,
          scale_id: marking_scale.id
        })

      goal_2_3 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_2.id,
          scale_id: marking_scale.id
        })

      goal_3_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_3.id,
          scale_id: marking_scale.id
        })

      goal_3_2 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_3.id,
          scale_id: marking_scale.id
        })

      goal_3_3 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_3.id,
          scale_id: marking_scale.id
        })

      subject_1 = TaxonomyFixtures.subject_fixture()
      subject_2 = TaxonomyFixtures.subject_fixture()
      subject_3 = TaxonomyFixtures.subject_fixture()
      subject_4 = TaxonomyFixtures.subject_fixture()
      cycle = SchoolsFixtures.cycle_fixture()
      grades_report = ReportingFixtures.grades_report_fixture(%{scale_id: grading_scale.id})

      grades_report_cycle =
        ReportingFixtures.grades_report_cycle_fixture(%{
          school_cycle_id: cycle.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject_1 =
        ReportingFixtures.grades_report_subject_fixture(%{
          subject_id: subject_1.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject_2 =
        ReportingFixtures.grades_report_subject_fixture(%{
          subject_id: subject_2.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject_3 =
        ReportingFixtures.grades_report_subject_fixture(%{
          subject_id: subject_3.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject_4 =
        ReportingFixtures.grades_report_subject_fixture(%{
          subject_id: subject_4.id,
          grades_report_id: grades_report.id
        })

      report_card =
        ReportingFixtures.report_card_fixture(%{
          school_cycle_id: cycle.id,
          grades_report_id: grades_report.id
        })

      _grade_component_1_1 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_1.id,
          assessment_point_id: goal_1_1.id,
          weight: 1.0
        })

      _grade_component_1_2 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_1.id,
          assessment_point_id: goal_1_2.id,
          weight: 2.0
        })

      _grade_component_1_3 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_1.id,
          assessment_point_id: goal_1_3.id,
          weight: 3.0
        })

      _grade_component_2_1 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_2.id,
          assessment_point_id: goal_2_1.id,
          weight: 1.0
        })

      _grade_component_2_2 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_2.id,
          assessment_point_id: goal_2_2.id,
          weight: 2.0
        })

      _grade_component_2_3 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_2.id,
          assessment_point_id: goal_2_3.id,
          weight: 3.0
        })

      _grade_component_3_1 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_3.id,
          assessment_point_id: goal_3_1.id,
          weight: 1.0
        })

      _grade_component_3_2 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_3.id,
          assessment_point_id: goal_3_2.id,
          weight: 2.0
        })

      _grade_component_3_3 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_3.id,
          assessment_point_id: goal_3_3.id,
          weight: 3.0
        })

      std = SchoolsFixtures.student_fixture()

      # subject 1

      entry_1_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std.id,
          assessment_point_id: goal_1_1.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_exc.id
        })

      entry_1_2 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std.id,
          assessment_point_id: goal_1_2.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_ach.id
        })

      entry_1_3 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std.id,
          assessment_point_id: goal_1_3.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_pro.id
        })

      # subject 2

      _entry_2_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std.id,
          assessment_point_id: goal_2_1.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_eme.id
        })

      _entry_2_2 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std.id,
          assessment_point_id: goal_2_2.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_ach.id
        })

      _entry_2_3 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std.id,
          assessment_point_id: goal_2_3.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_exc.id
        })

      # subject 3

      _entry_3_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std.id,
          assessment_point_id: goal_3_1.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_eme.id
        })

      _entry_3_2 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std.id,
          assessment_point_id: goal_3_2.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_eme.id
        })

      _entry_3_diff =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std.id,
          assessment_point_id: goal_3_3.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_eme.id
        })

      # extra cases setup

      # UPDATE CASE - pre calculate subject 3
      {:ok, %{id: student_grade_report_entry_3_id}, :created} =
        GradesReports.calculate_student_grade(
          std.id,
          grades_report.id,
          grades_report_cycle.id,
          grades_report_subject_3.id
        )

      # UPDATE + EMPTY - pre calculate subject 1, then delete entries
      {:ok, %{id: student_grade_report_entry_1_id}, :created} =
        GradesReports.calculate_student_grade(
          std.id,
          grades_report.id,
          grades_report_cycle.id,
          grades_report_subject_1.id
        )

      Assessments.delete_assessment_point_entry(entry_1_1)
      Assessments.delete_assessment_point_entry(entry_1_2)
      Assessments.delete_assessment_point_entry(entry_1_3)

      # assert

      assert {:ok, %{created: 1, updated: 1, deleted: 1, noop: 1}} =
               GradesReports.calculate_student_grades(
                 std.id,
                 grades_report.id,
                 grades_report_cycle.id
               )

      # sub 1 - previously calculated should not exist anymore
      assert Repo.get(StudentGradeReportEntry, student_grade_report_entry_1_id) |> is_nil()

      # sub 2
      expected_student_id = std.id
      expected_ordinal_value_id = ov_b.id

      assert %{
               student_id: ^expected_student_id,
               composition_normalized_value: 0.85,
               ordinal_value_id: ^expected_ordinal_value_id
             } =
               Repo.get_by(
                 StudentGradeReportEntry,
                 student_id: std.id,
                 grades_report_cycle_id: grades_report_cycle.id,
                 grades_report_subject_id: grades_report_subject_2.id
               )

      # sub 3
      expected_ordinal_value_id = ov_e.id
      expected_grades_report_cycle_id = grades_report_cycle.id
      expected_grades_report_subject_id = grades_report_subject_3.id

      assert %{
               student_id: ^expected_student_id,
               composition_normalized_value: 0.4,
               ordinal_value_id: ^expected_ordinal_value_id,
               grades_report_cycle_id: ^expected_grades_report_cycle_id,
               grades_report_subject_id: ^expected_grades_report_subject_id
             } =
               Repo.get(
                 StudentGradeReportEntry,
                 student_grade_report_entry_3_id
               )

      # sub 4 - should not exist
      assert Repo.get_by(
               StudentGradeReportEntry,
               student_id: std.id,
               grades_report_cycle_id: grades_report_cycle.id,
               grades_report_subject_id: grades_report_subject_4.id
             )
             |> is_nil()
    end

    test "calculate_subject_grades/4 returns the correct student grades report entries for given cycle and subject" do
      # marking scale
      # ordinal scale, 4 levels
      # 1 eme: 0.4
      # 2 pro: 0.6
      # 3 ach: 0.85
      # 4 exc: 1.0
      #
      # grades scale
      # ordinal scale, 5 levels A, B, C, D, E (1.0, 0.85, 0.7, 0.5, 0)
      # breakpoints: E - 0.5 - D - 0.6 - C - 0.8 - B - 0.9 - A
      #
      # compositions: ap1 = w1, ap2 = w2, ap3 = w3
      #
      # test cases (in ap order)
      # std 1: exc - ach - pro = 0.75000 = C (actually irrelevant, will be delete to test update + no entries case)
      # std 2: eme - ach - exc = 0.85000 = B
      # std 3: eme - eme - eme = 0.40000 = E
      #
      # no entries case: there's a 4th student without entries. it should return nil
      # update case: student 3 will be pre calculated. the function should update the std grade report entry
      # update + no entries case: when there's no entries but an existing student grades report entry, delete it

      marking_scale = GradingFixtures.scale_fixture(%{type: "ordinal"})

      ov_eme =
        GradingFixtures.ordinal_value_fixture(%{scale_id: marking_scale.id, normalized_value: 0.4})

      ov_pro =
        GradingFixtures.ordinal_value_fixture(%{scale_id: marking_scale.id, normalized_value: 0.6})

      ov_ach =
        GradingFixtures.ordinal_value_fixture(%{
          scale_id: marking_scale.id,
          normalized_value: 0.85
        })

      ov_exc =
        GradingFixtures.ordinal_value_fixture(%{scale_id: marking_scale.id, normalized_value: 1.0})

      grading_scale =
        GradingFixtures.scale_fixture(%{type: "ordinal", breakpoints: [0.5, 0.6, 0.8, 0.9]})

      _ov_a =
        GradingFixtures.ordinal_value_fixture(%{scale_id: grading_scale.id, normalized_value: 1.0})

      ov_b =
        GradingFixtures.ordinal_value_fixture(%{
          scale_id: grading_scale.id,
          normalized_value: 0.85
        })

      _ov_c =
        GradingFixtures.ordinal_value_fixture(%{scale_id: grading_scale.id, normalized_value: 0.7})

      _ov_d =
        GradingFixtures.ordinal_value_fixture(%{scale_id: grading_scale.id, normalized_value: 0.5})

      ov_e =
        GradingFixtures.ordinal_value_fixture(%{scale_id: grading_scale.id, normalized_value: 0.0})

      strand_1 = LearningContextFixtures.strand_fixture()

      goal_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_1.id,
          scale_id: marking_scale.id
        })

      goal_2 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_1.id,
          scale_id: marking_scale.id
        })

      goal_3 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_1.id,
          scale_id: marking_scale.id
        })

      subject = TaxonomyFixtures.subject_fixture()
      cycle = SchoolsFixtures.cycle_fixture()
      grades_report = ReportingFixtures.grades_report_fixture(%{scale_id: grading_scale.id})

      grades_report_cycle =
        ReportingFixtures.grades_report_cycle_fixture(%{
          school_cycle_id: cycle.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject =
        ReportingFixtures.grades_report_subject_fixture(%{
          subject_id: subject.id,
          grades_report_id: grades_report.id
        })

      report_card =
        ReportingFixtures.report_card_fixture(%{
          school_cycle_id: cycle.id,
          grades_report_id: grades_report.id
        })

      _grade_component_1 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject.id,
          assessment_point_id: goal_1.id,
          weight: 1.0
        })

      _grade_component_2 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject.id,
          assessment_point_id: goal_2.id,
          weight: 2.0
        })

      _grade_component_3 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject.id,
          assessment_point_id: goal_3.id,
          weight: 3.0
        })

      std_1 = SchoolsFixtures.student_fixture()
      std_2 = SchoolsFixtures.student_fixture()
      std_3 = SchoolsFixtures.student_fixture()
      std_4 = SchoolsFixtures.student_fixture()
      std_5 = SchoolsFixtures.student_fixture()

      # student 1

      entry_1_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_1.id,
          assessment_point_id: goal_1.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_exc.id
        })

      entry_1_2 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_1.id,
          assessment_point_id: goal_2.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_ach.id
        })

      entry_1_3 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_1.id,
          assessment_point_id: goal_3.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_pro.id
        })

      # student 2

      _entry_2_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_2.id,
          assessment_point_id: goal_1.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_eme.id
        })

      _entry_2_2 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_2.id,
          assessment_point_id: goal_2.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_ach.id
        })

      _entry_2_3 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_2.id,
          assessment_point_id: goal_3.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_exc.id
        })

      # student 3

      _entry_3_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_3.id,
          assessment_point_id: goal_1.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_eme.id
        })

      _entry_3_2 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_3.id,
          assessment_point_id: goal_2.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_eme.id
        })

      _entry_3_3 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_3.id,
          assessment_point_id: goal_3.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_eme.id
        })

      # student 5 (extra)

      _entry_5_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_5.id,
          assessment_point_id: goal_1.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_eme.id
        })

      # extra cases setup

      # UPDATE CASE - pre calculate student 3
      {:ok, %{id: student_3_grade_report_entry_id}, :created} =
        GradesReports.calculate_student_grade(
          std_3.id,
          grades_report.id,
          grades_report_cycle.id,
          grades_report_subject.id
        )

      # UPDATE + EMPTY - pre calculate student 1, then delete entries
      {:ok, %{id: student_1_grade_report_entry_id}, :created} =
        GradesReports.calculate_student_grade(
          std_1.id,
          grades_report.id,
          grades_report_cycle.id,
          grades_report_subject.id
        )

      Assessments.delete_assessment_point_entry(entry_1_1)
      Assessments.delete_assessment_point_entry(entry_1_2)
      Assessments.delete_assessment_point_entry(entry_1_3)

      # assert

      assert {:ok, %{created: 1, updated: 1, deleted: 1, noop: 1}} =
               GradesReports.calculate_subject_grades(
                 [std_1.id, std_2.id, std_3.id, std_4.id],
                 grades_report.id,
                 grades_report_cycle.id,
                 grades_report_subject.id
               )

      # std 1 - previously calculated should not exist anymore
      assert Repo.get(StudentGradeReportEntry, student_1_grade_report_entry_id) |> is_nil()

      # sub 2
      expected_ordinal_value_id = ov_b.id

      assert %{
               composition_normalized_value: 0.85,
               ordinal_value_id: ^expected_ordinal_value_id
             } =
               Repo.get_by(
                 StudentGradeReportEntry,
                 student_id: std_2.id,
                 grades_report_cycle_id: grades_report_cycle.id,
                 grades_report_subject_id: grades_report_subject.id
               )

      # sub 3
      expected_student_id = std_3.id
      expected_ordinal_value_id = ov_e.id
      expected_grades_report_cycle_id = grades_report_cycle.id
      expected_grades_report_subject_id = grades_report_subject.id

      assert %{
               composition_normalized_value: 0.4,
               student_id: ^expected_student_id,
               ordinal_value_id: ^expected_ordinal_value_id,
               grades_report_cycle_id: ^expected_grades_report_cycle_id,
               grades_report_subject_id: ^expected_grades_report_subject_id
             } =
               Repo.get(
                 StudentGradeReportEntry,
                 student_3_grade_report_entry_id
               )

      # sub 4 - should not exist
      assert Repo.get_by(
               StudentGradeReportEntry,
               student_id: std_4.id,
               grades_report_cycle_id: grades_report_cycle.id,
               grades_report_subject_id: grades_report_subject.id
             )
             |> is_nil()
    end

    test "calculate_cycle_grades/3 returns the correct student grades report entries for given cycle" do
      # marking scale
      # ordinal scale, 4 levels
      # 1 eme: 0.4
      # 2 pro: 0.6
      # 3 ach: 0.85
      # 4 exc: 1.0
      #
      # grades scale
      # ordinal scale, 5 levels A, B, C, D, E (1.0, 0.85, 0.7, 0.5, 0)
      # breakpoints: E - 0.5 - D - 0.6 - C - 0.8 - B - 0.9 - A
      #
      # compositions: ap1 = w1, ap2 = w2, ap3 = w3
      #
      # test cases (in ap order)
      # std 1 sub 1: exc - ach - pro = 0.75000 = C (actually irrelevant, will be delete to test update + no entries case)
      # std 2 sub 2: eme - ach - exc = 0.85000 = B
      # std 3 sub 3: eme - eme - eme = 0.40000 = E
      #
      # no entries case: there's a 4th student without entries. it should return nil
      # update case: student 3 will be pre calculated. the function should update the std grade report entry
      # update + no entries case: when there's no entries but an existing student grades report entry, delete it

      marking_scale = GradingFixtures.scale_fixture(%{type: "ordinal"})

      ov_eme =
        GradingFixtures.ordinal_value_fixture(%{scale_id: marking_scale.id, normalized_value: 0.4})

      ov_pro =
        GradingFixtures.ordinal_value_fixture(%{scale_id: marking_scale.id, normalized_value: 0.6})

      ov_ach =
        GradingFixtures.ordinal_value_fixture(%{
          scale_id: marking_scale.id,
          normalized_value: 0.85
        })

      ov_exc =
        GradingFixtures.ordinal_value_fixture(%{scale_id: marking_scale.id, normalized_value: 1.0})

      grading_scale =
        GradingFixtures.scale_fixture(%{type: "ordinal", breakpoints: [0.5, 0.6, 0.8, 0.9]})

      _ov_a =
        GradingFixtures.ordinal_value_fixture(%{scale_id: grading_scale.id, normalized_value: 1.0})

      ov_b =
        GradingFixtures.ordinal_value_fixture(%{
          scale_id: grading_scale.id,
          normalized_value: 0.85
        })

      _ov_c =
        GradingFixtures.ordinal_value_fixture(%{scale_id: grading_scale.id, normalized_value: 0.7})

      _ov_d =
        GradingFixtures.ordinal_value_fixture(%{scale_id: grading_scale.id, normalized_value: 0.5})

      ov_e =
        GradingFixtures.ordinal_value_fixture(%{scale_id: grading_scale.id, normalized_value: 0.0})

      strand_1 = LearningContextFixtures.strand_fixture()
      strand_2 = LearningContextFixtures.strand_fixture()
      strand_3 = LearningContextFixtures.strand_fixture()

      goal_1_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_1.id,
          scale_id: marking_scale.id
        })

      goal_1_2 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_1.id,
          scale_id: marking_scale.id
        })

      goal_1_3 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_1.id,
          scale_id: marking_scale.id
        })

      goal_2_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_2.id,
          scale_id: marking_scale.id
        })

      goal_2_2 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_2.id,
          scale_id: marking_scale.id
        })

      goal_2_3 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_2.id,
          scale_id: marking_scale.id
        })

      goal_3_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_3.id,
          scale_id: marking_scale.id
        })

      goal_3_2 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_3.id,
          scale_id: marking_scale.id
        })

      goal_3_3 =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand_3.id,
          scale_id: marking_scale.id
        })

      subject_1 = TaxonomyFixtures.subject_fixture()
      subject_2 = TaxonomyFixtures.subject_fixture()
      subject_3 = TaxonomyFixtures.subject_fixture()
      cycle = SchoolsFixtures.cycle_fixture()
      grades_report = ReportingFixtures.grades_report_fixture(%{scale_id: grading_scale.id})

      grades_report_cycle =
        ReportingFixtures.grades_report_cycle_fixture(%{
          school_cycle_id: cycle.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject_1 =
        ReportingFixtures.grades_report_subject_fixture(%{
          subject_id: subject_1.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject_2 =
        ReportingFixtures.grades_report_subject_fixture(%{
          subject_id: subject_2.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject_3 =
        ReportingFixtures.grades_report_subject_fixture(%{
          subject_id: subject_3.id,
          grades_report_id: grades_report.id
        })

      report_card =
        ReportingFixtures.report_card_fixture(%{
          school_cycle_id: cycle.id,
          grades_report_id: grades_report.id
        })

      _grade_component_1_1 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_1.id,
          assessment_point_id: goal_1_1.id,
          weight: 1.0
        })

      _grade_component_1_2 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_1.id,
          assessment_point_id: goal_1_2.id,
          weight: 2.0
        })

      _grade_component_1_3 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_1.id,
          assessment_point_id: goal_1_3.id,
          weight: 3.0
        })

      _grade_component_2_1 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_2.id,
          assessment_point_id: goal_2_1.id,
          weight: 1.0
        })

      _grade_component_2_2 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_2.id,
          assessment_point_id: goal_2_2.id,
          weight: 2.0
        })

      _grade_component_2_3 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_2.id,
          assessment_point_id: goal_2_3.id,
          weight: 3.0
        })

      _grade_component_3_1 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_3.id,
          assessment_point_id: goal_3_1.id,
          weight: 1.0
        })

      _grade_component_3_2 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_3.id,
          assessment_point_id: goal_3_2.id,
          weight: 2.0
        })

      _grade_component_3_3 =
        GradingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject_3.id,
          assessment_point_id: goal_3_3.id,
          weight: 3.0
        })

      std_1 = SchoolsFixtures.student_fixture()
      std_2 = SchoolsFixtures.student_fixture()
      std_3 = SchoolsFixtures.student_fixture()
      std_4 = SchoolsFixtures.student_fixture()
      std_5 = SchoolsFixtures.student_fixture()

      # student 1

      entry_1_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_1.id,
          assessment_point_id: goal_1_1.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_exc.id
        })

      entry_1_2 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_1.id,
          assessment_point_id: goal_1_2.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_ach.id
        })

      entry_1_3 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_1.id,
          assessment_point_id: goal_1_3.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_pro.id
        })

      # student 2

      _entry_2_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_2.id,
          assessment_point_id: goal_2_1.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_eme.id
        })

      _entry_2_2 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_2.id,
          assessment_point_id: goal_2_2.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_ach.id
        })

      _entry_2_3 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_2.id,
          assessment_point_id: goal_2_3.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_exc.id
        })

      # student 3

      _entry_3_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_3.id,
          assessment_point_id: goal_3_1.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_eme.id
        })

      _entry_3_2 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_3.id,
          assessment_point_id: goal_3_2.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_eme.id
        })

      _entry_3_3 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_3.id,
          assessment_point_id: goal_3_3.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_eme.id
        })

      # student 5 (extra)

      _entry_5_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: std_5.id,
          assessment_point_id: goal_1_1.id,
          scale_id: marking_scale.id,
          scale_type: "ordinal",
          ordinal_value_id: ov_eme.id
        })

      # extra cases setup

      # UPDATE CASE - pre calculate student 3
      {:ok, %{id: student_3_grade_report_entry_id}, :created} =
        GradesReports.calculate_student_grade(
          std_3.id,
          grades_report.id,
          grades_report_cycle.id,
          grades_report_subject_3.id
        )

      # UPDATE + EMPTY - pre calculate student 1, then delete entries
      {:ok, %{id: student_1_grade_report_entry_id}, :created} =
        GradesReports.calculate_student_grade(
          std_1.id,
          grades_report.id,
          grades_report_cycle.id,
          grades_report_subject_1.id
        )

      Assessments.delete_assessment_point_entry(entry_1_1)
      Assessments.delete_assessment_point_entry(entry_1_2)
      Assessments.delete_assessment_point_entry(entry_1_3)

      # assert

      assert {:ok, %{created: 1, updated: 1, deleted: 1, noop: 9}} =
               GradesReports.calculate_cycle_grades(
                 [std_1.id, std_2.id, std_3.id, std_4.id],
                 grades_report.id,
                 grades_report_cycle.id
               )

      # std 1 - previously calculated should not exist anymore
      assert Repo.get(StudentGradeReportEntry, student_1_grade_report_entry_id) |> is_nil()

      # sub 2
      expected_ordinal_value_id = ov_b.id

      assert %{
               composition_normalized_value: 0.85,
               ordinal_value_id: ^expected_ordinal_value_id
             } =
               Repo.get_by(
                 StudentGradeReportEntry,
                 student_id: std_2.id,
                 grades_report_cycle_id: grades_report_cycle.id,
                 grades_report_subject_id: grades_report_subject_2.id
               )

      # sub 3
      expected_student_id = std_3.id
      expected_ordinal_value_id = ov_e.id
      expected_grades_report_cycle_id = grades_report_cycle.id
      expected_grades_report_subject_id = grades_report_subject_3.id

      assert %{
               composition_normalized_value: 0.4,
               student_id: ^expected_student_id,
               ordinal_value_id: ^expected_ordinal_value_id,
               grades_report_cycle_id: ^expected_grades_report_cycle_id,
               grades_report_subject_id: ^expected_grades_report_subject_id
             } =
               Repo.get(
                 StudentGradeReportEntry,
                 student_3_grade_report_entry_id
               )

      # sub 4 - should not exist
      assert Repo.get_by(
               StudentGradeReportEntry,
               student_id: std_4.id,
               grades_report_cycle_id: grades_report_cycle.id
             )
             |> is_nil()
    end
  end

  describe "students grades display" do
    alias Lanttern.GradesReports.StudentGradeReportEntry

    import Lanttern.GradesReportsFixtures
    alias Lanttern.AssessmentsFixtures
    alias Lanttern.GradingFixtures
    alias Lanttern.LearningContextFixtures
    alias Lanttern.ReportingFixtures
    alias Lanttern.SchoolsFixtures
    alias Lanttern.TaxonomyFixtures

    test "build_students_grades_map/3 returns the correct map" do
      # expected structure
      #       | sub 1     | sub 2     | sub 3
      # std 1 | entry_1_1 | entry_1_2 | entry_1_3
      # std 2 | entry_2_1 | nil       | nil
      # std 3 | entry_3_1 | entry_3_2 | nil

      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ov = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id})

      cycle = SchoolsFixtures.cycle_fixture()
      grades_report = ReportingFixtures.grades_report_fixture(%{scale_id: scale.id})

      grades_report_cycle =
        ReportingFixtures.grades_report_cycle_fixture(%{
          school_cycle_id: cycle.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject_1 =
        ReportingFixtures.grades_report_subject_fixture(%{
          grades_report_id: grades_report.id
        })

      grades_report_subject_2 =
        ReportingFixtures.grades_report_subject_fixture(%{
          grades_report_id: grades_report.id
        })

      grades_report_subject_3 =
        ReportingFixtures.grades_report_subject_fixture(%{
          grades_report_id: grades_report.id
        })

      std_1 = SchoolsFixtures.student_fixture()
      std_2 = SchoolsFixtures.student_fixture()
      std_3 = SchoolsFixtures.student_fixture()

      entry_1_1 =
        student_grade_report_entry_fixture(%{
          student_id: std_1.id,
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_1.id,
          ordinal_value_id: ov.id
        })

      entry_1_2 =
        student_grade_report_entry_fixture(%{
          student_id: std_1.id,
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_2.id
        })

      entry_1_3 =
        student_grade_report_entry_fixture(%{
          student_id: std_1.id,
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_3.id
        })

      entry_2_1 =
        student_grade_report_entry_fixture(%{
          student_id: std_2.id,
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_1.id
        })

      entry_3_1 =
        student_grade_report_entry_fixture(%{
          student_id: std_3.id,
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_1.id
        })

      entry_3_2 =
        student_grade_report_entry_fixture(%{
          student_id: std_3.id,
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_2.id
        })

      # extra fixtures for query test (TBD)

      assert expected =
               GradesReports.build_students_grades_map(
                 [std_1.id, std_2.id, std_3.id],
                 grades_report.id,
                 cycle.id
               )

      assert expected_std_1 = expected[std_1.id]
      assert expected_entry_1_1 = expected_std_1[grades_report_subject_1.id]
      assert expected_entry_1_1.id == entry_1_1.id
      assert expected_entry_1_1.ordinal_value.id == ov.id
      assert expected_entry_1_2 = expected_std_1[grades_report_subject_2.id]
      assert expected_entry_1_2.id == entry_1_2.id
      assert is_nil(expected_entry_1_2.ordinal_value)
      assert expected_entry_1_3 = expected_std_1[grades_report_subject_3.id]
      assert expected_entry_1_3.id == entry_1_3.id
      assert is_nil(expected_entry_1_3.ordinal_value)

      assert expected_std_2 = expected[std_2.id]
      assert expected_entry_2_1 = expected_std_2[grades_report_subject_1.id]
      assert expected_entry_2_1.id == entry_2_1.id
      assert is_nil(expected_entry_2_1.ordinal_value)
      assert is_nil(expected_std_2[grades_report_subject_2.id])
      assert is_nil(expected_std_2[grades_report_subject_3.id])

      assert expected_std_3 = expected[std_3.id]
      assert expected_entry_3_1 = expected_std_3[grades_report_subject_1.id]
      assert expected_entry_3_1.id == entry_3_1.id
      assert is_nil(expected_entry_3_1.ordinal_value)
      assert expected_entry_3_2 = expected_std_3[grades_report_subject_2.id]
      assert expected_entry_3_2.id == entry_3_2.id
      assert is_nil(expected_entry_3_2.ordinal_value)
      assert is_nil(expected_std_3[grades_report_subject_3.id])
    end

    test "build_student_grades_map/1 returns the correct map" do
      # expected structure
      #       | cycle 1   | cycle 2   | cycle 3
      # sub 1 | entry_1_1 | entry_2_1 | entry_3_1
      # sub 2 | entry_1_2 | nil       | nil
      # sub 3 | entry_1_3 | entry_2_3 | nil

      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ov = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id})

      std = SchoolsFixtures.student_fixture()
      grades_report = ReportingFixtures.grades_report_fixture(%{scale_id: scale.id})
      report_card = ReportingFixtures.report_card_fixture(%{grades_report_id: grades_report.id})

      student_grades_report =
        ReportingFixtures.student_report_card_fixture(%{
          student_id: std.id,
          report_card_id: report_card.id
        })

      cycle_1 = SchoolsFixtures.cycle_fixture()
      cycle_2 = SchoolsFixtures.cycle_fixture()
      cycle_3 = SchoolsFixtures.cycle_fixture()

      grades_report_cycle_1 =
        ReportingFixtures.grades_report_cycle_fixture(%{
          school_cycle_id: cycle_1.id,
          grades_report_id: grades_report.id
        })

      grades_report_cycle_2 =
        ReportingFixtures.grades_report_cycle_fixture(%{
          school_cycle_id: cycle_2.id,
          grades_report_id: grades_report.id
        })

      grades_report_cycle_3 =
        ReportingFixtures.grades_report_cycle_fixture(%{
          school_cycle_id: cycle_3.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject_1 =
        ReportingFixtures.grades_report_subject_fixture(%{
          grades_report_id: grades_report.id
        })

      grades_report_subject_2 =
        ReportingFixtures.grades_report_subject_fixture(%{
          grades_report_id: grades_report.id
        })

      grades_report_subject_3 =
        ReportingFixtures.grades_report_subject_fixture(%{
          grades_report_id: grades_report.id
        })

      entry_1_1 =
        student_grade_report_entry_fixture(%{
          student_id: std.id,
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle_1.id,
          grades_report_subject_id: grades_report_subject_1.id,
          ordinal_value_id: ov.id
        })

      entry_1_2 =
        student_grade_report_entry_fixture(%{
          student_id: std.id,
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle_1.id,
          grades_report_subject_id: grades_report_subject_2.id
        })

      entry_1_3 =
        student_grade_report_entry_fixture(%{
          student_id: std.id,
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle_1.id,
          grades_report_subject_id: grades_report_subject_3.id
        })

      entry_2_1 =
        student_grade_report_entry_fixture(%{
          student_id: std.id,
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle_2.id,
          grades_report_subject_id: grades_report_subject_1.id
        })

      entry_2_3 =
        student_grade_report_entry_fixture(%{
          student_id: std.id,
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle_2.id,
          grades_report_subject_id: grades_report_subject_3.id
        })

      entry_3_1 =
        student_grade_report_entry_fixture(%{
          student_id: std.id,
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle_3.id,
          grades_report_subject_id: grades_report_subject_1.id
        })

      # extra fixtures for query test (TBD)

      assert expected = GradesReports.build_student_grades_map(student_grades_report.id)

      # expected structure
      #       | cycle 1   | cycle 2   | cycle 3
      # sub 1 | entry_1_1 | entry_2_1 | entry_3_1
      # sub 2 | entry_1_2 | nil       | nil
      # sub 3 | entry_1_3 | entry_2_3 | nil

      assert expected_cycle_1 = expected[grades_report_cycle_1.id]
      assert expected_entry_1_1 = expected_cycle_1[grades_report_subject_1.id]
      assert expected_entry_1_1.id == entry_1_1.id
      assert expected_entry_1_1.ordinal_value.id == ov.id
      assert expected_entry_1_2 = expected_cycle_1[grades_report_subject_2.id]
      assert expected_entry_1_2.id == entry_1_2.id
      assert is_nil(expected_entry_1_2.ordinal_value)
      assert expected_entry_1_3 = expected_cycle_1[grades_report_subject_3.id]
      assert expected_entry_1_3.id == entry_1_3.id
      assert is_nil(expected_entry_1_3.ordinal_value)

      assert expected_cycle_2 = expected[grades_report_cycle_2.id]
      assert expected_entry_2_1 = expected_cycle_2[grades_report_subject_1.id]
      assert expected_entry_2_1.id == entry_2_1.id
      assert is_nil(expected_entry_2_1.ordinal_value)
      assert is_nil(expected_cycle_2[grades_report_subject_2.id])
      assert expected_entry_2_3 = expected_cycle_2[grades_report_subject_3.id]
      assert expected_entry_2_3.id == entry_2_3.id
      assert is_nil(expected_entry_2_3.ordinal_value)

      assert expected_cycle_3 = expected[grades_report_cycle_3.id]
      assert expected_entry_3_1 = expected_cycle_3[grades_report_subject_1.id]
      assert expected_entry_3_1.id == entry_3_1.id
      assert is_nil(expected_entry_3_1.ordinal_value)
      assert is_nil(expected_cycle_3[grades_report_subject_2.id])
      assert is_nil(expected_cycle_3[grades_report_subject_3.id])
    end
  end
end
