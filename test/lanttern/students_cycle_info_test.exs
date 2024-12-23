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
end
