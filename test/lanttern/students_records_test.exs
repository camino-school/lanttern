defmodule Lanttern.StudentsRecordsTest do
  use Lanttern.DataCase

  alias Lanttern.StudentsRecords

  describe "students_records" do
    alias Lanttern.StudentsRecords.StudentRecord

    import Lanttern.StudentsRecordsFixtures
    alias Lanttern.SchoolsFixtures

    @invalid_attrs %{name: nil, date: nil, time: nil, description: nil}

    test "list_students_records/0 returns all students_records" do
      student_record = student_record_fixture()
      assert StudentsRecords.list_students_records() == [student_record]
    end

    test "get_student_record!/1 returns the student_record with given id" do
      student_record = student_record_fixture()
      assert StudentsRecords.get_student_record!(student_record.id) == student_record
    end

    test "create_student_record/1 with valid data creates a student_record" do
      school = SchoolsFixtures.school_fixture()

      valid_attrs = %{
        school_id: school.id,
        name: "some name",
        date: ~D[2024-09-15],
        time: ~T[14:00:00],
        description: "some description"
      }

      assert {:ok, %StudentRecord{} = student_record} =
               StudentsRecords.create_student_record(valid_attrs)

      assert student_record.school_id == school.id
      assert student_record.name == "some name"
      assert student_record.date == ~D[2024-09-15]
      assert student_record.time == ~T[14:00:00]
      assert student_record.description == "some description"
    end

    test "create_student_record/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = StudentsRecords.create_student_record(@invalid_attrs)
    end

    test "update_student_record/2 with valid data updates the student_record" do
      student_record = student_record_fixture()

      update_attrs = %{
        name: "some updated name",
        date: ~D[2024-09-16],
        time: ~T[15:01:01],
        description: "some updated description"
      }

      assert {:ok, %StudentRecord{} = student_record} =
               StudentsRecords.update_student_record(student_record, update_attrs)

      assert student_record.name == "some updated name"
      assert student_record.date == ~D[2024-09-16]
      assert student_record.time == ~T[15:01:01]
      assert student_record.description == "some updated description"
    end

    test "update_student_record/2 with invalid data returns error changeset" do
      student_record = student_record_fixture()

      assert {:error, %Ecto.Changeset{}} =
               StudentsRecords.update_student_record(student_record, @invalid_attrs)

      assert student_record == StudentsRecords.get_student_record!(student_record.id)
    end

    test "delete_student_record/1 deletes the student_record" do
      student_record = student_record_fixture()
      assert {:ok, %StudentRecord{}} = StudentsRecords.delete_student_record(student_record)

      assert_raise Ecto.NoResultsError, fn ->
        StudentsRecords.get_student_record!(student_record.id)
      end
    end

    test "change_student_record/1 returns a student_record changeset" do
      student_record = student_record_fixture()
      assert %Ecto.Changeset{} = StudentsRecords.change_student_record(student_record)
    end
  end
end
