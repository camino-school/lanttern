defmodule Lanttern.SchoolsTest do
  use Lanttern.DataCase

  alias Lanttern.Schools

  describe "students" do
    alias Lanttern.Schools.Student

    import Lanttern.SchoolsFixtures

    @invalid_attrs %{name: nil}

    test "list_students/0 returns all students" do
      student = student_fixture()
      assert Schools.list_students() == [student]
    end

    test "get_student!/1 returns the student with given id" do
      student = student_fixture()
      assert Schools.get_student!(student.id) == student
    end

    test "create_student/1 with valid data creates a student" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Student{} = student} = Schools.create_student(valid_attrs)
      assert student.name == "some name"
    end

    test "create_student/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Schools.create_student(@invalid_attrs)
    end

    test "update_student/2 with valid data updates the student" do
      student = student_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Student{} = student} = Schools.update_student(student, update_attrs)
      assert student.name == "some updated name"
    end

    test "update_student/2 with invalid data returns error changeset" do
      student = student_fixture()
      assert {:error, %Ecto.Changeset{}} = Schools.update_student(student, @invalid_attrs)
      assert student == Schools.get_student!(student.id)
    end

    test "delete_student/1 deletes the student" do
      student = student_fixture()
      assert {:ok, %Student{}} = Schools.delete_student(student)
      assert_raise Ecto.NoResultsError, fn -> Schools.get_student!(student.id) end
    end

    test "change_student/1 returns a student changeset" do
      student = student_fixture()
      assert %Ecto.Changeset{} = Schools.change_student(student)
    end
  end
end
