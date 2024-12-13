defmodule Lanttern.StudentsRecordsTest do
  use Lanttern.DataCase

  alias Lanttern.StudentsRecords

  describe "students_records" do
    alias Lanttern.StudentsRecords.StudentRecord
    alias Lanttern.StudentsRecordsLog.StudentRecordLog

    import Lanttern.StudentsRecordsFixtures
    alias Lanttern.SchoolsFixtures
    alias Lanttern.RepoHelpers.Page

    @invalid_attrs %{name: nil, date: nil, time: nil, description: nil}

    test "list_students_records/1 returns all students_records" do
      student_record = student_record_fixture()
      [expected_student_record] = StudentsRecords.list_students_records()
      assert expected_student_record.id == student_record.id
    end

    test "list_students_records/1 with school opt returns students_records filtered by the given school" do
      school = SchoolsFixtures.school_fixture()
      student_record = student_record_fixture(%{school_id: school.id})

      # extra fixture to test filtering
      student_record_fixture()

      [expected_student_record] = StudentsRecords.list_students_records(school_id: school.id)
      assert expected_student_record.id == student_record.id
    end

    test "list_students_records/1 with preloads opt returns all students_records with preloaded data" do
      school = SchoolsFixtures.school_fixture()
      type = student_record_type_fixture(%{school_id: school.id})
      student_record = student_record_fixture(%{type_id: type.id, school_id: school.id})

      [expected] = StudentsRecords.list_students_records(preloads: :type)
      assert expected.id == student_record.id
      assert expected.type.id == type.id
    end

    test "list_students_records/1 with students opt returns records filtered by students" do
      school = SchoolsFixtures.school_fixture()
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})

      student_record =
        student_record_fixture(%{school_id: school.id, students_ids: [student.id]})

      # extra fixture to test filtering
      student_record_fixture()
      student_record_fixture(%{school_id: school.id})

      [expected_student_record] =
        StudentsRecords.list_students_records(
          school_id: school.id,
          students_ids: [student.id]
        )

      assert expected_student_record.id == student_record.id
    end

    test "list_students_records/1 with types and statuses opts students_records filtered by given types and statuses" do
      school = SchoolsFixtures.school_fixture()
      type = student_record_type_fixture(%{school_id: school.id})
      status = student_record_status_fixture(%{school_id: school.id})

      student_record =
        student_record_fixture(%{school_id: school.id, type_id: type.id, status_id: status.id})

      # extra fixture to test filtering
      student_record_fixture()
      student_record_fixture(%{school_id: school.id, type_id: type.id})
      student_record_fixture(%{school_id: school.id, status_id: status.id})

      [expected_student_record] =
        StudentsRecords.list_students_records(
          school_id: school.id,
          types_ids: [type.id],
          statuses_ids: [status.id]
        )

      assert expected_student_record.id == student_record.id
    end

    test "list_students_records_page/1 returns all students_records in a Page struct" do
      student_record_1 = student_record_fixture(%{date: ~D[2024-01-01], time: nil})
      student_record_2_1 = student_record_fixture(%{date: ~D[2024-02-01], time: ~T[09:00:00]})
      student_record_2_2 = student_record_fixture(%{date: ~D[2024-02-01], time: ~T[10:00:00]})
      student_record_2_3 = student_record_fixture(%{date: ~D[2024-02-01], time: ~T[10:00:00]})

      %Page{results: [expected_student_record], keyset: keyset, has_next: true} =
        StudentsRecords.list_students_records_page(first: 1)

      assert expected_student_record.id == student_record_2_3.id

      %Page{results: [expected_student_record], keyset: keyset, has_next: true} =
        StudentsRecords.list_students_records_page(first: 1, after: keyset)

      assert expected_student_record.id == student_record_2_2.id

      %Page{results: [expected_student_record], keyset: keyset, has_next: true} =
        StudentsRecords.list_students_records_page(first: 1, after: keyset)

      assert expected_student_record.id == student_record_2_1.id

      %Page{results: [expected_student_record], has_next: false} =
        StudentsRecords.list_students_records_page(first: 1, after: keyset)

      assert expected_student_record.id == student_record_1.id
    end

    test "list_students_records_page/1 handles empty students_records correctly" do
      _student_record = student_record_fixture()
      type = student_record_type_fixture()

      %Page{results: [], has_next: false} =
        StudentsRecords.list_students_records_page(types_ids: [type.id])
    end

    test "get_student_record/1 returns the student_record with given id" do
      student_record = student_record_fixture()
      expected_student_record = StudentsRecords.get_student_record(student_record.id)
      assert expected_student_record.id == student_record.id
    end

    test "get_student_record!/1 returns the student_record with given id" do
      student_record = student_record_fixture()
      expected_student_record = StudentsRecords.get_student_record!(student_record.id)
      assert expected_student_record.id == student_record.id
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
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})
      class = SchoolsFixtures.class_fixture(%{school_id: school.id})

      # profile to test log
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      valid_attrs = %{
        school_id: school.id,
        status_id: status.id,
        type_id: type.id,
        name: "some name",
        date: ~D[2024-09-15],
        time: ~T[14:00:00],
        description: "some description",
        students_ids: [student.id],
        classes_ids: [class.id]
      }

      assert {:ok, %StudentRecord{} = student_record} =
               StudentsRecords.create_student_record(valid_attrs, log_profile_id: profile.id)

      assert student_record.school_id == school.id
      assert student_record.status_id == status.id
      assert student_record.type_id == type.id
      assert student_record.name == "some name"
      assert student_record.date == ~D[2024-09-15]
      assert student_record.time == ~T[14:00:00]
      assert student_record.description == "some description"

      student_record = student_record |> Repo.preload([:students, :classes])
      assert student_record.students == [student]
      assert student_record.classes == [class]

      on_exit(fn ->
        assert_supervised_tasks_are_down()

        student_record_log =
          Repo.get_by!(StudentRecordLog,
            student_record_id: student_record.id
          )

        assert student_record_log.student_record_id == student_record.id
        assert student_record_log.profile_id == profile.id
        assert student_record_log.operation == "CREATE"

        assert student_record_log.students_ids == [student.id]
        assert student_record_log.classes_ids == [class.id]
        assert student_record_log.school_id == student_record.school_id
        assert student_record_log.status_id == student_record.status_id
        assert student_record_log.type_id == student_record.type_id
        assert student_record_log.name == student_record.name
        assert student_record_log.date == student_record.date
        assert student_record_log.time == student_record.time
        assert student_record_log.description == student_record.description
      end)
    end

    test "create_student_record/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = StudentsRecords.create_student_record(@invalid_attrs)
    end

    test "update_student_record/2 with valid data updates the student_record" do
      school = SchoolsFixtures.school_fixture()
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})
      class = SchoolsFixtures.class_fixture(%{school_id: school.id})

      student_record =
        student_record_fixture(%{
          school_id: school.id,
          students_ids: [student.id],
          classes_ids: [class.id]
        })

      updated_student = SchoolsFixtures.student_fixture(%{school_id: school.id})
      updated_class = SchoolsFixtures.class_fixture(%{school_id: school.id})

      update_attrs = %{
        name: "some updated name",
        date: ~D[2024-09-16],
        time: ~T[15:01:01],
        description: "some updated description",
        students_ids: [updated_student.id],
        classes_ids: [updated_class.id]
      }

      # profile to test log
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      assert {:ok, %StudentRecord{} = student_record} =
               StudentsRecords.update_student_record(student_record, update_attrs,
                 log_profile_id: profile.id
               )

      assert student_record.name == "some updated name"
      assert student_record.date == ~D[2024-09-16]
      assert student_record.time == ~T[15:01:01]
      assert student_record.description == "some updated description"

      student_record = student_record |> Repo.preload([:students, :classes])
      assert student_record.students == [updated_student]
      assert student_record.classes == [updated_class]

      on_exit(fn ->
        assert_supervised_tasks_are_down()

        student_record_log =
          Repo.get_by!(StudentRecordLog,
            student_record_id: student_record.id
          )

        assert student_record_log.student_record_id == student_record.id
        assert student_record_log.profile_id == profile.id
        assert student_record_log.operation == "UPDATE"

        assert student_record_log.students_ids == [updated_student.id]
        assert student_record_log.classes_ids == [updated_class.id]
        assert student_record_log.school_id == student_record.school_id
        assert student_record_log.status_id == student_record.status_id
        assert student_record_log.type_id == student_record.type_id
        assert student_record_log.name == student_record.name
        assert student_record_log.date == student_record.date
        assert student_record_log.time == student_record.time
        assert student_record_log.description == student_record.description
      end)
    end

    test "update_student_record/2 with invalid data returns error changeset" do
      student_record = student_record_fixture()

      assert {:error, %Ecto.Changeset{}} =
               StudentsRecords.update_student_record(student_record, @invalid_attrs)

      expected_student_record = StudentsRecords.get_student_record!(student_record.id)
      assert expected_student_record.id == student_record.id
    end

    test "delete_student_record/1 deletes the student_record" do
      student_record = student_record_fixture()

      # profile to test log
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      assert {:ok, %StudentRecord{}} =
               StudentsRecords.delete_student_record(student_record, log_profile_id: profile.id)

      assert_raise Ecto.NoResultsError, fn ->
        StudentsRecords.get_student_record!(student_record.id)
      end

      on_exit(fn ->
        assert_supervised_tasks_are_down()

        student_record_log =
          Repo.get_by!(StudentRecordLog,
            student_record_id: student_record.id
          )

        assert student_record_log.student_record_id == student_record.id
        assert student_record_log.profile_id == profile.id
        assert student_record_log.operation == "DELETE"
      end)
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
