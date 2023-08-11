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

    test "create_student/1 with valid data containing classes creates a student with classes" do
      class_1 = class_fixture()
      class_2 = class_fixture()
      class_3 = class_fixture()

      valid_attrs = %{
        name: "some name",
        classes_ids: [
          class_1.id,
          class_2.id,
          class_3.id
        ]
      }

      assert {:ok, %Student{} = student} = Schools.create_student(valid_attrs)
      assert student.name == "some name"
      assert Enum.find(student.classes, fn c -> c.id == class_1.id end)
      assert Enum.find(student.classes, fn c -> c.id == class_2.id end)
      assert Enum.find(student.classes, fn c -> c.id == class_3.id end)
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

    test "update_student/2 with valid data containing classes updates the student" do
      class_1 = class_fixture()
      class_2 = class_fixture()
      class_3 = class_fixture()
      student = student_fixture(%{classes_ids: [class_1.id, class_2.id]})

      update_attrs = %{
        name: "some updated name",
        classes_ids: [class_1.id, class_3.id]
      }

      assert {:ok, %Student{} = student} = Schools.update_student(student, update_attrs)
      assert student.name == "some updated name"
      assert length(student.classes) == 2
      assert Enum.find(student.classes, fn c -> c.id == class_1.id end)
      assert Enum.find(student.classes, fn c -> c.id == class_3.id end)
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

  describe "classes" do
    alias Lanttern.Schools.Class

    import Lanttern.SchoolsFixtures

    @invalid_attrs %{name: nil}

    test "list_classes/0 returns all classes" do
      class = class_fixture()
      assert Schools.list_classes() == [class]
    end

    test "get_class!/1 returns the class with given id" do
      class = class_fixture()
      assert Schools.get_class!(class.id) == class
    end

    test "create_class/1 with valid data creates a class" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %Class{} = class} = Schools.create_class(valid_attrs)
      assert class.name == "some name"
    end

    test "create_class/1 with valid data containing students creates a class with students" do
      student_1 = student_fixture()
      student_2 = student_fixture()
      student_3 = student_fixture()

      valid_attrs = %{
        name: "some name",
        students_ids: [
          student_1.id,
          student_2.id,
          student_3.id
        ]
      }

      assert {:ok, %Class{} = class} = Schools.create_class(valid_attrs)
      assert class.name == "some name"
      assert Enum.find(class.students, fn s -> s.id == student_1.id end)
      assert Enum.find(class.students, fn s -> s.id == student_2.id end)
      assert Enum.find(class.students, fn s -> s.id == student_3.id end)
    end

    test "create_class/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Schools.create_class(@invalid_attrs)
    end

    test "update_class/2 with valid data updates the class" do
      class = class_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Class{} = class} = Schools.update_class(class, update_attrs)
      assert class.name == "some updated name"
    end

    test "update_class/2 with valid data containing students updates the class" do
      student_1 = student_fixture()
      student_2 = student_fixture()
      student_3 = student_fixture()
      class = class_fixture(%{students_ids: [student_1.id, student_2.id]})

      update_attrs = %{
        name: "some updated name",
        students_ids: [student_1.id, student_3.id]
      }

      assert {:ok, %Class{} = class} = Schools.update_class(class, update_attrs)
      assert class.name == "some updated name"
      assert length(class.students) == 2
      assert Enum.find(class.students, fn s -> s.id == student_1.id end)
      assert Enum.find(class.students, fn s -> s.id == student_3.id end)
    end

    test "update_class/2 with invalid data returns error changeset" do
      class = class_fixture()
      assert {:error, %Ecto.Changeset{}} = Schools.update_class(class, @invalid_attrs)
      assert class == Schools.get_class!(class.id)
    end

    test "delete_class/1 deletes the class" do
      class = class_fixture()
      assert {:ok, %Class{}} = Schools.delete_class(class)
      assert_raise Ecto.NoResultsError, fn -> Schools.get_class!(class.id) end
    end

    test "change_class/1 returns a class changeset" do
      class = class_fixture()
      assert %Ecto.Changeset{} = Schools.change_class(class)
    end
  end
end
