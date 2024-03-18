defmodule Lanttern.GradesReportsTest do
  use Lanttern.DataCase

  alias Lanttern.GradesReports

  describe "student_grade_report_entries" do
    alias Lanttern.GradesReports.StudentGradeReportEntry

    import Lanttern.GradesReportsFixtures

    @invalid_attrs %{comment: nil, normalized_value: nil, score: nil}

    test "list_student_grade_report_entries/0 returns all student_grade_report_entries" do
      student_grade_report_entry = student_grade_report_entry_fixture()
      assert GradesReports.list_student_grade_report_entries() == [student_grade_report_entry]
    end

    test "get_student_grade_report_entry!/1 returns the student_grade_report_entry with given id" do
      student_grade_report_entry = student_grade_report_entry_fixture()

      assert GradesReports.get_student_grade_report_entry!(student_grade_report_entry.id) ==
               student_grade_report_entry
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
        normalized_value: 0.5,
        student_id: student.id,
        grades_report_id: grades_report.id,
        grades_report_cycle_id: grades_report_cycle.id,
        grades_report_subject_id: grades_report_subject.id
      }

      assert {:ok, %StudentGradeReportEntry{} = student_grade_report_entry} =
               GradesReports.create_student_grade_report_entry(valid_attrs)

      assert student_grade_report_entry.comment == "some comment"
      assert student_grade_report_entry.normalized_value == 0.5
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
      update_attrs = %{comment: "some updated comment", normalized_value: 0.7, score: 456.7}

      assert {:ok, %StudentGradeReportEntry{} = student_grade_report_entry} =
               GradesReports.update_student_grade_report_entry(
                 student_grade_report_entry,
                 update_attrs
               )

      assert student_grade_report_entry.comment == "some updated comment"
      assert student_grade_report_entry.normalized_value == 0.7
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
    alias Lanttern.AssessmentsFixtures
    alias Lanttern.GradingFixtures
    alias Lanttern.LearningContextFixtures
    alias Lanttern.ReportingFixtures
    alias Lanttern.SchoolsFixtures
    alias Lanttern.TaxonomyFixtures

    test "calculate_student_grade/1 returns the correct student_grade_report_entry" do
      # marking scale
      # ordinal scale, 4 levels
      # 1 eme: 0.4
      # 2 pro: 0.6
      # 3 ach: 0.85
      # 4 exc: 1.0
      #
      # grades scale
      # ordinal scale, 5 levels A, B, C, D, E (1.0, 0.85, 0.7, 0.5, 0)
      # breakpoints: E - 0.4 - D - 0.6 - C - 0.8 - B - 0.9 - A
      #
      # compositions: ap1 = w1, ap2 = w2, ap3 = w3, ap3_diff = w3
      #
      # test cases (in ap order)
      # eme - pro - ach = 0.69167 = C
      # ach - ach - exc = 0.92500 = A
      # eme - eme - pro = 0.50000 = D (use diff in ap3)

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
        GradingFixtures.scale_fixture(%{type: "ordinal", breakpoints: [0.4, 0.6, 0.8, 0.9]})

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
        ReportingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject.id,
          assessment_point_id: goal_1.id,
          weight: 1.0
        })

      _grade_component_2 =
        ReportingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject.id,
          assessment_point_id: goal_2.id,
          weight: 2.0
        })

      _grade_component_3 =
        ReportingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject.id,
          assessment_point_id: goal_3.id,
          weight: 3.0
        })

      _grade_component_diff =
        ReportingFixtures.grade_component_fixture(%{
          report_card_id: report_card.id,
          subject_id: subject.id,
          assessment_point_id: goal_diff.id,
          weight: 3.0
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

      expected_ov_id = ov_c.id
      expected_std_id = std_1.id

      assert {:ok,
              %StudentGradeReportEntry{
                student_id: ^expected_std_id,
                normalized_value: 0.69167,
                ordinal_value_id: ^expected_ov_id
              }} =
               GradesReports.calculate_student_grade(
                 student_id: std_1.id,
                 grades_report_cycle_id: grades_report_cycle.id,
                 grades_report_subject_id: grades_report_subject.id
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
                normalized_value: 0.925,
                ordinal_value_id: ^expected_ov_id
              }} =
               GradesReports.calculate_student_grade(
                 student_id: std_2.id,
                 grades_report_cycle_id: grades_report_cycle.id,
                 grades_report_subject_id: grades_report_subject.id
               )

      # case 3 (diff)
      std_3 = SchoolsFixtures.student_fixture()

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

      _entry_3_diff =
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
                student_id: ^expected_std_id,
                normalized_value: 0.5,
                ordinal_value_id: ^expected_ov_id
              }} =
               GradesReports.calculate_student_grade(
                 student_id: std_3.id,
                 grades_report_cycle_id: grades_report_cycle.id,
                 grades_report_subject_id: grades_report_subject.id
               )
    end
  end
end
