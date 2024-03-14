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
end
