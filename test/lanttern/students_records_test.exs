defmodule Lanttern.StudentsRecordsTest do
  use Lanttern.DataCase

  alias Lanttern.StudentsRecords

  describe "students_records" do
    alias Lanttern.StudentsRecords.StudentRecord
    alias Lanttern.StudentsRecordsLog.StudentRecordLog

    import Lanttern.StudentsRecordsFixtures
    alias Lanttern.SchoolsFixtures
    alias Lanttern.RepoHelpers.Page
    alias Lanttern.Identity.Profile

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

      # create 2 students to test duplicated results when more than one filter applied
      student_a = SchoolsFixtures.student_fixture(%{school_id: school.id})
      student_b = SchoolsFixtures.student_fixture(%{school_id: school.id})

      student_record =
        student_record_fixture(%{
          school_id: school.id,
          students_ids: [student_a.id, student_b.id]
        })

      # extra fixture to test filtering
      student_record_fixture()
      student_record_fixture(%{school_id: school.id})

      [expected_student_record] =
        StudentsRecords.list_students_records(
          school_id: school.id,
          students_ids: [student_a.id, student_b.id]
        )

      assert expected_student_record.id == student_record.id
    end

    test "list_students_records/1 with classes opt returns records filtered by classes" do
      school = SchoolsFixtures.school_fixture()

      # create 2 classes to test duplicated results when more than one filter applied
      class_a = SchoolsFixtures.class_fixture(%{school_id: school.id})
      class_b = SchoolsFixtures.class_fixture(%{school_id: school.id})

      student_record =
        student_record_fixture(%{school_id: school.id, classes_ids: [class_a.id, class_b.id]})

      # extra fixture to test filtering
      student_record_fixture()
      student_record_fixture(%{school_id: school.id})

      [expected_student_record] =
        StudentsRecords.list_students_records(
          school_id: school.id,
          classes_ids: [class_a.id, class_b.id]
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

    test "list_students_records/1 with owner and assignees opts students_records filtered by given owner and assignees" do
      school = SchoolsFixtures.school_fixture()
      owner = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})
      assignee = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})

      student_record =
        student_record_fixture(%{
          school_id: school.id,
          created_by_staff_member_id: owner.id,
          assignees_ids: [assignee.id]
        })

      # extra fixture to test filtering
      student_record_fixture()
      student_record_fixture(%{school_id: school.id, created_by_staff_member_id: assignee.id})
      student_record_fixture(%{school_id: school.id, assignees_ids: [owner.id]})
      student_record_fixture(%{school_id: school.id})

      [expected_student_record] =
        StudentsRecords.list_students_records(
          school_id: school.id,
          owner_id: owner.id,
          assignees_ids: [assignee.id]
        )

      assert expected_student_record.id == student_record.id
    end

    test "list_students_records/1 with check_profile_permissions filters results correctly" do
      school = SchoolsFixtures.school_fixture()
      owner = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})
      assignee = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})

      open_student_record =
        student_record_fixture(%{
          school_id: school.id,
          shared_with_school: true,
          date: ~D[2025-12-01]
        })

      closed_student_record =
        student_record_fixture(%{
          school_id: school.id,
          date: ~D[2025-11-01]
        })

      owner_and_assignee_student_record =
        student_record_fixture(%{
          school_id: school.id,
          created_by_staff_member_id: owner.id,
          assignees_ids: [assignee.id],
          date: ~D[2025-10-01]
        })

      # extra fixture to test filtering
      student_record_fixture()

      # test student profile
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})

      profile = %Profile{
        permissions: [],
        student: student
      }

      assert StudentsRecords.list_students_records(check_profile_permissions: profile) == []

      # test profile from other school
      staff_member = SchoolsFixtures.staff_member_fixture()

      profile = %Profile{
        permissions: [],
        staff_member: staff_member
      }

      assert StudentsRecords.list_students_records(check_profile_permissions: profile) == []

      # test profile with full access from other school
      staff_member = SchoolsFixtures.staff_member_fixture()

      profile = %Profile{
        permissions: ["students_records_full_access"],
        staff_member: staff_member
      }

      assert StudentsRecords.list_students_records(check_profile_permissions: profile) == []

      # test school profile without permissions
      staff_member = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})

      profile = %Profile{
        permissions: [],
        staff_member: staff_member
      }

      [expected] = StudentsRecords.list_students_records(check_profile_permissions: profile)
      assert expected.id == open_student_record.id

      # test school profile with full access
      staff_member = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})

      profile = %Profile{
        permissions: ["students_records_full_access"],
        staff_member: staff_member
      }

      [expected_1, expected_2, expected_3] =
        StudentsRecords.list_students_records(check_profile_permissions: profile)

      assert expected_1.id == open_student_record.id
      assert expected_2.id == closed_student_record.id
      assert expected_3.id == owner_and_assignee_student_record.id

      # test owner without permissions
      profile = %Profile{
        permissions: [],
        staff_member: owner
      }

      [expected_1, expected_2] =
        StudentsRecords.list_students_records(check_profile_permissions: profile)

      assert expected_1.id == open_student_record.id
      assert expected_2.id == owner_and_assignee_student_record.id

      # test assignee without permissions
      profile = %Profile{
        permissions: [],
        staff_member: assignee
      }

      [expected_1, expected_2] =
        StudentsRecords.list_students_records(check_profile_permissions: profile)

      assert expected_1.id == open_student_record.id
      assert expected_2.id == owner_and_assignee_student_record.id
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

    test "get_student_record/2 returns the student_record with given id" do
      student_record = student_record_fixture()
      expected_student_record = StudentsRecords.get_student_record(student_record.id)
      assert expected_student_record.id == student_record.id
    end

    test "get_student_record!/2 returns the student_record with given id" do
      student_record = student_record_fixture()
      expected_student_record = StudentsRecords.get_student_record!(student_record.id)
      assert expected_student_record.id == student_record.id
    end

    test "get_student_record/2 with preload opts returns the student_record with preloaded data" do
      school = SchoolsFixtures.school_fixture()
      type = student_record_type_fixture(%{school_id: school.id})
      student_record = student_record_fixture(%{type_id: type.id, school_id: school.id})

      expected = StudentsRecords.get_student_record(student_record.id, preloads: :type)
      assert expected.id == student_record.id
      assert expected.type.id == type.id
    end

    test "get_student_record/2 with check_profile_permissions filters results correctly" do
      school = SchoolsFixtures.school_fixture()
      owner = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})
      assignee = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})

      open_student_record =
        student_record_fixture(%{
          school_id: school.id,
          shared_with_school: true
        })

      closed_student_record =
        student_record_fixture(%{
          school_id: school.id
        })

      owner_and_assignee_student_record =
        student_record_fixture(%{
          school_id: school.id,
          created_by_staff_member_id: owner.id,
          assignees_ids: [assignee.id]
        })

      # test student profile
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})

      profile = %Profile{
        permissions: [],
        student: student
      }

      assert StudentsRecords.get_student_record(open_student_record.id,
               check_profile_permissions: profile
             ) == nil

      assert StudentsRecords.get_student_record(closed_student_record.id,
               check_profile_permissions: profile
             ) == nil

      assert StudentsRecords.get_student_record(owner_and_assignee_student_record.id,
               check_profile_permissions: profile
             ) == nil

      # test profile from other school
      staff_member = SchoolsFixtures.staff_member_fixture()

      profile = %Profile{
        permissions: [],
        staff_member: staff_member
      }

      assert StudentsRecords.get_student_record(open_student_record.id,
               check_profile_permissions: profile
             ) == nil

      assert StudentsRecords.get_student_record(closed_student_record.id,
               check_profile_permissions: profile
             ) == nil

      assert StudentsRecords.get_student_record(owner_and_assignee_student_record.id,
               check_profile_permissions: profile
             ) == nil

      # test profile with full access from other school
      staff_member = SchoolsFixtures.staff_member_fixture()

      profile = %Profile{
        permissions: ["students_records_full_access"],
        staff_member: staff_member
      }

      assert StudentsRecords.get_student_record(open_student_record.id,
               check_profile_permissions: profile
             ) == nil

      assert StudentsRecords.get_student_record(closed_student_record.id,
               check_profile_permissions: profile
             ) == nil

      assert StudentsRecords.get_student_record(owner_and_assignee_student_record.id,
               check_profile_permissions: profile
             ) == nil

      # test school profile without permissions
      staff_member = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})

      profile = %Profile{
        permissions: [],
        staff_member: staff_member
      }

      assert %StudentRecord{} =
               StudentsRecords.get_student_record(open_student_record.id,
                 check_profile_permissions: profile
               )

      assert StudentsRecords.get_student_record(closed_student_record.id,
               check_profile_permissions: profile
             ) == nil

      assert StudentsRecords.get_student_record(owner_and_assignee_student_record.id,
               check_profile_permissions: profile
             ) == nil

      # test school profile with full access
      staff_member = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})

      profile = %Profile{
        permissions: ["students_records_full_access"],
        staff_member: staff_member
      }

      assert %StudentRecord{} =
               StudentsRecords.get_student_record(open_student_record.id,
                 check_profile_permissions: profile
               )

      assert %StudentRecord{} =
               StudentsRecords.get_student_record(closed_student_record.id,
                 check_profile_permissions: profile
               )

      assert %StudentRecord{} =
               StudentsRecords.get_student_record(owner_and_assignee_student_record.id,
                 check_profile_permissions: profile
               )

      # test owner without permissions
      profile = %Profile{
        permissions: [],
        staff_member: owner
      }

      assert %StudentRecord{} =
               StudentsRecords.get_student_record(open_student_record.id,
                 check_profile_permissions: profile
               )

      assert StudentsRecords.get_student_record(closed_student_record.id,
               check_profile_permissions: profile
             ) == nil

      assert %StudentRecord{} =
               StudentsRecords.get_student_record(owner_and_assignee_student_record.id,
                 check_profile_permissions: profile
               )

      # test assignee without permissions
      profile = %Profile{
        permissions: [],
        staff_member: assignee
      }

      assert %StudentRecord{} =
               StudentsRecords.get_student_record(open_student_record.id,
                 check_profile_permissions: profile
               )

      assert StudentsRecords.get_student_record(closed_student_record.id,
               check_profile_permissions: profile
             ) == nil

      assert %StudentRecord{} =
               StudentsRecords.get_student_record(owner_and_assignee_student_record.id,
                 check_profile_permissions: profile
               )
    end

    test "create_student_record/1 with valid data creates a student_record" do
      school = SchoolsFixtures.school_fixture()
      type = student_record_type_fixture(%{school_id: school.id})
      status = student_record_status_fixture(%{school_id: school.id})
      staff_member = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})
      class = SchoolsFixtures.class_fixture(%{school_id: school.id})
      assignee = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})

      # profile to test log
      profile = Lanttern.IdentityFixtures.staff_member_profile_fixture()

      valid_attrs = %{
        school_id: school.id,
        status_id: status.id,
        type_id: type.id,
        name: "some name",
        date: ~D[2024-09-15],
        time: ~T[14:00:00],
        description: "some description",
        created_by_staff_member_id: staff_member.id,
        students_ids: [student.id],
        classes_ids: [class.id],
        assignees_ids: [assignee.id]
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

      student_record =
        student_record
        |> Repo.preload([:created_by_staff_member, :students, :classes, :assignees])

      assert student_record.created_by_staff_member == staff_member
      assert student_record.students == [student]
      assert student_record.classes == [class]
      assert student_record.assignees == [assignee]

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
        assert student_record_log.assignees_ids == [assignee.id]

        assert student_record_log.created_by_staff_member_id ==
                 student_record.created_by_staff_member_id
      end)
    end

    test "create_student_record/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = StudentsRecords.create_student_record(@invalid_attrs)
    end

    test "update_student_record/2 with valid data updates the student_record" do
      school = SchoolsFixtures.school_fixture()
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})
      class = SchoolsFixtures.class_fixture(%{school_id: school.id})
      assignee = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})

      student_record =
        student_record_fixture(%{
          school_id: school.id,
          students_ids: [student.id],
          classes_ids: [class.id],
          assignees_ids: [assignee.id]
        })

      updated_student = SchoolsFixtures.student_fixture(%{school_id: school.id})
      updated_class = SchoolsFixtures.class_fixture(%{school_id: school.id})
      updated_assignee = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})

      update_attrs = %{
        name: "some updated name",
        date: ~D[2024-09-16],
        time: ~T[15:01:01],
        description: "some updated description",
        students_ids: [updated_student.id],
        classes_ids: [updated_class.id],
        assignees_ids: [updated_assignee.id]
      }

      # profile to test log
      profile = Lanttern.IdentityFixtures.staff_member_profile_fixture()

      assert {:ok, %StudentRecord{} = student_record} =
               StudentsRecords.update_student_record(student_record, update_attrs,
                 log_profile_id: profile.id
               )

      assert student_record.name == "some updated name"
      assert student_record.date == ~D[2024-09-16]
      assert student_record.time == ~T[15:01:01]
      assert student_record.description == "some updated description"

      student_record = student_record |> Repo.preload([:students, :classes, :assignees])
      assert student_record.students == [updated_student]
      assert student_record.classes == [updated_class]
      assert student_record.assignees == [updated_assignee]

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
        assert student_record_log.assignees_ids == [updated_assignee.id]
        assert student_record_log.school_id == student_record.school_id
        assert student_record_log.status_id == student_record.status_id
        assert student_record_log.type_id == student_record.type_id
        assert student_record_log.name == student_record.name
        assert student_record_log.date == student_record.date
        assert student_record_log.time == student_record.time
        assert student_record_log.description == student_record.description

        assert student_record_log.created_by_staff_member_id ==
                 student_record.created_by_staff_member_id
      end)
    end

    test "user without permissions can't update_student_record/3 with check_profile_permissions" do
      school = SchoolsFixtures.school_fixture()
      staff_member = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})

      student_record =
        student_record_fixture(%{school_id: school.id}) |> Repo.preload([:assignees])

      update_attrs = %{name: "some updated name"}

      profile = %Profile{
        permissions: [],
        staff_member: staff_member
      }

      assert {:error, %Ecto.Changeset{}} =
               StudentsRecords.update_student_record(student_record, update_attrs,
                 check_profile_permissions: profile
               )
    end

    test "student record owner can update_student_record/3 with check_profile_permissions" do
      school = SchoolsFixtures.school_fixture()
      staff_member = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})

      student_record =
        student_record_fixture(%{
          school_id: school.id,
          created_by_staff_member_id: staff_member.id
        })
        |> Repo.preload([:assignees])

      update_attrs = %{name: "some updated name"}

      profile = %Profile{
        permissions: [],
        staff_member: staff_member
      }

      assert {:ok, %StudentRecord{} = student_record} =
               StudentsRecords.update_student_record(student_record, update_attrs,
                 check_profile_permissions: profile
               )

      assert student_record.name == "some updated name"
    end

    test "student record assignee can update_student_record/3 with check_profile_permissions" do
      school = SchoolsFixtures.school_fixture()
      staff_member = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})

      student_record =
        student_record_fixture(%{
          school_id: school.id,
          assignees_ids: [staff_member.id]
        })
        |> Repo.preload([:assignees])

      update_attrs = %{name: "some updated name"}

      profile = %Profile{
        permissions: [],
        staff_member: staff_member
      }

      assert {:ok, %StudentRecord{} = student_record} =
               StudentsRecords.update_student_record(student_record, update_attrs,
                 check_profile_permissions: profile
               )

      assert student_record.name == "some updated name"
    end

    test "user with full access can update_student_record/3 with check_profile_permissions" do
      school = SchoolsFixtures.school_fixture()
      staff_member = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})

      student_record =
        student_record_fixture(%{school_id: school.id})
        |> Repo.preload([:assignees])

      update_attrs = %{name: "some updated name"}

      profile = %Profile{
        permissions: ["students_records_full_access"],
        staff_member: staff_member
      }

      assert {:ok, %StudentRecord{} = student_record} =
               StudentsRecords.update_student_record(student_record, update_attrs,
                 check_profile_permissions: profile
               )

      assert student_record.name == "some updated name"
    end

    test "user from other schools with full access can't update_student_record/3 with check_profile_permissions" do
      school = SchoolsFixtures.school_fixture()
      staff_member = SchoolsFixtures.staff_member_fixture()

      student_record =
        student_record_fixture(%{school_id: school.id})
        |> Repo.preload([:assignees])

      update_attrs = %{name: "some updated name"}

      profile = %Profile{
        permissions: ["students_records_full_access"],
        staff_member: staff_member
      }

      assert {:error, %Ecto.Changeset{}} =
               StudentsRecords.update_student_record(student_record, update_attrs,
                 check_profile_permissions: profile
               )
    end

    test "update_student_record/2 with invalid data returns error changeset" do
      student_record = student_record_fixture()

      assert {:error, %Ecto.Changeset{}} =
               StudentsRecords.update_student_record(student_record, @invalid_attrs)

      expected_student_record = StudentsRecords.get_student_record!(student_record.id)
      assert expected_student_record.id == student_record.id
    end

    test "delete_student_record/2 deletes the student_record" do
      student_record = student_record_fixture()

      # profile to test log
      profile = Lanttern.IdentityFixtures.staff_member_profile_fixture()

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

    test "user without full access can't delete_student_record/2 with check_profile_permissions" do
      school = SchoolsFixtures.school_fixture()
      staff_member = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})
      student_record = student_record_fixture(%{school_id: school.id})

      profile = %Profile{
        permissions: [],
        staff_member: staff_member
      }

      assert {:error, %Ecto.Changeset{}} =
               StudentsRecords.delete_student_record(student_record,
                 check_profile_permissions: profile
               )
    end

    test "student record owner can delete_student_record/2 with check_profile_permissions" do
      school = SchoolsFixtures.school_fixture()
      staff_member = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})

      student_record =
        student_record_fixture(%{
          school_id: school.id,
          created_by_staff_member_id: staff_member.id
        })

      profile = %Profile{
        permissions: [],
        staff_member: staff_member
      }

      assert {:ok, %StudentRecord{}} =
               StudentsRecords.delete_student_record(student_record,
                 check_profile_permissions: profile
               )
    end

    test "student record assignee can't delete_student_record/2 with check_profile_permissions" do
      school = SchoolsFixtures.school_fixture()
      staff_member = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})

      student_record =
        student_record_fixture(%{
          school_id: school.id,
          assignees_ids: [staff_member.id]
        })

      profile = %Profile{
        permissions: [],
        staff_member: staff_member
      }

      assert {:error, %Ecto.Changeset{}} =
               StudentsRecords.delete_student_record(student_record,
                 check_profile_permissions: profile
               )
    end

    test "user with full access can delete_student_record/2 with check_profile_permissions" do
      school = SchoolsFixtures.school_fixture()
      staff_member = SchoolsFixtures.staff_member_fixture(%{school_id: school.id})

      student_record =
        student_record_fixture(%{school_id: school.id})

      profile = %Profile{
        permissions: ["students_records_full_access"],
        staff_member: staff_member
      }

      assert {:ok, %StudentRecord{}} =
               StudentsRecords.delete_student_record(student_record,
                 check_profile_permissions: profile
               )
    end

    test "user from other schools with full access can't delete_student_record/2 with check_profile_permissions" do
      school = SchoolsFixtures.school_fixture()
      staff_member = SchoolsFixtures.staff_member_fixture()

      student_record =
        student_record_fixture(%{school_id: school.id})

      profile = %Profile{
        permissions: ["students_records_full_access"],
        staff_member: staff_member
      }

      assert {:error, %Ecto.Changeset{}} =
               StudentsRecords.delete_student_record(student_record,
                 check_profile_permissions: profile
               )
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
