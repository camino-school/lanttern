defmodule Lanttern.GradesReportsTest do
  use Lanttern.DataCase
  alias Lanttern.Repo

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
      grades_report = grades_report_fixture()

      grades_report_cycle =
        grades_report_cycle_fixture(%{
          grades_report_id: grades_report.id
        })

      grades_report_subject =
        grades_report_subject_fixture(%{
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

  describe "grades_reports" do
    alias Lanttern.GradesReports.GradesReport

    import Lanttern.GradesReportsFixtures
    alias Lanttern.ReportingFixtures
    alias Lanttern.SchoolsFixtures
    alias Lanttern.TaxonomyFixtures

    @invalid_attrs %{info: "blah", scale_id: nil}

    test "list_grades_reports/1 returns all grades_reports" do
      grades_report = grades_report_fixture()
      assert GradesReports.list_grades_reports() == [grades_report]
    end

    test "list_grades_reports/1 with load grid opt returns all grades_reports with linked and ordered cycles and subjects" do
      cycle_2024 =
        SchoolsFixtures.cycle_fixture(%{start_at: ~D[2024-01-01], end_at: ~D[2024-12-31]})

      cycle_2024_1 =
        SchoolsFixtures.cycle_fixture(%{start_at: ~D[2024-01-01], end_at: ~D[2024-06-30]})

      cycle_2024_2 =
        SchoolsFixtures.cycle_fixture(%{start_at: ~D[2024-07-01], end_at: ~D[2024-12-31]})

      subject_a = TaxonomyFixtures.subject_fixture()
      subject_b = TaxonomyFixtures.subject_fixture()
      subject_c = TaxonomyFixtures.subject_fixture()

      grades_report = grades_report_fixture(%{school_cycle_id: cycle_2024.id})

      grades_report_cycle_2024_1 =
        grades_report_cycle_fixture(%{
          grades_report_id: grades_report.id,
          school_cycle_id: cycle_2024_1.id
        })

      grades_report_cycle_2024_2 =
        grades_report_cycle_fixture(%{
          grades_report_id: grades_report.id,
          school_cycle_id: cycle_2024_2.id
        })

      # subjects order c, b, a

      grades_report_subject_c =
        grades_report_subject_fixture(%{
          grades_report_id: grades_report.id,
          subject_id: subject_c.id
        })

      grades_report_subject_b =
        grades_report_subject_fixture(%{
          grades_report_id: grades_report.id,
          subject_id: subject_b.id
        })

      grades_report_subject_a =
        grades_report_subject_fixture(%{
          grades_report_id: grades_report.id,
          subject_id: subject_a.id
        })

      assert [expected_grades_report] = GradesReports.list_grades_reports(load_grid: true)
      assert expected_grades_report.id == grades_report.id
      assert expected_grades_report.school_cycle.id == cycle_2024.id

      # check cycles
      assert [expected_grc_2024_1, expected_grc_2024_2] =
               expected_grades_report.grades_report_cycles

      assert expected_grc_2024_1.id == grades_report_cycle_2024_1.id
      assert expected_grc_2024_1.school_cycle.id == cycle_2024_1.id
      assert expected_grc_2024_2.id == grades_report_cycle_2024_2.id
      assert expected_grc_2024_2.school_cycle.id == cycle_2024_2.id

      # check subjects
      assert [expected_grs_c, expected_grs_b, expected_grs_a] =
               expected_grades_report.grades_report_subjects

      assert expected_grs_a.id == grades_report_subject_a.id
      assert expected_grs_a.subject.id == subject_a.id
      assert expected_grs_b.id == grades_report_subject_b.id
      assert expected_grs_b.subject.id == subject_b.id
      assert expected_grs_c.id == grades_report_subject_c.id
      assert expected_grs_c.subject.id == subject_c.id
    end

    test "get_grades_report!/2 returns the grades_report with given id" do
      grades_report = grades_report_fixture()
      assert GradesReports.get_grades_report!(grades_report.id) == grades_report
    end

    test "get_grades_report!/2 with preloads returns the grade report with given id and preloaded data" do
      school_cycle = SchoolsFixtures.cycle_fixture()
      grades_report = grades_report_fixture(%{school_cycle_id: school_cycle.id})

      expected = GradesReports.get_grades_report!(grades_report.id, preloads: :school_cycle)

      assert expected.id == grades_report.id
      assert expected.school_cycle == school_cycle
    end

    test "get_grades_report!/2 with load grid opt returns the grades report with linked and ordered cycles and subjects" do
      cycle_2024 =
        SchoolsFixtures.cycle_fixture(%{start_at: ~D[2024-01-01], end_at: ~D[2024-12-31]})

      cycle_2024_1 =
        SchoolsFixtures.cycle_fixture(%{start_at: ~D[2024-01-01], end_at: ~D[2024-06-30]})

      cycle_2024_2 =
        SchoolsFixtures.cycle_fixture(%{start_at: ~D[2024-07-01], end_at: ~D[2024-12-31]})

      subject_a = TaxonomyFixtures.subject_fixture()
      subject_b = TaxonomyFixtures.subject_fixture()
      subject_c = TaxonomyFixtures.subject_fixture()

      grades_report = grades_report_fixture(%{school_cycle_id: cycle_2024.id})

      grades_report_cycle_2024_1 =
        grades_report_cycle_fixture(%{
          grades_report_id: grades_report.id,
          school_cycle_id: cycle_2024_1.id
        })

      grades_report_cycle_2024_2 =
        grades_report_cycle_fixture(%{
          grades_report_id: grades_report.id,
          school_cycle_id: cycle_2024_2.id
        })

      # subjects order c, b, a

      grades_report_subject_c =
        grades_report_subject_fixture(%{
          grades_report_id: grades_report.id,
          subject_id: subject_c.id
        })

      grades_report_subject_b =
        grades_report_subject_fixture(%{
          grades_report_id: grades_report.id,
          subject_id: subject_b.id
        })

      grades_report_subject_a =
        grades_report_subject_fixture(%{
          grades_report_id: grades_report.id,
          subject_id: subject_a.id
        })

      assert expected_grades_report =
               GradesReports.get_grades_report!(grades_report.id, load_grid: true)

      assert expected_grades_report.id == grades_report.id
      assert expected_grades_report.school_cycle.id == cycle_2024.id

      # check sub cycles
      assert [expected_grc_2024_1, expected_grc_2024_2] =
               expected_grades_report.grades_report_cycles

      assert expected_grc_2024_1.id == grades_report_cycle_2024_1.id
      assert expected_grc_2024_1.school_cycle.id == cycle_2024_1.id
      assert expected_grc_2024_2.id == grades_report_cycle_2024_2.id
      assert expected_grc_2024_2.school_cycle.id == cycle_2024_2.id

      # check subjects
      assert [expected_grs_c, expected_grs_b, expected_grs_a] =
               expected_grades_report.grades_report_subjects

      assert expected_grs_a.id == grades_report_subject_a.id
      assert expected_grs_a.subject.id == subject_a.id
      assert expected_grs_b.id == grades_report_subject_b.id
      assert expected_grs_b.subject.id == subject_b.id
      assert expected_grs_c.id == grades_report_subject_c.id
      assert expected_grs_c.subject.id == subject_c.id
    end

    test "create_grades_report/1 with valid data creates a grades_report" do
      school_cycle = Lanttern.SchoolsFixtures.cycle_fixture()
      scale = Lanttern.GradingFixtures.scale_fixture()

      valid_attrs = %{
        name: "grade report name abc",
        school_cycle_id: school_cycle.id,
        scale_id: scale.id
      }

      assert {:ok, %GradesReport{} = grades_report} =
               GradesReports.create_grades_report(valid_attrs)

      assert grades_report.name == "grade report name abc"
      assert grades_report.school_cycle_id == school_cycle.id
      assert grades_report.scale_id == scale.id
    end

    test "create_grades_report/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = GradesReports.create_grades_report(@invalid_attrs)
    end

    test "update_grades_report/2 with valid data updates the grades_report" do
      grades_report = grades_report_fixture()
      update_attrs = %{info: "some updated info", is_differentiation: "true"}

      assert {:ok, %GradesReport{} = grades_report} =
               GradesReports.update_grades_report(grades_report, update_attrs)

      assert grades_report.info == "some updated info"
      assert grades_report.is_differentiation
    end

    test "update_grades_report/2 with invalid data returns error changeset" do
      grades_report = grades_report_fixture()

      assert {:error, %Ecto.Changeset{}} =
               GradesReports.update_grades_report(grades_report, @invalid_attrs)

      assert grades_report == GradesReports.get_grades_report!(grades_report.id)
    end

    test "delete_grades_report/1 deletes the grades_report" do
      grades_report = grades_report_fixture()
      assert {:ok, %GradesReport{}} = GradesReports.delete_grades_report(grades_report)

      assert_raise Ecto.NoResultsError, fn ->
        GradesReports.get_grades_report!(grades_report.id)
      end
    end

    test "change_grades_report/1 returns a grades_report changeset" do
      grades_report = grades_report_fixture()
      assert %Ecto.Changeset{} = GradesReports.change_grades_report(grades_report)
    end
  end

  describe "grades report subjects" do
    alias Lanttern.GradesReports.GradesReportSubject

    import Lanttern.GradesReportsFixtures
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
               GradesReports.list_grades_report_subjects(grades_report.id)

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
               GradesReports.add_subject_to_grades_report(valid_attrs)

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
               GradesReports.add_subject_to_grades_report(valid_attrs)

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
               GradesReports.update_grades_report_subjects_positions(
                 sorted_grades_report_subjects_ids
               )

      assert [
               expected_grs_2,
               expected_grs_3,
               expected_grs_1,
               expected_grs_4
             ] =
               GradesReports.list_grades_report_subjects(grades_report.id)

      assert expected_grs_1.id == grades_report_subject_1.id
      assert expected_grs_2.id == grades_report_subject_2.id
      assert expected_grs_3.id == grades_report_subject_3.id
      assert expected_grs_4.id == grades_report_subject_4.id
    end

    test "delete_grades_report_subject/1 deletes the grades_report_subject" do
      grades_report_subject = grades_report_subject_fixture()

      assert {:ok, %GradesReportSubject{}} =
               GradesReports.delete_grades_report_subject(grades_report_subject)

      assert_raise Ecto.NoResultsError, fn ->
        Repo.get!(GradesReportSubject, grades_report_subject.id)
      end
    end
  end

  describe "grades report cycles" do
    alias Lanttern.GradesReports.GradesReportCycle

    import Lanttern.GradesReportsFixtures
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
               GradesReports.list_grades_report_cycles(grades_report.id)

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
               GradesReports.add_cycle_to_grades_report(valid_attrs)

      assert grades_report_cycle.grades_report_id == grades_report.id
      assert grades_report_cycle.school_cycle_id == school_cycle.id
    end

    test "update_grades_report_cycle/2 with valid data updates the grades_report_cycle" do
      grades_report_cycle = grades_report_cycle_fixture()
      update_attrs = %{weight: 123.0}

      assert {:ok, %GradesReportCycle{} = grades_report_cycle} =
               GradesReports.update_grades_report_cycle(grades_report_cycle, update_attrs)

      assert grades_report_cycle.weight == 123.0
    end

    test "update_grades_report_cycle/2 with invalid data returns error changeset" do
      grades_report_cycle = grades_report_cycle_fixture()
      invalid_attrs = %{weight: "abc"}

      assert {:error, %Ecto.Changeset{}} =
               GradesReports.update_grades_report_cycle(grades_report_cycle, invalid_attrs)

      assert grades_report_cycle == Repo.get!(GradesReportCycle, grades_report_cycle.id)
    end

    test "delete_grades_report_cycle/1 deletes the grades_report_cycle" do
      grades_report_cycle = grades_report_cycle_fixture()

      assert {:ok, %GradesReportCycle{}} =
               GradesReports.delete_grades_report_cycle(grades_report_cycle)

      assert_raise Ecto.NoResultsError, fn ->
        Repo.get!(GradesReportCycle, grades_report_cycle.id)
      end
    end
  end

  describe "grade composition" do
    import Lanttern.GradesReportsFixtures

    alias Lanttern.AssessmentsFixtures
    alias Lanttern.CurriculaFixtures
    alias Lanttern.GradingFixtures
    alias Lanttern.LearningContextFixtures
    alias Lanttern.TaxonomyFixtures

    test "list_grade_composition/2 returns all report card's subject grade composition assessment points" do
      strand = LearningContextFixtures.strand_fixture()

      cur_component = CurriculaFixtures.curriculum_component_fixture()

      ci_1 =
        CurriculaFixtures.curriculum_item_fixture(curriculum_component_id: cur_component.id)

      ci_2 =
        CurriculaFixtures.curriculum_item_fixture(curriculum_component_id: cur_component.id)

      ast_point_1 =
        AssessmentsFixtures.assessment_point_fixture(
          strand_id: strand.id,
          curriculum_item_id: ci_1.id
        )

      ast_point_2 =
        AssessmentsFixtures.assessment_point_fixture(
          strand_id: strand.id,
          curriculum_item_id: ci_2.id
        )

      grades_report = grades_report_fixture()
      grades_report_cycle = grades_report_cycle_fixture(%{grades_report_id: grades_report.id})
      grades_report_subject = grades_report_subject_fixture(%{grades_report_id: grades_report.id})

      grade_component_1 =
        GradingFixtures.grade_component_fixture(%{
          weight: 2.0,
          assessment_point_id: ast_point_1.id,
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject.id
        })

      grade_component_2 =
        GradingFixtures.grade_component_fixture(%{
          weight: 1.0,
          assessment_point_id: ast_point_2.id,
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject.id
        })

      # extra fixtures to test filter
      other_strand = LearningContextFixtures.strand_fixture()
      other_ast_point = AssessmentsFixtures.assessment_point_fixture(strand_id: other_strand.id)

      other_grades_report_cycle =
        grades_report_cycle_fixture(%{grades_report_id: grades_report.id})

      other_grades_report_subject =
        grades_report_subject_fixture(%{grades_report_id: grades_report.id})

      _other_grade_component =
        GradingFixtures.grade_component_fixture(%{
          assessment_point_id: other_ast_point.id,
          grades_report_id: grades_report.id,
          grades_report_cycle_id: other_grades_report_cycle.id,
          grades_report_subject_id: other_grades_report_subject.id
        })

      assert [expected_grade_component_1, expected_grade_component_2] =
               GradesReports.list_grade_composition(
                 grades_report_cycle.id,
                 grades_report_subject.id
               )

      assert expected_grade_component_1.id == grade_component_1.id
      assert expected_grade_component_1.assessment_point.id == ast_point_1.id
      assert expected_grade_component_1.assessment_point.strand.id == strand.id
      assert expected_grade_component_1.assessment_point.curriculum_item.id == ci_1.id

      assert expected_grade_component_1.assessment_point.curriculum_item.curriculum_component.id ==
               cur_component.id

      assert expected_grade_component_2.id == grade_component_2.id
      assert expected_grade_component_2.assessment_point.id == ast_point_2.id
      assert expected_grade_component_2.assessment_point.strand.id == strand.id
      assert expected_grade_component_2.assessment_point.curriculum_item.id == ci_2.id

      assert expected_grade_component_2.assessment_point.curriculum_item.curriculum_component.id ==
               cur_component.id
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
      grades_report = grades_report_fixture(%{scale_id: grading_scale.id})

      grades_report_cycle =
        grades_report_cycle_fixture(%{
          school_cycle_id: cycle.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject =
        grades_report_subject_fixture(%{
          subject_id: subject.id,
          grades_report_id: grades_report.id
        })

      _grade_component_1 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject.id,
          assessment_point_id: goal_1.id,
          weight: 1.0
        })

      _grade_component_2 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject.id,
          assessment_point_id: goal_2.id,
          weight: 2.0
        })

      _grade_component_3 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject.id,
          assessment_point_id: goal_3.id,
          weight: 3.0
        })

      _grade_component_diff =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject.id,
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

      other_grades_report_cycle =
        grades_report_cycle_fixture(%{
          school_cycle_id: other_cycle.id,
          grades_report_id: grades_report.id
        })

      other_grades_report_subject =
        grades_report_subject_fixture(%{
          subject_id: other_subject.id,
          grades_report_id: grades_report.id
        })

      _other_grade_component =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: other_grades_report_cycle.id,
          grades_report_subject_id: other_grades_report_subject.id,
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
      grades_report = grades_report_fixture(%{scale_id: grading_scale.id})

      grades_report_cycle =
        grades_report_cycle_fixture(%{
          school_cycle_id: cycle.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject_1 =
        grades_report_subject_fixture(%{
          subject_id: subject_1.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject_2 =
        grades_report_subject_fixture(%{
          subject_id: subject_2.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject_3 =
        grades_report_subject_fixture(%{
          subject_id: subject_3.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject_4 =
        grades_report_subject_fixture(%{
          subject_id: subject_4.id,
          grades_report_id: grades_report.id
        })

      _grade_component_1_1 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_1.id,
          assessment_point_id: goal_1_1.id,
          weight: 1.0
        })

      _grade_component_1_2 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_1.id,
          assessment_point_id: goal_1_2.id,
          weight: 2.0
        })

      _grade_component_1_3 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_1.id,
          assessment_point_id: goal_1_3.id,
          weight: 3.0
        })

      _grade_component_2_1 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_2.id,
          assessment_point_id: goal_2_1.id,
          weight: 1.0
        })

      _grade_component_2_2 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_2.id,
          assessment_point_id: goal_2_2.id,
          weight: 2.0
        })

      _grade_component_2_3 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_2.id,
          assessment_point_id: goal_2_3.id,
          weight: 3.0
        })

      _grade_component_3_1 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_3.id,
          assessment_point_id: goal_3_1.id,
          weight: 1.0
        })

      _grade_component_3_2 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_3.id,
          assessment_point_id: goal_3_2.id,
          weight: 2.0
        })

      _grade_component_3_3 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_3.id,
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
      grades_report = grades_report_fixture(%{scale_id: grading_scale.id})

      grades_report_cycle =
        grades_report_cycle_fixture(%{
          school_cycle_id: cycle.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject =
        grades_report_subject_fixture(%{
          subject_id: subject.id,
          grades_report_id: grades_report.id
        })

      _grade_component_1 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject.id,
          assessment_point_id: goal_1.id,
          weight: 1.0
        })

      _grade_component_2 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject.id,
          assessment_point_id: goal_2.id,
          weight: 2.0
        })

      _grade_component_3 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject.id,
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
      grades_report = grades_report_fixture(%{scale_id: grading_scale.id})

      grades_report_cycle =
        grades_report_cycle_fixture(%{
          school_cycle_id: cycle.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject_1 =
        grades_report_subject_fixture(%{
          subject_id: subject_1.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject_2 =
        grades_report_subject_fixture(%{
          subject_id: subject_2.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject_3 =
        grades_report_subject_fixture(%{
          subject_id: subject_3.id,
          grades_report_id: grades_report.id
        })

      _grade_component_1_1 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_1.id,
          assessment_point_id: goal_1_1.id,
          weight: 1.0
        })

      _grade_component_1_2 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_1.id,
          assessment_point_id: goal_1_2.id,
          weight: 2.0
        })

      _grade_component_1_3 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_1.id,
          assessment_point_id: goal_1_3.id,
          weight: 3.0
        })

      _grade_component_2_1 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_2.id,
          assessment_point_id: goal_2_1.id,
          weight: 1.0
        })

      _grade_component_2_2 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_2.id,
          assessment_point_id: goal_2_2.id,
          weight: 2.0
        })

      _grade_component_2_3 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_2.id,
          assessment_point_id: goal_2_3.id,
          weight: 3.0
        })

      _grade_component_3_1 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_3.id,
          assessment_point_id: goal_3_1.id,
          weight: 1.0
        })

      _grade_component_3_2 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_3.id,
          assessment_point_id: goal_3_2.id,
          weight: 2.0
        })

      _grade_component_3_3 =
        GradingFixtures.grade_component_fixture(%{
          grades_report_id: grades_report.id,
          grades_report_cycle_id: grades_report_cycle.id,
          grades_report_subject_id: grades_report_subject_3.id,
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
      grades_report = grades_report_fixture(%{scale_id: scale.id})

      grades_report_cycle =
        grades_report_cycle_fixture(%{
          school_cycle_id: cycle.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject_1 =
        grades_report_subject_fixture(%{
          grades_report_id: grades_report.id
        })

      grades_report_subject_2 =
        grades_report_subject_fixture(%{
          grades_report_id: grades_report.id
        })

      grades_report_subject_3 =
        grades_report_subject_fixture(%{
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
      grades_report = grades_report_fixture(%{scale_id: scale.id})
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
        grades_report_cycle_fixture(%{
          school_cycle_id: cycle_1.id,
          grades_report_id: grades_report.id
        })

      grades_report_cycle_2 =
        grades_report_cycle_fixture(%{
          school_cycle_id: cycle_2.id,
          grades_report_id: grades_report.id
        })

      grades_report_cycle_3 =
        grades_report_cycle_fixture(%{
          school_cycle_id: cycle_3.id,
          grades_report_id: grades_report.id
        })

      grades_report_subject_1 =
        grades_report_subject_fixture(%{
          grades_report_id: grades_report.id
        })

      grades_report_subject_2 =
        grades_report_subject_fixture(%{
          grades_report_id: grades_report.id
        })

      grades_report_subject_3 =
        grades_report_subject_fixture(%{
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
