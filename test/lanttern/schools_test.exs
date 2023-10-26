defmodule Lanttern.SchoolsTest do
  use Lanttern.DataCase

  alias Lanttern.Schools
  import Lanttern.SchoolsFixtures
  import Ecto.Query, only: [from: 2]

  describe "schools" do
    alias Lanttern.Schools.School

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

    @invalid_attrs %{name: nil}

    test "list_classes/1 returns all classes" do
      class = class_fixture()
      assert Schools.list_classes() == [class]
    end

    test "list_classes/1 with preloads and school filter returns all classes as expected" do
      school = school_fixture()
      student = student_fixture()
      class = class_fixture(%{school_id: school.id, students_ids: [student.id]})

      # extra classes for school filter validation
      class_fixture()
      class_fixture()

      [expected_class] =
        Schools.list_classes(preloads: [:school, :students], schools_ids: [school.id])

      assert expected_class.id == class.id
      assert expected_class.school == school
      assert expected_class.students == [student]
    end

    test "get_class!/2 returns the class with given id" do
      class = class_fixture()
      assert Schools.get_class!(class.id) == class
    end

    test "get_class!/2 with preloads returns the class with given id and preloaded data" do
      school = school_fixture()
      student = student_fixture()
      class = class_fixture(%{school_id: school.id, students_ids: [student.id]})

      expected_class = Schools.get_class!(class.id, preloads: [:school, :students])
      assert expected_class.id == class.id
      assert expected_class.school == school
      assert expected_class.students == [student]
    end

    test "create_class/1 with valid data creates a class" do
      school = school_fixture()
      valid_attrs = %{school_id: school.id, name: "some name"}

      assert {:ok, %Class{} = class} = Schools.create_class(valid_attrs)
      assert class.name == "some name"
      assert class.school_id == school.id
    end

    test "create_class/1 with valid data containing students creates a class with students" do
      school = school_fixture()
      student_1 = student_fixture()
      student_2 = student_fixture()
      student_3 = student_fixture()

      valid_attrs = %{
        name: "some name",
        school_id: school.id,
        students_ids: [
          student_1.id,
          student_2.id,
          student_3.id
        ]
      }

      assert {:ok, %Class{} = class} = Schools.create_class(valid_attrs)
      assert class.name == "some name"
      assert class.school_id == school.id
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

    @invalid_attrs %{name: nil}

    test "list_students/1 returns all students" do
      student = student_fixture()
      assert Schools.list_students() == [student]
    end

    test "list_students/1 with opts returns all students as expected" do
      school = school_fixture()
      class_1 = class_fixture()
      student_1 = student_fixture(%{school_id: school.id, classes_ids: [class_1.id]})
      class_2 = class_fixture()
      student_2 = student_fixture(%{school_id: school.id, classes_ids: [class_2.id]})

      # extra student for filtering validation
      student_fixture()

      expected_students =
        Schools.list_students(
          classes_ids: [class_1.id, class_2.id],
          preloads: [:school, :classes]
        )

      # assert length to check filtering
      assert length(expected_students) == 2

      # assert school and classes are preloaded
      for expected_student <- expected_students do
        assert expected_student.school == school

        case expected_student.id do
          id when id == student_1.id ->
            assert expected_student.classes == [class_1]

          id when id == student_2.id ->
            assert expected_student.classes == [class_2]
        end
      end
    end

    test "get_student!/2 returns the student with given id" do
      student = student_fixture()
      assert Schools.get_student!(student.id) == student
    end

    test "get_student!/2 with preloads returns the student with given id and preloaded data" do
      school = school_fixture()
      class = class_fixture()
      student = student_fixture(%{school_id: school.id, classes_ids: [class.id]})

      expected_student = Schools.get_student!(student.id, preloads: [:school, :classes])
      assert expected_student.id == student.id
      assert expected_student.school == school
      assert expected_student.classes == [class]
    end

    test "create_student/1 with valid data creates a student" do
      school = school_fixture()
      valid_attrs = %{school_id: school.id, name: "some name"}

      assert {:ok, %Student{} = student} = Schools.create_student(valid_attrs)
      assert student.name == "some name"
    end

    test "create_student/1 with valid data with classes_ids param creates a student with classes" do
      school = school_fixture()
      class_1 = class_fixture()
      class_2 = class_fixture()
      class_3 = class_fixture()

      valid_attrs = %{
        school_id: school.id,
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

    test "create_student/1 with valid data with classes param creates a student with classes" do
      school = school_fixture()
      class_1 = class_fixture()
      class_2 = class_fixture()
      class_3 = class_fixture()

      valid_attrs = %{
        school_id: school.id,
        name: "some name",
        classes: [
          class_1,
          class_2,
          class_3
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

  describe "csv parsing" do
    test "create_students_from_csv/3 creates classes and students, and returns a list with the registration status for each row" do
      school = school_fixture()
      class = class_fixture(name: "existing class", school_id: school.id)
      user = Lanttern.IdentityFixtures.user_fixture(email: "existing-user@school.com")

      csv_std_1 = %{
        class_name: "existing class",
        name: "Student A",
        email: "student-a@school.com"
      }

      csv_std_2 = %{
        class_name: "existing class",
        name: "Student A same user",
        email: "student-a@school.com"
      }

      csv_std_3 = %{
        class_name: "mapped to existing class",
        name: "With existing user email",
        email: "existing-user@school.com"
      }

      csv_std_4 = %{
        class_name: "mapped to existing class",
        name: "No email",
        email: ""
      }

      csv_std_5 = %{
        class_name: "new class",
        name: "With new class",
        email: "student-d@school.com"
      }

      csv_std_6 = %{
        class_name: "new class",
        name: "",
        email: "student-x@school.com"
      }

      csv_students = [csv_std_1, csv_std_2, csv_std_3, csv_std_4, csv_std_5, csv_std_6]

      class_name_id_map = %{
        "existing class" => class.id,
        "mapped to existing class" => class.id,
        "new class" => ""
      }

      {:ok, expected} =
        Schools.create_students_from_csv(csv_students, class_name_id_map, school.id)

      [
        {returned_csv_std_1, {:ok, std_1}},
        {returned_csv_std_2, {:ok, std_2}},
        {returned_csv_std_3, {:ok, std_3}},
        {returned_csv_std_4, {:ok, std_4}},
        {returned_csv_std_5, {:ok, std_5}},
        {returned_csv_std_6, {:error, _error}}
      ] = expected

      # assert students and classes

      assert returned_csv_std_1.name == csv_std_1.name
      assert std_1.name == csv_std_1.name
      assert std_1.classes == [class]
      assert get_user(std_1.id, "student")

      assert returned_csv_std_2.name == csv_std_2.name
      assert std_2.name == csv_std_2.name
      assert std_2.classes == [class]
      assert get_user(std_2.id, "student")

      assert get_user(std_1.id, "student") == get_user(std_2.id, "student")

      assert returned_csv_std_3.name == csv_std_3.name
      assert std_3.name == csv_std_3.name
      assert std_3.classes == [class]
      assert get_user(std_3.id, "student").id == user.id

      assert returned_csv_std_4.name == csv_std_4.name
      assert std_4.name == csv_std_4.name
      assert std_4.classes == [class]
      refute get_user(std_4.id, "student")

      assert returned_csv_std_5.name == csv_std_5.name
      assert std_5.name == csv_std_5.name
      assert std_5.classes |> hd() |> Map.get(:name) == "new class"
      assert get_user(std_5.id, "student")

      assert returned_csv_std_6.name == csv_std_6.name
    end

    test "create_teachers_from_csv/2 creates teachers, and returns a list with the registration status for each row" do
      school = school_fixture()
      user = Lanttern.IdentityFixtures.user_fixture(email: "existing-user@school.com")

      csv_teacher_1 = %{
        name: "Teacher A",
        email: "teacher-a@school.com"
      }

      csv_teacher_2 = %{
        name: "Teacher A same user",
        email: "teacher-a@school.com"
      }

      csv_teacher_3 = %{
        name: "With existing user email",
        email: "existing-user@school.com"
      }

      csv_teacher_4 = %{
        name: "No email",
        email: ""
      }

      csv_teacher_5 = %{
        name: "",
        email: "teacher-x@school.com"
      }

      csv_teachers = [csv_teacher_1, csv_teacher_2, csv_teacher_3, csv_teacher_4, csv_teacher_5]

      {:ok, expected} =
        Schools.create_teachers_from_csv(csv_teachers, school.id)

      [
        {returned_csv_teacher_1, {:ok, teacher_1}},
        {returned_csv_teacher_2, {:ok, teacher_2}},
        {returned_csv_teacher_3, {:ok, teacher_3}},
        {returned_csv_teacher_4, {:ok, teacher_4}},
        {returned_csv_teacher_5, {:error, _error}}
      ] = expected

      # assert students and classes

      assert returned_csv_teacher_1.name == csv_teacher_1.name
      assert teacher_1.name == csv_teacher_1.name
      assert get_user(teacher_1.id, "teacher")

      assert returned_csv_teacher_2.name == csv_teacher_2.name
      assert teacher_2.name == csv_teacher_2.name
      assert get_user(teacher_2.id, "teacher")

      assert get_user(teacher_1.id, "teacher") == get_user(teacher_2.id, "teacher")

      assert returned_csv_teacher_3.name == csv_teacher_3.name
      assert teacher_3.name == csv_teacher_3.name
      assert get_user(teacher_3.id, "teacher").id == user.id

      assert returned_csv_teacher_4.name == csv_teacher_4.name
      assert teacher_4.name == csv_teacher_4.name
      refute get_user(teacher_4.id, "teacher")

      assert returned_csv_teacher_5.name == csv_teacher_5.name
    end

    defp get_user(id, "student") do
      from(s in Schools.Student,
        left_join: p in Lanttern.Identity.Profile,
        on: p.student_id == s.id,
        left_join: u in Lanttern.Identity.User,
        on: u.id == p.user_id,
        where: s.id == ^id,
        select: u
      )
      |> Lanttern.Repo.one!()
    end

    defp get_user(id, "teacher") do
      from(t in Schools.Teacher,
        left_join: p in Lanttern.Identity.Profile,
        on: p.teacher_id == t.id,
        left_join: u in Lanttern.Identity.User,
        on: u.id == p.user_id,
        where: t.id == ^id,
        select: u
      )
      |> Lanttern.Repo.one!()
    end
  end
end
