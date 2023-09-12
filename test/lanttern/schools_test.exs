defmodule Lanttern.SchoolsTest do
  use Lanttern.DataCase

  alias Lanttern.Schools

  describe "schools" do
    alias Lanttern.Schools.School

    import Lanttern.SchoolsFixtures

    @invalid_attrs %{name: nil}

    test "list_schools/0 returns all schools" do
      school = school_fixture()
      assert Schools.list_schools() == [school]
    end

    test "get_school!/1 returns the school with given id" do
      school = school_fixture()
      assert Schools.get_school!(school.id) == school
    end

    test "create_school/1 with valid data creates a school" do
      valid_attrs = %{name: "some name"}

      assert {:ok, %School{} = school} = Schools.create_school(valid_attrs)
      assert school.name == "some name"
    end

    test "create_school/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Schools.create_school(@invalid_attrs)
    end

    test "update_school/2 with valid data updates the school" do
      school = school_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %School{} = school} = Schools.update_school(school, update_attrs)
      assert school.name == "some updated name"
    end

    test "update_school/2 with invalid data returns error changeset" do
      school = school_fixture()
      assert {:error, %Ecto.Changeset{}} = Schools.update_school(school, @invalid_attrs)
      assert school == Schools.get_school!(school.id)
    end

    test "delete_school/1 deletes the school" do
      school = school_fixture()
      assert {:ok, %School{}} = Schools.delete_school(school)
      assert_raise Ecto.NoResultsError, fn -> Schools.get_school!(school.id) end
    end

    test "change_school/1 returns a school changeset" do
      school = school_fixture()
      assert %Ecto.Changeset{} = Schools.change_school(school)
    end
  end

  describe "classes" do
    alias Lanttern.Schools.Class

    import Lanttern.SchoolsFixtures

    @invalid_attrs %{name: nil}

    test "list_classes/1 returns all classes" do
      class = class_fixture()
      assert Schools.list_classes() == [class]
    end

    test "list_classes/1 with preloads returns all classes with preloaded data" do
      student = student_fixture()
      class = class_fixture(%{students_ids: [student.id]})

      [expected_class] = Schools.list_classes(preloads: :students)
      assert expected_class.id == class.id
      assert expected_class.students == [student]
    end

    test "get_class!/2 returns the class with given id" do
      class = class_fixture()
      assert Schools.get_class!(class.id) == class
    end

    test "get_class!/2 with preloads returns the class with given id and preloaded data" do
      student = student_fixture()
      class = class_fixture(%{students_ids: [student.id]})

      expected_class = Schools.get_class!(class.id, preloads: :students)
      assert expected_class.students == [student]
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

  describe "students" do
    alias Lanttern.Schools.Student

    import Lanttern.SchoolsFixtures

    @invalid_attrs %{name: nil}

    test "list_students/1 returns all students" do
      student = student_fixture()
      assert Schools.list_students() == [student]
    end

    test "list_students/1 with opts returns all students as expected" do
      class_1 = class_fixture()
      student_1 = student_fixture(%{classes_ids: [class_1.id]})
      class_2 = class_fixture()
      student_2 = student_fixture(%{classes_ids: [class_2.id]})

      # extra student for filtering validation
      student_fixture()

      students = Schools.list_students(classes_ids: [class_1.id, class_2.id], preloads: :classes)

      # assert length to check filtering
      assert length(students) == 2

      # assert students are preloaded
      expected_student_1 = Enum.find(students, fn s -> s.id == student_1.id end)
      assert expected_student_1.classes == [class_1]

      expected_student_2 = Enum.find(students, fn s -> s.id == student_2.id end)
      assert expected_student_2.classes == [class_2]
    end

    test "get_student!/2 returns the student with given id" do
      student = student_fixture()
      assert Schools.get_student!(student.id) == student
    end

    test "get_student!/2 with preloads returns the student with given id and preloaded data" do
      class = class_fixture()
      student = student_fixture(%{classes_ids: [class.id]})

      expected_student = Schools.get_student!(student.id, preloads: :classes)
      assert expected_student.classes == [class]
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

  describe "teachers" do
    alias Lanttern.Schools.Teacher

    import Lanttern.SchoolsFixtures

    @invalid_attrs %{name: nil}

    test "list_teachers/1 returns all teachers" do
      teacher = teacher_fixture()
      assert Schools.list_teachers() == [teacher]
    end

    test "list_teachers/1 with opts returns all students as expected" do
      school = school_fixture()
      teacher = teacher_fixture(%{school_id: school.id})

      [expected_teacher] = Schools.list_teachers(preloads: :school)

      # assert school is preloaded
      assert expected_teacher.id == teacher.id
      assert expected_teacher.school == school
    end

    test "get_teacher!/1 returns the teacher with given id" do
      teacher = teacher_fixture()
      assert Schools.get_teacher!(teacher.id) == teacher
    end

    test "get_teacher!/2 with preloads returns the teacher with given id and preloaded data" do
      school = school_fixture()
      teacher = teacher_fixture(%{school_id: school.id})

      expected_teacher = Schools.get_teacher!(teacher.id, preloads: :school)
      assert expected_teacher.id == teacher.id
      assert expected_teacher.school == school
    end

    test "create_teacher/1 with valid data creates a teacher" do
      school = school_fixture()
      valid_attrs = %{school_id: school.id, name: "some name"}

      assert {:ok, %Teacher{} = teacher} = Schools.create_teacher(valid_attrs)
      assert teacher.name == "some name"
    end

    test "create_teacher/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Schools.create_teacher(@invalid_attrs)
    end

    test "update_teacher/2 with valid data updates the teacher" do
      teacher = teacher_fixture()
      update_attrs = %{name: "some updated name"}

      assert {:ok, %Teacher{} = teacher} = Schools.update_teacher(teacher, update_attrs)
      assert teacher.name == "some updated name"
    end

    test "update_teacher/2 with invalid data returns error changeset" do
      teacher = teacher_fixture()
      assert {:error, %Ecto.Changeset{}} = Schools.update_teacher(teacher, @invalid_attrs)
      assert teacher == Schools.get_teacher!(teacher.id)
    end

    test "delete_teacher/1 deletes the teacher" do
      teacher = teacher_fixture()
      assert {:ok, %Teacher{}} = Schools.delete_teacher(teacher)
      assert_raise Ecto.NoResultsError, fn -> Schools.get_teacher!(teacher.id) end
    end

    test "change_teacher/1 returns a teacher changeset" do
      teacher = teacher_fixture()
      assert %Ecto.Changeset{} = Schools.change_teacher(teacher)
    end
  end
end
