defmodule Lanttern.StudentsCycleInfoTest do
  use Lanttern.DataCase

  alias Lanttern.StudentsCycleInfo

  describe "students_cycle_info" do
    alias Lanttern.StudentsCycleInfo.StudentCycleInfo

    import Lanttern.StudentsCycleInfoFixtures
    alias Lanttern.SchoolsFixtures

    @invalid_attrs %{school_info: nil, family_info: nil, profile_picture_url: nil}

    test "list_students_cycle_info/0 returns all students_cycle_info" do
      student_cycle_info = student_cycle_info_fixture()
      assert StudentsCycleInfo.list_students_cycle_info() == [student_cycle_info]
    end

    test "get_student_cycle_info!/1 returns the student_cycle_info with given id" do
      student_cycle_info = student_cycle_info_fixture()

      assert StudentsCycleInfo.get_student_cycle_info!(student_cycle_info.id) ==
               student_cycle_info
    end

    test "create_student_cycle_info/1 with valid data creates a student_cycle_info" do
      school = SchoolsFixtures.school_fixture()
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})
      cycle = SchoolsFixtures.cycle_fixture(%{school_id: school.id})

      valid_attrs = %{
        school_info: "some school_info",
        family_info: "some family_info",
        profile_picture_url: "some profile_picture",
        school_id: school.id,
        student_id: student.id,
        cycle_id: cycle.id
      }

      assert {:ok, %StudentCycleInfo{} = student_cycle_info} =
               StudentsCycleInfo.create_student_cycle_info(valid_attrs)

      assert student_cycle_info.school_info == "some school_info"
      assert student_cycle_info.family_info == "some family_info"
      assert student_cycle_info.profile_picture_url == "some profile_picture"
      assert student_cycle_info.school_id == school.id
      assert student_cycle_info.student_id == student.id
      assert student_cycle_info.cycle_id == cycle.id
    end

    test "create_student_cycle_info/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               StudentsCycleInfo.create_student_cycle_info(@invalid_attrs)
    end

    test "update_student_cycle_info/2 with valid data updates the student_cycle_info" do
      student_cycle_info = student_cycle_info_fixture()

      update_attrs = %{
        school_info: "some updated school_info",
        family_info: "some updated family_info",
        profile_picture_url: "some updated profile_picture"
      }

      assert {:ok, %StudentCycleInfo{} = student_cycle_info} =
               StudentsCycleInfo.update_student_cycle_info(student_cycle_info, update_attrs)

      assert student_cycle_info.school_info == "some updated school_info"
      assert student_cycle_info.family_info == "some updated family_info"
      assert student_cycle_info.profile_picture_url == "some updated profile_picture"
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

      assert {:ok, %StudentCycleInfo{}} =
               StudentsCycleInfo.delete_student_cycle_info(student_cycle_info)

      assert_raise Ecto.NoResultsError, fn ->
        StudentsCycleInfo.get_student_cycle_info!(student_cycle_info.id)
      end
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
