defmodule Lanttern.StudentsCycleInfoTest do
  use Lanttern.DataCase

  alias Lanttern.StudentsCycleInfo

  describe "students_cycle_info" do
    alias Lanttern.StudentsCycleInfo.StudentCycleInfo
    alias Lanttern.StudentsCycleInfoLog.StudentCycleInfoLog

    import Lanttern.StudentsCycleInfoFixtures
    alias Lanttern.SchoolsFixtures
    alias Lanttern.IdentityFixtures

    @invalid_attrs %{school_info: nil, shared_info: nil, profile_picture_url: nil}

    test "list_students_cycle_info/0 returns all students_cycle_info" do
      student_cycle_info = student_cycle_info_fixture()
      assert StudentsCycleInfo.list_students_cycle_info() == [student_cycle_info]
    end

    test "get_student_cycle_info!/1 returns the student_cycle_info with given id" do
      student_cycle_info = student_cycle_info_fixture()

      assert StudentsCycleInfo.get_student_cycle_info!(student_cycle_info.id) ==
               student_cycle_info
    end

    test "get_student_cycle_info_by_student_and_cycle/2 returns the student_cycle_info for given student and cycle" do
      school = SchoolsFixtures.school_fixture()
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})
      cycle = SchoolsFixtures.cycle_fixture(%{school_id: school.id})

      student_cycle_info =
        student_cycle_info_fixture(%{
          school_id: school.id,
          student_id: student.id,
          cycle_id: cycle.id
        })

      assert StudentsCycleInfo.get_student_cycle_info_by_student_and_cycle(student.id, cycle.id) ==
               student_cycle_info
    end

    test "get_student_cycle_info_by_student_and_cycle/3 with check_attachments_for school opt set has_attachments field as expected" do
      school = SchoolsFixtures.school_fixture()
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})
      cycle = SchoolsFixtures.cycle_fixture(%{school_id: school.id})

      student_cycle_info =
        student_cycle_info_fixture(%{
          school_id: school.id,
          student_id: student.id,
          cycle_id: cycle.id
        })

      profile = IdentityFixtures.teacher_profile_fixture()

      {:ok, _attachment} =
        StudentsCycleInfo.create_student_cycle_info_attachment(
          profile.id,
          student_cycle_info.id,
          %{"name" => "attachment", "link" => "https://somevaliduri.com", "is_external" => true},
          false
        )

      expected =
        StudentsCycleInfo.get_student_cycle_info_by_student_and_cycle(student.id, cycle.id,
          check_attachments_for: :school
        )

      assert expected.id == student_cycle_info.id
      assert expected.has_attachments
    end

    test "get_student_cycle_info_by_student_and_cycle/3 with check_attachments_for family opt set has_attachments field as expected" do
      school = SchoolsFixtures.school_fixture()
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})
      cycle = SchoolsFixtures.cycle_fixture(%{school_id: school.id})

      student_cycle_info =
        student_cycle_info_fixture(%{
          school_id: school.id,
          student_id: student.id,
          cycle_id: cycle.id
        })

      profile = IdentityFixtures.teacher_profile_fixture()

      {:ok, _attachment} =
        StudentsCycleInfo.create_student_cycle_info_attachment(
          profile.id,
          student_cycle_info.id,
          %{"name" => "attachment", "link" => "https://somevaliduri.com", "is_external" => true},
          true
        )

      expected =
        StudentsCycleInfo.get_student_cycle_info_by_student_and_cycle(student.id, cycle.id,
          check_attachments_for: :student
        )

      assert expected.id == student_cycle_info.id
      assert expected.has_attachments
    end

    test "create_student_cycle_info/1 with valid data creates a student_cycle_info" do
      school = SchoolsFixtures.school_fixture()
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})
      cycle = SchoolsFixtures.cycle_fixture(%{school_id: school.id})

      # profile to test log
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      valid_attrs = %{
        school_info: "some school_info",
        shared_info: "some shared_info",
        profile_picture_url: "some profile_picture",
        school_id: school.id,
        student_id: student.id,
        cycle_id: cycle.id
      }

      assert {:ok, %StudentCycleInfo{} = student_cycle_info} =
               StudentsCycleInfo.create_student_cycle_info(valid_attrs,
                 log_profile_id: profile.id
               )

      assert student_cycle_info.school_info == "some school_info"
      assert student_cycle_info.shared_info == "some shared_info"
      assert student_cycle_info.profile_picture_url == "some profile_picture"
      assert student_cycle_info.school_id == school.id
      assert student_cycle_info.student_id == student.id
      assert student_cycle_info.cycle_id == cycle.id

      on_exit(fn ->
        assert_supervised_tasks_are_down()

        student_cycle_info_log =
          Repo.get_by!(StudentCycleInfoLog,
            student_cycle_info_id: student_cycle_info.id
          )

        assert student_cycle_info_log.student_cycle_info_id == student_cycle_info.id
        assert student_cycle_info_log.profile_id == profile.id
        assert student_cycle_info_log.operation == "CREATE"

        assert student_cycle_info_log.school_info == student_cycle_info.school_info
        assert student_cycle_info_log.shared_info == student_cycle_info.shared_info

        assert student_cycle_info_log.profile_picture_url ==
                 student_cycle_info.profile_picture_url

        assert student_cycle_info_log.school_id == student_cycle_info.school_id
        assert student_cycle_info_log.student_id == student_cycle_info.student_id
        assert student_cycle_info_log.cycle_id == student_cycle_info.cycle_id
      end)
    end

    test "create_student_cycle_info/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               StudentsCycleInfo.create_student_cycle_info(@invalid_attrs)
    end

    test "update_student_cycle_info/2 with valid data updates the student_cycle_info" do
      student_cycle_info = student_cycle_info_fixture()

      # profile to test log
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      update_attrs = %{
        school_info: "some updated school_info",
        shared_info: "some updated shared_info",
        profile_picture_url: "some updated profile_picture"
      }

      assert {:ok, %StudentCycleInfo{} = student_cycle_info} =
               StudentsCycleInfo.update_student_cycle_info(student_cycle_info, update_attrs,
                 log_profile_id: profile.id
               )

      assert student_cycle_info.school_info == "some updated school_info"
      assert student_cycle_info.shared_info == "some updated shared_info"
      assert student_cycle_info.profile_picture_url == "some updated profile_picture"

      on_exit(fn ->
        assert_supervised_tasks_are_down()

        student_cycle_info_log =
          Repo.get_by!(StudentCycleInfoLog,
            student_cycle_info_id: student_cycle_info.id
          )

        assert student_cycle_info_log.student_cycle_info_id == student_cycle_info.id
        assert student_cycle_info_log.profile_id == profile.id
        assert student_cycle_info_log.operation == "UPDATE"

        assert student_cycle_info_log.school_info == student_cycle_info.school_info
        assert student_cycle_info_log.shared_info == student_cycle_info.shared_info

        assert student_cycle_info_log.profile_picture_url ==
                 student_cycle_info.profile_picture_url

        assert student_cycle_info_log.school_id == student_cycle_info.school_id
        assert student_cycle_info_log.student_id == student_cycle_info.student_id
        assert student_cycle_info_log.cycle_id == student_cycle_info.cycle_id
      end)
    end

    test "update_student_cycle_info/2 with invalid data returns error changeset" do
      student_cycle_info = student_cycle_info_fixture()
      invalid_student = SchoolsFixtures.student_fixture()
      invalid_cycle = SchoolsFixtures.cycle_fixture()

      assert {:error, %Ecto.Changeset{}} =
               StudentsCycleInfo.update_student_cycle_info(student_cycle_info, %{
                 student_id: invalid_student.id,
                 cycle_id: invalid_cycle.id
               })

      assert student_cycle_info ==
               StudentsCycleInfo.get_student_cycle_info!(student_cycle_info.id)
    end

    test "delete_student_cycle_info/1 deletes the student_cycle_info" do
      student_cycle_info = student_cycle_info_fixture()

      # profile to test log
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      assert {:ok, %StudentCycleInfo{}} =
               StudentsCycleInfo.delete_student_cycle_info(student_cycle_info,
                 log_profile_id: profile.id
               )

      assert_raise Ecto.NoResultsError, fn ->
        StudentsCycleInfo.get_student_cycle_info!(student_cycle_info.id)
      end

      on_exit(fn ->
        assert_supervised_tasks_are_down()

        student_cycle_info_log =
          Repo.get_by!(StudentCycleInfoLog,
            student_cycle_info_id: student_cycle_info.id
          )

        assert student_cycle_info_log.student_cycle_info_id == student_cycle_info.id
        assert student_cycle_info_log.profile_id == profile.id
        assert student_cycle_info_log.operation == "DELETE"
      end)
    end

    test "change_student_cycle_info/1 returns a student_cycle_info changeset" do
      student_cycle_info = student_cycle_info_fixture()
      assert %Ecto.Changeset{} = StudentsCycleInfo.change_student_cycle_info(student_cycle_info)
    end
  end

  describe "list_cycles_and_classes_for_student" do
    alias Lanttern.SchoolsFixtures

    test "list_cycles_and_classes_for_student/1 returns a list of cycles and classes related to given student" do
      school = SchoolsFixtures.school_fixture()

      cycle_2023 =
        SchoolsFixtures.cycle_fixture(%{
          school_id: school.id,
          start_at: ~D[2023-01-01],
          end_at: ~D[2023-12-31]
        })

      cycle_2024 =
        SchoolsFixtures.cycle_fixture(%{
          school_id: school.id,
          start_at: ~D[2024-01-01],
          end_at: ~D[2024-12-31]
        })

      cycle_2025 =
        SchoolsFixtures.cycle_fixture(%{
          school_id: school.id,
          start_at: ~D[2025-01-01],
          end_at: ~D[2025-12-31]
        })

      _cycle_2025_q1 =
        SchoolsFixtures.cycle_fixture(%{
          school_id: school.id,
          start_at: ~D[2025-01-01],
          end_at: ~D[2025-03-31],
          parent_cycle_id: cycle_2025.id
        })

      class_2023_a =
        SchoolsFixtures.class_fixture(%{
          school_id: school.id,
          cycle_id: cycle_2023.id,
          name: "AAA"
        })

      class_2023_b =
        SchoolsFixtures.class_fixture(%{
          school_id: school.id,
          cycle_id: cycle_2023.id,
          name: "BBB"
        })

      class_2024 = SchoolsFixtures.class_fixture(%{school_id: school.id, cycle_id: cycle_2024.id})

      _class_2025 =
        SchoolsFixtures.class_fixture(%{school_id: school.id, cycle_id: cycle_2025.id})

      # student won't be linked to class 2025
      student =
        SchoolsFixtures.student_fixture(%{
          school_id: school.id,
          classes_ids: [class_2023_a.id, class_2023_b.id, class_2024.id]
        })

      assert StudentsCycleInfo.list_cycles_and_classes_for_student(student) == [
               {cycle_2025, []},
               {cycle_2024, [class_2024]},
               {cycle_2023, [class_2023_a, class_2023_b]}
             ]
    end
  end
end
