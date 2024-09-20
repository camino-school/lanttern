defmodule Lanttern.StudentsRecordsTest do
  use Lanttern.DataCase

  alias Lanttern.StudentsRecords

  describe "students_records" do
    alias Lanttern.StudentsRecords.StudentRecord

    import Lanttern.StudentsRecordsFixtures
    alias Lanttern.SchoolsFixtures

    @invalid_attrs %{name: nil, date: nil, time: nil, description: nil}

    test "list_students_records/1 returns all students_records" do
      student_record = student_record_fixture()
      assert StudentsRecords.list_students_records() == [student_record]
    end

    test "list_students_records/1 with school opt returns all students_records filtered by the given school" do
      school = SchoolsFixtures.school_fixture()
      student_record = student_record_fixture(%{school_id: school.id})

      # extra fixture to test filtering
      student_record_fixture()

      assert StudentsRecords.list_students_records(school_id: school.id) == [student_record]
    end

    test "list_students_records/1 with preloads opt returns all students_records with preloaded data" do
      school = SchoolsFixtures.school_fixture()
      type = student_record_type_fixture(%{school_id: school.id})
      student_record = student_record_fixture(%{type_id: type.id, school_id: school.id})

      [expected] = StudentsRecords.list_students_records(preloads: :type)
      assert expected.id == student_record.id
      assert expected.type.id == type.id
    end

    test "get_student_record/1 returns the student_record with given id" do
      student_record = student_record_fixture()
      assert StudentsRecords.get_student_record(student_record.id) == student_record
    end

    test "get_student_record!/1 returns the student_record with given id" do
      student_record = student_record_fixture()
      assert StudentsRecords.get_student_record!(student_record.id) == student_record
    end

    test "get_student_record/1 with preload opts returns the student_record with preloaded data" do
      school = SchoolsFixtures.school_fixture()
      type = student_record_type_fixture(%{school_id: school.id})
      student_record = student_record_fixture(%{type_id: type.id, school_id: school.id})

      expected = StudentsRecords.get_student_record(student_record.id, preloads: :type)
      assert expected.id == student_record.id
      assert expected.type.id == type.id
    end

    test "create_student_record/1 with valid data creates a student_record" do
      school = SchoolsFixtures.school_fixture()
      type = student_record_type_fixture(%{school_id: school.id})
      status = student_record_status_fixture(%{school_id: school.id})

      valid_attrs = %{
        school_id: school.id,
        status_id: status.id,
        type_id: type.id,
        name: "some name",
        date: ~D[2024-09-15],
        time: ~T[14:00:00],
        description: "some description"
      }

      assert {:ok, %StudentRecord{} = student_record} =
               StudentsRecords.create_student_record(valid_attrs)

      assert student_record.school_id == school.id
      assert student_record.status_id == status.id
      assert student_record.type_id == type.id
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

  describe "student_record_types" do
    alias Lanttern.StudentsRecords.StudentRecordType

    import Lanttern.StudentsRecordsFixtures
    alias Lanttern.SchoolsFixtures

    @invalid_attrs %{name: nil, bg_color: nil, text_color: nil}

    test "list_student_record_types/1 returns all student_record_types" do
      student_record_type = student_record_type_fixture()
      assert StudentsRecords.list_student_record_types() == [student_record_type]
    end

    test "list_student_record_types/1 with school_id opt returns all student_record_types filtered by given school" do
      school = SchoolsFixtures.school_fixture()
      student_record_type = student_record_type_fixture(%{school_id: school.id})

      # other fixture for filter testing
      student_record_type_fixture()

      assert StudentsRecords.list_student_record_types(school_id: school.id) == [
               student_record_type
             ]
    end

    test "get_student_record_type!/1 returns the student_record_type with given id" do
      student_record_type = student_record_type_fixture()

      assert StudentsRecords.get_student_record_type!(student_record_type.id) ==
               student_record_type
    end

    test "create_student_record_type/1 with valid data creates a student_record_type" do
      school = SchoolsFixtures.school_fixture()

      valid_attrs = %{
        school_id: school.id,
        name: "some name",
        bg_color: "#000000",
        text_color: "#ffffff"
      }

      assert {:ok, %StudentRecordType{} = student_record_type} =
               StudentsRecords.create_student_record_type(valid_attrs)

      assert student_record_type.school_id == school.id
      assert student_record_type.name == "some name"
      assert student_record_type.bg_color == "#000000"
      assert student_record_type.text_color == "#ffffff"
    end

    test "create_student_record_type/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               StudentsRecords.create_student_record_type(@invalid_attrs)
    end

    test "update_student_record_type/2 with valid data updates the student_record_type" do
      student_record_type = student_record_type_fixture()
      update_attrs = %{name: "some updated name", bg_color: "#ffffff", text_color: "#000000"}

      assert {:ok, %StudentRecordType{} = student_record_type} =
               StudentsRecords.update_student_record_type(student_record_type, update_attrs)

      assert student_record_type.name == "some updated name"
      assert student_record_type.bg_color == "#ffffff"
      assert student_record_type.text_color == "#000000"
    end

    test "update_student_record_type/2 with invalid data returns error changeset" do
      student_record_type = student_record_type_fixture()

      assert {:error, %Ecto.Changeset{}} =
               StudentsRecords.update_student_record_type(student_record_type, @invalid_attrs)

      assert student_record_type ==
               StudentsRecords.get_student_record_type!(student_record_type.id)
    end

    test "delete_student_record_type/1 deletes the student_record_type" do
      student_record_type = student_record_type_fixture()

      assert {:ok, %StudentRecordType{}} =
               StudentsRecords.delete_student_record_type(student_record_type)

      assert_raise Ecto.NoResultsError, fn ->
        StudentsRecords.get_student_record_type!(student_record_type.id)
      end
    end

    test "change_student_record_type/1 returns a student_record_type changeset" do
      student_record_type = student_record_type_fixture()
      assert %Ecto.Changeset{} = StudentsRecords.change_student_record_type(student_record_type)
    end
  end

  describe "student_record_statuses" do
    alias Lanttern.StudentsRecords.StudentRecordStatus

    import Lanttern.StudentsRecordsFixtures
    alias Lanttern.SchoolsFixtures

    @invalid_attrs %{name: nil, bg_color: nil, text_color: nil}

    test "list_student_record_statuses/1 returns all student_record_statuses" do
      student_record_status = student_record_status_fixture()
      assert StudentsRecords.list_student_record_statuses() == [student_record_status]
    end

    test "list_student_record_statuses/1 with school_id opt returns all student_record_types filtered by given school" do
      school = SchoolsFixtures.school_fixture()
      student_record_status = student_record_status_fixture(%{school_id: school.id})

      # other fixture for filter testing
      student_record_status_fixture()

      assert StudentsRecords.list_student_record_statuses(school_id: school.id) == [
               student_record_status
             ]
    end

    test "get_student_record_status!/1 returns the student_record_status with given id" do
      student_record_status = student_record_status_fixture()

      assert StudentsRecords.get_student_record_status!(student_record_status.id) ==
               student_record_status
    end

    test "create_student_record_status/1 with valid data creates a student_record_status" do
      school = SchoolsFixtures.school_fixture()

      valid_attrs = %{
        school_id: school.id,
        name: "some name",
        bg_color: "#000000",
        text_color: "#ffffff"
      }

      assert {:ok, %StudentRecordStatus{} = student_record_status} =
               StudentsRecords.create_student_record_status(valid_attrs)

      assert student_record_status.school_id == school.id
      assert student_record_status.name == "some name"
      assert student_record_status.bg_color == "#000000"
      assert student_record_status.text_color == "#ffffff"
    end

    test "create_student_record_status/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               StudentsRecords.create_student_record_status(@invalid_attrs)
    end

    test "update_student_record_status/2 with valid data updates the student_record_status" do
      student_record_status = student_record_status_fixture()

      update_attrs = %{
        name: "some updated name",
        bg_color: "#ffffff",
        text_color: "#000000"
      }

      assert {:ok, %StudentRecordStatus{} = student_record_status} =
               StudentsRecords.update_student_record_status(student_record_status, update_attrs)

      assert student_record_status.name == "some updated name"
      assert student_record_status.bg_color == "#ffffff"
      assert student_record_status.text_color == "#000000"
    end

    test "update_student_record_status/2 with invalid data returns error changeset" do
      student_record_status = student_record_status_fixture()

      assert {:error, %Ecto.Changeset{}} =
               StudentsRecords.update_student_record_status(student_record_status, @invalid_attrs)

      assert student_record_status ==
               StudentsRecords.get_student_record_status!(student_record_status.id)
    end

    test "delete_student_record_status/1 deletes the student_record_status" do
      student_record_status = student_record_status_fixture()

      assert {:ok, %StudentRecordStatus{}} =
               StudentsRecords.delete_student_record_status(student_record_status)

      assert_raise Ecto.NoResultsError, fn ->
        StudentsRecords.get_student_record_status!(student_record_status.id)
      end
    end

    test "change_student_record_status/1 returns a student_record_status changeset" do
      student_record_status = student_record_status_fixture()

      assert %Ecto.Changeset{} =
               StudentsRecords.change_student_record_status(student_record_status)
    end
  end
end
