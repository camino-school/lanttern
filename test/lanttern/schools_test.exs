defmodule Lanttern.SchoolsTest do
  use Lanttern.DataCase

  alias Lanttern.Schools
  import Lanttern.Factory
  import Lanttern.SchoolsFixtures
  import Lanttern.IdentityFixtures
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

  describe "school_cycles" do
    alias Lanttern.Schools.Cycle

    import Lanttern.SchoolsFixtures

    @invalid_attrs %{name: nil, start_at: nil, end_at: nil}

    test "list_cycles/1 returns all school_cycles" do
      cycle = cycle_fixture()
      assert Schools.list_cycles() == [cycle]
    end

    test "list_cycles/1 with school filter returns all cycles as expected" do
      school = school_fixture()
      cycle = cycle_fixture(%{school_id: school.id})

      # extra cycles for school filter validation
      cycle_fixture()
      cycle_fixture()

      assert [cycle] == Schools.list_cycles(schools_ids: [school.id])
    end

    test "list_cycles/1 with order opt returns all cycles ordered" do
      cycle_2024_c =
        cycle_fixture(%{start_at: ~D[2024-01-01], end_at: ~D[2024-12-31], name: "CCC"})

      cycle_2023_a =
        cycle_fixture(%{start_at: ~D[2023-01-01], end_at: ~D[2023-12-31], name: "AAA"})

      cycle_2022_b =
        cycle_fixture(%{start_at: ~D[2022-01-01], end_at: ~D[2022-12-31], name: "BBB"})

      assert [cycle_2022_b, cycle_2023_a, cycle_2024_c] ==
               Schools.list_cycles(order: :asc)
    end

    test "list_cycles/1 with parent_cycles_only: true opt removes subcycles from list" do
      school = school_fixture()
      parent_cycle = cycle_fixture(%{school_id: school.id})
      _subcycle = cycle_fixture(%{school_id: school.id, parent_cycle_id: parent_cycle.id})

      assert [parent_cycle] == Schools.list_cycles(parent_cycles_only: true)
    end

    test "list_cycles/1 with subcycles_only: true opt removes parent cycles from list" do
      school = school_fixture()
      parent_cycle = cycle_fixture(%{school_id: school.id})
      subcycle = cycle_fixture(%{school_id: school.id, parent_cycle_id: parent_cycle.id})

      assert [subcycle] == Schools.list_cycles(subcycles_only: true)
    end

    test "list_cycles/1 with subcycles_of_parent_id returns the subcycles of the given parent" do
      school = school_fixture()
      parent_cycle = cycle_fixture(%{school_id: school.id})
      subcycle = cycle_fixture(%{school_id: school.id, parent_cycle_id: parent_cycle.id})

      # other fixtures for filter testing
      other_parent_cycle = cycle_fixture(%{school_id: school.id})

      _other_subcycle =
        cycle_fixture(%{school_id: school.id, parent_cycle_id: other_parent_cycle.id})

      assert [subcycle] == Schools.list_cycles(subcycles_of_parent_id: parent_cycle.id)
    end

    test "list_cycles_and_subcycles/1 with school filter returns all cycles with preloaded subcycles as expected" do
      school = school_fixture()

      cycle_2024 =
        cycle_fixture(%{school_id: school.id, start_at: ~D[2024-01-01], end_at: ~D[2024-12-31]})

      cycle_2024_1 =
        cycle_fixture(%{
          school_id: school.id,
          start_at: ~D[2024-01-01],
          end_at: ~D[2024-06-30],
          parent_cycle_id: cycle_2024.id
        })

      cycle_2024_2 =
        cycle_fixture(%{
          school_id: school.id,
          start_at: ~D[2024-07-01],
          end_at: ~D[2024-12-31],
          parent_cycle_id: cycle_2024.id
        })

      cycle_2023 =
        cycle_fixture(%{school_id: school.id, start_at: ~D[2023-01-01], end_at: ~D[2023-12-31]})

      cycle_2023_1 =
        cycle_fixture(%{
          school_id: school.id,
          start_at: ~D[2023-01-01],
          end_at: ~D[2023-06-30],
          parent_cycle_id: cycle_2023.id
        })

      cycle_2023_2 =
        cycle_fixture(%{
          school_id: school.id,
          start_at: ~D[2023-07-01],
          end_at: ~D[2023-12-31],
          parent_cycle_id: cycle_2023.id
        })

      # extra cycles for school filter validation
      cycle_fixture()
      cycle_fixture()

      [expected_cycle_2024, expected_cycle_2023] =
        Schools.list_cycles_and_subcycles(schools_ids: [school.id])

      assert expected_cycle_2024.id == cycle_2024.id
      assert expected_cycle_2024.subcycles == [cycle_2024_2, cycle_2024_1]
      assert expected_cycle_2023.id == cycle_2023.id
      assert expected_cycle_2023.subcycles == [cycle_2023_2, cycle_2023_1]
    end

    test "get_cycle!/1 returns the cycle with given id" do
      cycle = cycle_fixture()
      assert Schools.get_cycle!(cycle.id) == cycle
    end

    test "get_newest_parent_cycle_from_school/1 returns the newest cycle from given school" do
      school = school_fixture()

      newest_cycle =
        cycle_fixture(%{school_id: school.id, start_at: ~D[2030-01-01], end_at: ~D[2030-12-31]})

      # other cycles for testing (newer but sub, older, from other school)
      cycle_fixture(%{start_at: ~D[2031-01-01], end_at: ~D[2031-12-31]})

      cycle_fixture(%{
        school_id: school.id,
        start_at: ~D[2031-01-01],
        end_at: ~D[2031-12-31],
        parent_cycle_id: newest_cycle.id
      })

      cycle_fixture(%{school_id: school.id, start_at: ~D[2029-01-01], end_at: ~D[2029-12-31]})
      cycle_fixture()

      assert Schools.get_newest_parent_cycle_from_school(school.id) == newest_cycle
    end

    test "create_cycle/1 with valid data creates a cycle" do
      school = school_fixture()

      valid_attrs = %{
        name: "some name",
        start_at: ~D[2023-11-09],
        end_at: ~D[2023-12-09],
        school_id: school.id
      }

      assert {:ok, %Cycle{} = cycle} = Schools.create_cycle(valid_attrs)
      assert cycle.name == "some name"
      assert cycle.start_at == ~D[2023-11-09]
      assert cycle.end_at == ~D[2023-12-09]
    end

    test "create_cycle/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Schools.create_cycle(@invalid_attrs)
    end

    test "create_cycle/1 prevents using subcycle as parent cycle" do
      school = school_fixture()
      parent_cycle = cycle_fixture(%{school_id: school.id})
      subcycle = cycle_fixture(%{school_id: school.id, parent_cycle_id: parent_cycle.id})

      create_attrs = %{
        name: "some name",
        start_at: ~D[2023-11-09],
        end_at: ~D[2023-12-09],
        school_id: school.id,
        parent_cycle_id: subcycle.id
      }

      assert {:error,
              %Ecto.Changeset{
                errors: [parent_cycle_id: {"You can't use a subcycle as a parent cycle", []}]
              }} = Schools.create_cycle(create_attrs)
    end

    test "update_cycle/2 with valid data updates the cycle" do
      cycle = cycle_fixture()

      update_attrs = %{
        name: "some updated name",
        start_at: ~D[2023-11-10],
        end_at: ~D[2023-12-10]
      }

      assert {:ok, %Cycle{} = cycle} = Schools.update_cycle(cycle, update_attrs)
      assert cycle.name == "some updated name"
      assert cycle.start_at == ~D[2023-11-10]
      assert cycle.end_at == ~D[2023-12-10]
    end

    test "update_cycle/2 with invalid data returns error changeset" do
      cycle = cycle_fixture()
      assert {:error, %Ecto.Changeset{}} = Schools.update_cycle(cycle, @invalid_attrs)
      assert cycle == Schools.get_cycle!(cycle.id)
    end

    test "update_cycle/2 prevents using subcycle as parent cycle" do
      school = school_fixture()
      parent_cycle = cycle_fixture(%{school_id: school.id})
      subcycle = cycle_fixture(%{school_id: school.id, parent_cycle_id: parent_cycle.id})
      cycle = cycle_fixture(%{school_id: school.id})

      update_attrs = %{
        name: "updated name",
        parent_cycle_id: subcycle.id
      }

      assert {:error,
              %Ecto.Changeset{
                errors: [parent_cycle_id: {"You can't use a subcycle as a parent cycle", []}]
              }} = Schools.update_cycle(cycle, update_attrs)
    end

    test "delete_cycle/1 deletes the cycle" do
      cycle = cycle_fixture()
      assert {:ok, %Cycle{}} = Schools.delete_cycle(cycle)
      assert_raise Ecto.NoResultsError, fn -> Schools.get_cycle!(cycle.id) end
    end

    test "change_cycle/1 returns a cycle changeset" do
      cycle = cycle_fixture()
      assert %Ecto.Changeset{} = Schools.change_cycle(cycle)
    end
  end

  describe "classes" do
    alias Lanttern.Schools.Class

    @invalid_attrs %{name: nil}

    test "list_classes/1 returns all classes" do
      class = class_fixture()
      [expected] = Schools.list_classes()
      assert expected.id == class.id
    end

    test "list_classes/1 with preloads and school filter returns all classes as expected" do
      school = school_fixture()
      student = student_fixture()
      year = Lanttern.TaxonomyFixtures.year_fixture()

      class =
        class_fixture(%{school_id: school.id, students_ids: [student.id], years_ids: [year.id]})

      # extra classes for school filter validation
      class_fixture()
      class_fixture()

      [expected_class] =
        Schools.list_classes(preloads: [:school, :students, :years], schools_ids: [school.id])

      assert expected_class.id == class.id
      assert expected_class.school == school
      assert expected_class.students == [student]
      assert expected_class.years == [year]
    end

    test "list_classes/1 with opts returns all classes correctly" do
      # in this test we'll apply school, cycle, and year filters
      # and preload students, which should be ordered alphabetically

      school = school_fixture()

      cycle_25 =
        cycle_fixture(%{school_id: school.id, start_at: ~D[2025-01-01], end_at: ~D[2025-12-31]})

      cycle_24 =
        cycle_fixture(%{school_id: school.id, start_at: ~D[2024-01-01], end_at: ~D[2024-12-31]})

      cycle_23 =
        cycle_fixture(%{school_id: school.id, start_at: ~D[2023-01-01], end_at: ~D[2023-12-31]})

      year = Lanttern.TaxonomyFixtures.year_fixture()

      class_b_25 =
        class_fixture(%{
          school_id: school.id,
          name: "BBB",
          cycle_id: cycle_25.id,
          years_ids: [year.id]
        })

      class_a_25 =
        class_fixture(%{
          school_id: school.id,
          name: "AAA 25",
          cycle_id: cycle_25.id,
          years_ids: [year.id]
        })

      class_a_24 =
        class_fixture(%{
          school_id: school.id,
          name: "AAA 24",
          cycle_id: cycle_24.id,
          years_ids: [year.id]
        })

      class_a_23 =
        class_fixture(%{
          school_id: school.id,
          name: "AAA 24",
          cycle_id: cycle_23.id,
          years_ids: [year.id]
        })

      # extra class for filtering test
      _class_from_another_year = class_fixture(%{school_id: school.id})

      # put students only in class a
      student_x =
        student_fixture(%{
          name: "XXX",
          classes_ids: [class_a_23.id, class_a_24.id, class_a_25.id]
        })

      student_y = student_fixture(%{name: "YYY", classes_ids: [class_a_25.id]})

      student_z =
        student_fixture(%{
          name: "ZZZ",
          classes_ids: [class_a_25.id],
          deactivated_at: DateTime.utc_now()
        })

      # extra classes for school filter validation
      class_fixture()
      class_fixture()

      [expected_a_25, expected_b_25, expected_a_24] =
        Schools.list_classes(
          schools_ids: [school.id],
          years_ids: [year.id],
          cycles_ids: [cycle_24.id, cycle_25.id],
          count_active_students: true,
          preloads: :students
        )

      assert expected_a_25.id == class_a_25.id
      assert expected_a_25.active_students_count == 2
      assert expected_a_25.cycle.id == cycle_25.id
      assert [expected_std_x, expected_std_y, expected_std_z] = expected_a_25.students
      assert expected_std_x.id == student_x.id
      assert expected_std_y.id == student_y.id
      assert expected_std_z.id == student_z.id

      assert expected_b_25.id == class_b_25.id
      assert expected_b_25.cycle.id == cycle_25.id

      assert expected_a_24.id == class_a_24.id
      assert expected_a_24.cycle.id == cycle_24.id
      assert [expected_std_x] = expected_a_24.students
      assert expected_std_x.id == student_x.id
    end

    test "list_classes_for_students_in_date/2 returns the correct list" do
      school = school_fixture()

      cycle_2024 =
        cycle_fixture(%{school_id: school.id, start_at: ~D[2024-01-01], end_at: ~D[2024-12-31]})

      cycle_2025 =
        cycle_fixture(%{school_id: school.id, start_at: ~D[2025-01-01], end_at: ~D[2025-12-31]})

      class_2024 = class_fixture(%{school_id: school.id, cycle_id: cycle_2024.id})
      class_2025 = class_fixture(%{school_id: school.id, cycle_id: cycle_2025.id})

      student_a =
        student_fixture(%{school_id: school.id, classes_ids: [class_2024.id, class_2025.id]})

      student_b =
        student_fixture(%{school_id: school.id, classes_ids: [class_2024.id]})

      student_c =
        student_fixture(%{school_id: school.id, classes_ids: [class_2025.id]})

      [expected_class_2024] =
        Schools.list_classes_for_students_in_date(
          [student_a.id, student_b.id, student_c.id],
          ~D[2024-06-10]
        )

      assert expected_class_2024.id == class_2024.id
      assert expected_class_2024.cycle.id == cycle_2024.id
    end

    test "list_user_classes/1 returns all classes from user's school correctly" do
      school = school_fixture()
      class = class_fixture(%{school_id: school.id})

      # extra class for filtering test
      _class_from_another_school = class_fixture()

      staff_member = staff_member_fixture(%{school_id: school.id})

      profile =
        Lanttern.IdentityFixtures.staff_member_profile_fixture(%{
          staff_member_id: staff_member.id
        })

      user = %Lanttern.Identity.User{current_profile: %{profile | school_id: school.id}}

      [expected] = Schools.list_user_classes(user)
      assert expected.id == class.id
    end

    test "list_user_classes/1 returns error tuple when user is student" do
      school = school_fixture()
      student = student_fixture(%{school_id: school.id})
      profile = Lanttern.IdentityFixtures.student_profile_fixture(%{student_id: student.id})

      user = %{
        current_profile:
          Lanttern.Identity.get_profile!(profile.id, preloads: [:staff_member, :student])
      }

      assert {:error, "User not allowed to list classes"} == Schools.list_user_classes(user)
    end

    test "search_classes/2 returns all items matched by search" do
      _class_1 = class_fixture(%{name: "lorem ipsum xolor sit amet"})
      class_2 = class_fixture(%{name: "lorem ipsum dolor sit amet"})
      class_3 = class_fixture(%{name: "lorem ipsum dolorxxx sit amet"})
      _class_4 = class_fixture(%{name: "lorem ipsum xxxxx sit amet"})

      [expected_2, expected_3] = Schools.search_classes("dolor")
      assert expected_2.id == class_2.id
      assert expected_3.id == class_3.id
    end

    test "search_classes/2 with school opt returns only classs from given school" do
      school = school_fixture()

      _class_1 = class_fixture(%{name: "lorem ipsum xolor sit amet"})
      class_2 = class_fixture(%{name: "lorem ipsum dolor sit amet", school_id: school.id})
      _class_3 = class_fixture(%{name: "lorem ipsum dolorxxx sit amet"})
      _class_4 = class_fixture(%{name: "lorem ipsum xxxxx sit amet"})

      [expected] = Schools.search_classes("dolor", schools_ids: [school.id])
      assert expected.id == class_2.id
    end

    test "get_class/2 returns the class with given id" do
      class = class_fixture()
      assert Schools.get_class(class.id) == class
    end

    test "get_class/2 returns nil if class with given id does not exist" do
      class_fixture()
      assert Schools.get_class(999_999) == nil
    end

    test "get_class/2 with check_permissions_for_user checks for user permission" do
      school = school_fixture()
      class = class_fixture(%{school_id: school.id})

      user =
        Lanttern.IdentityFixtures.current_staff_member_user_fixture(%{school_id: school.id}, [
          "school_management"
        ])

      assert Schools.get_class(class.id, check_permissions_for_user: user) == class

      school_user_without_management_permission =
        Lanttern.IdentityFixtures.current_staff_member_user_fixture(%{school_id: school.id})

      assert Schools.get_class(class.id,
               check_permissions_for_user: school_user_without_management_permission
             )
             |> is_nil()

      manager_from_other_school =
        Lanttern.IdentityFixtures.current_staff_member_user_fixture(%{}, ["school_management"])

      assert Schools.get_class(class.id, check_permissions_for_user: manager_from_other_school)
             |> is_nil()
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
      cycle = cycle_fixture(%{school_id: school.id})
      valid_attrs = %{school_id: school.id, cycle_id: cycle.id, name: "some name"}

      assert {:ok, %Class{} = class} = Schools.create_class(valid_attrs)
      assert class.name == "some name"
      assert class.school_id == school.id
    end

    test "create_class/1 with valid data containing students creates a class with students" do
      school = school_fixture()
      cycle = cycle_fixture(%{school_id: school.id})
      student_1 = student_fixture()
      student_2 = student_fixture()
      student_3 = student_fixture()

      valid_attrs = %{
        name: "some name",
        school_id: school.id,
        cycle_id: cycle.id,
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
      # create and link year and student to test if relations are deleted with class
      year = Lanttern.TaxonomyFixtures.year_fixture()
      student = student_fixture()

      class = class_fixture(%{years_ids: [year.id], students_ids: [student.id]})

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
    alias Lanttern.StudentsCycleInfoFixtures

    @invalid_attrs %{name: nil}

    test "list_students/1 returns all students" do
      student = student_fixture()
      assert Schools.list_students() == [student]
    end

    test "list_students/1 with class_id opt filter results by class" do
      class = class_fixture()
      student = student_fixture(%{classes_ids: [class.id]})

      # other students for filter testing
      student_fixture()

      assert [expected_student] = Schools.list_students(class_id: class.id)
      assert expected_student.id == student.id
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

    test "list_students/1 with load_email opt returns the students with its email" do
      student_a = student_fixture(%{name: "a"})
      student_b = student_fixture(%{name: "b"})

      # create user/profile only for student_a
      user = Lanttern.IdentityFixtures.user_fixture(%{email: "a@email.com"})

      _profile =
        Lanttern.IdentityFixtures.student_profile_fixture(%{
          user_id: user.id,
          student_id: student_a.id
        })

      [expected_student_a, expected_student_b] =
        Schools.list_students(
          load_email: true,
          # use load_profile_picture_from_cycle_id
          # to validate select_merge
          load_profile_picture_from_cycle_id: 1
        )

      assert expected_student_a.id == student_a.id
      assert expected_student_a.email == "a@email.com"
      assert expected_student_b.id == student_b.id
      assert is_nil(expected_student_b.email)
    end

    test "list_students/1 with only_in_some_class opts returns all students as expected" do
      school = school_fixture()
      class_1 = class_fixture(%{school_id: school.id})
      class_2 = class_fixture(%{school_id: school.id})
      student_a = student_fixture(%{name: "AAA", school_id: school.id, classes_ids: [class_1.id]})
      student_b = student_fixture(%{name: "BBB", school_id: school.id, classes_ids: [class_2.id]})
      student_c = student_fixture(%{name: "CCC", school_id: school.id})

      # extra student for filtering validation
      student_fixture()

      [expected_std_a, expected_std_b, expected_std_c] =
        Schools.list_students(school_id: school.id)

      assert expected_std_a.id == student_a.id
      assert expected_std_b.id == student_b.id
      assert expected_std_c.id == student_c.id

      [expected_std_a, expected_std_b] =
        Schools.list_students(school_id: school.id, only_in_some_class: true)

      assert expected_std_a.id == student_a.id
      assert expected_std_b.id == student_b.id

      [expected_std_c] =
        Schools.list_students(school_id: school.id, only_in_some_class: false)

      assert expected_std_c.id == student_c.id
    end

    test "list_students/1 with school opts returns students filtered by school" do
      school = school_fixture()
      student_1 = student_fixture(%{school_id: school.id, name: "AAA"})
      student_2 = student_fixture(%{school_id: school.id, name: "BBB"})

      # extra student for filtering validation
      student_fixture()

      assert [student_1, student_2] == Schools.list_students(school_id: school.id)
    end

    test "list_students/1 with only_active opt returns the students filtered by their deactivated status" do
      active_student = student_fixture()
      _deactivated_student = student_fixture(%{deactivated_at: DateTime.utc_now()})

      assert [active_student] == Schools.list_students(only_active: true)
    end

    test "list_students/1 with only_deactivated opt returns the students filtered by their deactivated status" do
      deactivated_student = student_fixture(%{deactivated_at: DateTime.utc_now()})
      _active_student = student_fixture()

      assert [deactivated_student] == Schools.list_students(only_deactivated: true)
    end

    test "list_students/1 with preload_classes_from_cycle_id opt return students with correct classes preload" do
      school = school_fixture()
      class_1 = class_fixture(%{school_id: school.id})
      class_2 = class_fixture(%{school_id: school.id})
      student_1 = student_fixture(%{school_id: school.id, name: "AAA", classes_ids: [class_1.id]})
      student_2 = student_fixture(%{school_id: school.id, name: "BBB", classes_ids: [class_2.id]})

      student_1_2 =
        student_fixture(%{
          school_id: school.id,
          name: "CCC",
          classes_ids: [class_1.id, class_1.id]
        })

      [expected_1, expected_2, expected_1_2] =
        Schools.list_students(
          # use classes_ids opt to validate joins
          # (both need classes join to work, but each one handles it differently)
          classes_ids: [class_1.id, class_2.id],
          preload_classes_from_cycle_id: class_1.cycle_id
        )

      assert expected_1.id == student_1.id
      assert [class_1] == expected_1.classes

      assert expected_2.id == student_2.id
      assert [] == expected_2.classes

      assert expected_1_2.id == student_1_2.id
      assert [class_1] == expected_1_2.classes
    end

    test "list_students/1 with load_profile_picture_from_cycle_id opt uses the student cycle info picture" do
      school = school_fixture()
      student = student_fixture(%{school_id: school.id})

      student_cycle_info =
        StudentsCycleInfoFixtures.student_cycle_info_fixture(%{
          school_id: school.id,
          student_id: student.id,
          profile_picture_url: "http://example.com/profile_picture.jpg"
        })

      # extra student cycle info for filtering validation
      StudentsCycleInfoFixtures.student_cycle_info_fixture(%{
        school_id: school.id,
        student_id: student.id,
        profile_picture_url: "http://not-loaded.com/profile_picture.jpg"
      })

      [expected_student] =
        Schools.list_students(load_profile_picture_from_cycle_id: student_cycle_info.cycle_id)

      assert expected_student.id == student.id
      assert expected_student.profile_picture_url == "http://example.com/profile_picture.jpg"
    end

    test "list_students/1 with students_ids opts returns students filtered by given ids" do
      school = school_fixture()
      student_1 = student_fixture(%{school_id: school.id, name: "AAA"})
      student_2 = student_fixture(%{school_id: school.id, name: "BBB"})

      # extra student for filtering validation
      student_fixture(%{school_id: school.id})
      student_fixture()

      assert [student_1, student_2] ==
               Schools.list_students(students_ids: [student_1.id, student_2.id])
    end

    test "search_students/2 returns all items matched by search" do
      _student_1 = student_fixture(%{name: "lorem ipsum xolor sit amet"})
      student_2 = student_fixture(%{name: "lorem ipsum dolor sit amet"})
      student_3 = student_fixture(%{name: "lorem ipsum dolorxxx sit amet"})
      _student_4 = student_fixture(%{name: "lorem ipsum xxxxx sit amet"})

      assert [student_2, student_3] == Schools.search_students("dolor")
    end

    test "search_students/2 with school opt returns only students from given school" do
      school = school_fixture()

      _student_1 = student_fixture(%{name: "lorem ipsum xolor sit amet"})
      student_2 = student_fixture(%{name: "lorem ipsum dolor sit amet", school_id: school.id})
      _student_3 = student_fixture(%{name: "lorem ipsum dolorxxx sit amet"})
      _student_4 = student_fixture(%{name: "lorem ipsum xxxxx sit amet"})

      assert [student_2] == Schools.search_students("dolor", school_id: school.id)
    end

    test "get_student/2 returns the student with given id" do
      student = student_fixture()
      assert Schools.get_student(student.id) == student
    end

    test "get_student/2 returns nil if student with given id does not exist" do
      student_fixture()
      assert Schools.get_student(99_999) == nil
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

    test "get_student/2 with load_email opt returns the student with its email" do
      user = Lanttern.IdentityFixtures.user_fixture(%{email: "email.abc@email.com"})

      profile =
        Lanttern.IdentityFixtures.student_profile_fixture(%{user_id: user.id})

      expected_student = Schools.get_student(profile.student_id, load_email: true)
      assert expected_student.id == profile.student_id
      assert expected_student.email == "email.abc@email.com"
    end

    test "get_student/2 with load_profile_picture_from_cycle_id and preload_classes_from_cycle_id opts load the correct profile picture and preloads the correct classes" do
      school = school_fixture()

      cycle_2024 =
        cycle_fixture(%{school_id: school.id, start_at: ~D[2024-01-01], end_at: ~D[2024-12-31]})

      cycle_2025 =
        cycle_fixture(%{school_id: school.id, start_at: ~D[2025-01-01], end_at: ~D[2025-12-31]})

      class_2024 = class_fixture(%{school_id: school.id, cycle_id: cycle_2024.id})
      class_2025_a = class_fixture(%{school_id: school.id, cycle_id: cycle_2025.id, name: "AAA"})
      class_2025_b = class_fixture(%{school_id: school.id, cycle_id: cycle_2025.id, name: "BBB"})

      student =
        student_fixture(%{
          school_id: school.id,
          classes_ids: [class_2024.id, class_2025_a.id, class_2025_b.id]
        })

      _student_cycle_info_2024 =
        StudentsCycleInfoFixtures.student_cycle_info_fixture(%{
          school_id: school.id,
          student_id: student.id,
          cycle_id: cycle_2024.id,
          profile_picture_url: "http://example.com/profile_picture_2024.jpg"
        })

      _student_cycle_info_2025 =
        StudentsCycleInfoFixtures.student_cycle_info_fixture(%{
          school_id: school.id,
          student_id: student.id,
          cycle_id: cycle_2025.id,
          profile_picture_url: "http://example.com/profile_picture_2025.jpg"
        })

      expected_student =
        Schools.get_student(student.id,
          load_profile_picture_from_cycle_id: cycle_2025.id,
          preload_classes_from_cycle_id: cycle_2025.id
        )

      assert expected_student.id == student.id
      assert expected_student.profile_picture_url == "http://example.com/profile_picture_2025.jpg"
      assert expected_student.classes == [class_2025_a, class_2025_b]
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

    test "create_student/1 with email creates a student linked to new profile/user" do
      school = school_fixture()

      valid_attrs = %{
        "school_id" => school.id,
        "name" => "some name",
        "email" => "some@email.com"
      }

      {:ok, %Student{} = student} = Schools.create_student(valid_attrs)
      assert student.name == "some name"
      assert student.email == "some@email.com"

      student_with_preloads =
        Schools.get_student!(student.id, preloads: [profile: :user])

      assert student_with_preloads.profile.user.email == "some@email.com"
    end

    test "create_student/1 with email creates a student linked to new profile and existing user" do
      school = school_fixture()
      user = Lanttern.IdentityFixtures.user_fixture(email: "some@email.com")

      valid_attrs = %{
        "school_id" => school.id,
        "name" => "some name",
        "email" => "some@email.com"
      }

      {:ok, %Student{} = student} = Schools.create_student(valid_attrs)
      assert student.name == "some name"
      assert student.email == "some@email.com"

      student_with_preloads =
        Schools.get_student!(student.id, preloads: [profile: :user])

      assert student_with_preloads.profile.user.id == user.id
    end

    test "update_student/2 with invalid data returns error changeset" do
      student = student_fixture()
      assert {:error, %Ecto.Changeset{}} = Schools.update_student(student, @invalid_attrs)
      assert student == Schools.get_student!(student.id)
    end

    test "delete_student/1 deletes the student" do
      # create and link class to test if relations are deleted with student
      class = class_fixture()
      student = student_fixture(%{classes_ids: [class.id]})

      assert {:ok, %Student{}} = Schools.delete_student(student)
      assert_raise Ecto.NoResultsError, fn -> Schools.get_student!(student.id) end
    end

    test "deactivate_student/1 sets deactivated_at for given student" do
      student = student_fixture()

      assert {:ok, %Student{deactivated_at: %DateTime{}}} =
               Schools.deactivate_student(student)
    end

    test "reactivate_student/1 sets deactivated_at to nil for given student" do
      student = student_fixture(%{deactivated_at: DateTime.utc_now()})

      assert {:ok, %Student{deactivated_at: nil}} =
               Schools.reactivate_student(student)
    end

    test "change_student/1 returns a student changeset" do
      student = student_fixture()
      assert %Ecto.Changeset{} = Schools.change_student(student)
    end

    test "list_students/1 with student_tags_ids opt returns students filtered by their tags" do
      # Create a school
      school = school_fixture()

      # Create tags
      tag_1 =
        Lanttern.StudentTagsFixtures.student_tag_fixture(%{school_id: school.id, name: "Tag 1"})

      tag_2 =
        Lanttern.StudentTagsFixtures.student_tag_fixture(%{school_id: school.id, name: "Tag 2"})

      # Create students with predictable alphabetical order
      student_a = student_fixture(%{school_id: school.id, name: "AAA Student with tag 1"})
      student_b = student_fixture(%{school_id: school.id, name: "BBB Student with tag 2"})
      student_c = student_fixture(%{school_id: school.id, name: "CCC Student with both tags"})
      _student_d = student_fixture(%{school_id: school.id, name: "DDD Student with no tags"})

      # Associate students with tags
      # Student A has tag 1
      Repo.insert!(%Lanttern.StudentTags.StudentTagRelationship{
        student_id: student_a.id,
        tag_id: tag_1.id,
        school_id: school.id
      })

      # Student B has tag 2
      Repo.insert!(%Lanttern.StudentTags.StudentTagRelationship{
        student_id: student_b.id,
        tag_id: tag_2.id,
        school_id: school.id
      })

      # Student C has both tags
      Repo.insert!(%Lanttern.StudentTags.StudentTagRelationship{
        student_id: student_c.id,
        tag_id: tag_1.id,
        school_id: school.id
      })

      Repo.insert!(%Lanttern.StudentTags.StudentTagRelationship{
        student_id: student_c.id,
        tag_id: tag_2.id,
        school_id: school.id
      })

      # Filter by tag 1 - should return student_a and student_c in alphabetical order
      [expected_student_a, expected_student_c] =
        Schools.list_students(student_tags_ids: [tag_1.id])

      assert expected_student_a.id == student_a.id
      assert expected_student_c.id == student_c.id

      # Filter by tag 2 - should return student_b and student_c in alphabetical order
      [expected_student_b, expected_student_c] =
        Schools.list_students(student_tags_ids: [tag_2.id])

      assert expected_student_b.id == student_b.id
      assert expected_student_c.id == student_c.id

      # Filter by both tags (should return students that have ANY of the tags)
      # Result should be in alphabetical order: student_a, student_b, student_c
      [expected_student_a, expected_student_b, expected_student_c] =
        Schools.list_students(student_tags_ids: [tag_1.id, tag_2.id])

      assert expected_student_a.id == student_a.id
      assert expected_student_b.id == student_b.id
      assert expected_student_c.id == student_c.id
    end
  end

  describe "staff" do
    alias Lanttern.Schools.StaffMember

    @invalid_attrs %{name: nil}

    test "list_staff_members/1 returns all staff members" do
      staff_member = staff_member_fixture()
      assert Schools.list_staff_members() == [staff_member]
    end

    test "list_staff_members/1 with school and staff_members_ids opts returns staff members filtered correctly" do
      school = school_fixture()
      staff_member_1 = staff_member_fixture(%{school_id: school.id, name: "AAA"})
      staff_member_2 = staff_member_fixture(%{school_id: school.id, name: "BBB"})

      # extra staff_member for filtering validation
      staff_member_fixture()
      staff_member_fixture(%{school_id: school.id})

      assert [staff_member_1, staff_member_2] ==
               Schools.list_staff_members(
                 school_id: school.id,
                 staff_members_ids: [staff_member_1.id, staff_member_2.id]
               )
    end

    test "list_staff_members/1 with opts returns all students as expected" do
      school = school_fixture()
      staff_member = staff_member_fixture(%{school_id: school.id})

      [expected_staff_member] = Schools.list_staff_members(preloads: :school)

      # assert school is preloaded
      assert expected_staff_member.id == staff_member.id
      assert expected_staff_member.school == school
    end

    test "list_staff_members/1 with load_email opt returns the staff members with its email" do
      staff_member_a = staff_member_fixture(%{name: "a"})
      staff_member_b = staff_member_fixture(%{name: "b"})

      # create user/profile only for staff_member_a
      user = Lanttern.IdentityFixtures.user_fixture(%{email: "a@email.com"})

      _profile =
        Lanttern.IdentityFixtures.staff_member_profile_fixture(%{
          user_id: user.id,
          staff_member_id: staff_member_a.id
        })

      [expected_staff_member_a, expected_staff_member_b] =
        Schools.list_staff_members(load_email: true)

      assert expected_staff_member_a.id == staff_member_a.id
      assert expected_staff_member_a.email == "a@email.com"
      assert expected_staff_member_b.id == staff_member_b.id
      assert is_nil(expected_staff_member_b.email)
    end

    test "list_staff_members/1 with only_active opt returns the staff members filtered by their deactivated status" do
      active_staff_member = staff_member_fixture()
      _deactivated_staff_member = staff_member_fixture(%{deactivated_at: DateTime.utc_now()})

      assert [active_staff_member] == Schools.list_staff_members(only_active: true)
    end

    test "list_staff_members/1 with only_deactivated opt returns the staff members filtered by their deactivated status" do
      deactivated_staff_member = staff_member_fixture(%{deactivated_at: DateTime.utc_now()})
      _active_staff_member = staff_member_fixture()

      assert [deactivated_staff_member] == Schools.list_staff_members(only_deactivated: true)
    end

    test "search_staff_members/2 returns all items matched by search" do
      _staff_member_1 = staff_member_fixture(%{name: "lorem ipsum xolor sit amet"})
      staff_member_2 = staff_member_fixture(%{name: "lorem ipsum dolor sit amet"})
      staff_member_3 = staff_member_fixture(%{name: "lorem ipsum dolorxxx sit amet"})
      _staff_member_4 = staff_member_fixture(%{name: "lorem ipsum xxxxx sit amet"})

      assert [staff_member_2, staff_member_3] == Schools.search_staff_members("dolor")
    end

    test "search_staff_members/2 with school opt returns only staff_members from given school" do
      school = school_fixture()

      _staff_member_1 = staff_member_fixture(%{name: "lorem ipsum xolor sit amet"})

      staff_member_2 =
        staff_member_fixture(%{name: "lorem ipsum dolor sit amet", school_id: school.id})

      _staff_member_3 = staff_member_fixture(%{name: "lorem ipsum dolorxxx sit amet"})
      _staff_member_4 = staff_member_fixture(%{name: "lorem ipsum xxxxx sit amet"})

      assert [staff_member_2] == Schools.search_staff_members("dolor", school_id: school.id)
    end

    test "get_staff_member!/1 returns the staff member with given id" do
      staff_member = staff_member_fixture()
      assert Schools.get_staff_member!(staff_member.id) == staff_member
    end

    test "get_staff_member!/2 with load_email opt returns the staff member with its email" do
      user = Lanttern.IdentityFixtures.user_fixture(%{email: "email.abc@email.com"})

      profile =
        Lanttern.IdentityFixtures.staff_member_profile_fixture(%{user_id: user.id})

      expected_staff_member = Schools.get_staff_member!(profile.staff_member_id, load_email: true)
      assert expected_staff_member.id == profile.staff_member_id
      assert expected_staff_member.email == "email.abc@email.com"
    end

    test "get_staff_member!/2 with preloads returns the staff member with given id and preloaded data" do
      school = school_fixture()
      staff_member = staff_member_fixture(%{school_id: school.id})

      expected_staff_member = Schools.get_staff_member!(staff_member.id, preloads: :school)
      assert expected_staff_member.id == staff_member.id
      assert expected_staff_member.school == school
    end

    test "create_staff_member/1 with valid data creates a staff member" do
      school = school_fixture()
      valid_attrs = %{school_id: school.id, name: "some name"}

      assert {:ok, %StaffMember{} = staff_member} = Schools.create_staff_member(valid_attrs)
      assert staff_member.name == "some name"
    end

    test "create_staff_member/1 with email creates a staff member linked to new profile/user" do
      school = school_fixture()

      valid_attrs = %{
        "school_id" => school.id,
        "name" => "some name",
        "email" => "some@email.com"
      }

      {:ok, %StaffMember{} = staff_member} = Schools.create_staff_member(valid_attrs)
      assert staff_member.name == "some name"
      assert staff_member.email == "some@email.com"

      staff_member_with_preloads =
        Schools.get_staff_member!(staff_member.id, preloads: [profile: :user])

      assert staff_member_with_preloads.profile.user.email == "some@email.com"
    end

    test "create_staff_member/1 with email creates a staff member linked to new profile and existing user" do
      school = school_fixture()
      user = Lanttern.IdentityFixtures.user_fixture(email: "some@email.com")

      valid_attrs = %{
        "school_id" => school.id,
        "name" => "some name",
        "email" => "some@email.com"
      }

      {:ok, %StaffMember{} = staff_member} = Schools.create_staff_member(valid_attrs)
      assert staff_member.name == "some name"
      assert staff_member.email == "some@email.com"

      staff_member_with_preloads =
        Schools.get_staff_member!(staff_member.id, preloads: [profile: :user])

      assert staff_member_with_preloads.profile.user.id == user.id
    end

    test "create_staff_member/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Schools.create_staff_member(@invalid_attrs)
    end

    test "update_staff_member/2 with valid data updates the staff member" do
      staff_member = staff_member_fixture()
      update_attrs = %{name: "some updated name"}

      {:ok, %StaffMember{} = staff_member} =
        Schools.update_staff_member(staff_member, update_attrs)

      assert staff_member.name == "some updated name"
    end

    test "update_staff_member/2 with email links to new profile/user" do
      staff_member = staff_member_fixture()

      update_attrs = %{
        "name" => "some updated name",
        "email" => "some@email.com"
      }

      {:ok, %StaffMember{} = staff_member} =
        Schools.update_staff_member(staff_member, update_attrs)

      assert staff_member.name == "some updated name"
      assert staff_member.email == "some@email.com"

      staff_member_with_preloads =
        Schools.get_staff_member!(staff_member.id, preloads: [profile: :user])

      assert staff_member_with_preloads.profile.user.email == "some@email.com"
    end

    test "update_staff_member/2 with email links to new profile and existing user" do
      staff_member = staff_member_fixture()
      user = Lanttern.IdentityFixtures.user_fixture(email: "some@email.com")

      update_attrs = %{
        "name" => "some updated name",
        "email" => "some@email.com"
      }

      {:ok, %StaffMember{} = staff_member} =
        Schools.update_staff_member(staff_member, update_attrs)

      assert staff_member.name == "some updated name"
      assert staff_member.email == "some@email.com"

      staff_member_with_preloads =
        Schools.get_staff_member!(staff_member.id, preloads: [profile: :user])

      assert staff_member_with_preloads.profile.user.id == user.id
    end

    test "update_staff_member/2 with email and existing profile relinks the profile to new user" do
      staff_member = staff_member_fixture(%{email: "some@email.com"})

      %{profile: %{user: user} = profile} =
        Schools.get_staff_member!(staff_member.id, preloads: [profile: :user])

      update_attrs = %{
        "name" => "some updated name",
        "email" => "new@email.com"
      }

      {:ok, %StaffMember{} = staff_member} =
        Schools.update_staff_member(staff_member, update_attrs)

      assert staff_member.name == "some updated name"
      assert staff_member.email == "new@email.com"

      staff_member_with_preloads =
        Schools.get_staff_member!(staff_member.id, preloads: [profile: :user])

      # assert new user and same profile
      assert staff_member_with_preloads.profile.user.id != user.id
      assert staff_member_with_preloads.profile.user.email == "new@email.com"
      assert staff_member_with_preloads.profile.id == profile.id

      # assert old user already exists
      assert %Lanttern.Identity.User{} = Repo.get(Lanttern.Identity.User, user.id)
    end

    test "update_staff_member/2 with empty email deletes the linked profile" do
      staff_member = staff_member_fixture(%{email: "some@email.com"})

      %{profile: %{user: user} = profile} =
        Schools.get_staff_member!(staff_member.id, preloads: [profile: :user])

      update_attrs = %{
        "name" => "some updated name",
        "email" => ""
      }

      {:ok, %StaffMember{} = staff_member} =
        Schools.update_staff_member(staff_member, update_attrs)

      assert staff_member.name == "some updated name"
      assert is_nil(staff_member.email)

      # assert staff member is not linked to any profile
      assert %{profile: nil} =
               Schools.get_staff_member!(staff_member.id, preloads: [profile: :user])

      # assert profile is deleted
      assert is_nil(Repo.get(Lanttern.Identity.Profile, profile.id))

      # assert user already exists
      assert %Lanttern.Identity.User{} = Repo.get(Lanttern.Identity.User, user.id)
    end

    test "update_staff_member/2 with invalid data returns error changeset" do
      staff_member = staff_member_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Schools.update_staff_member(staff_member, @invalid_attrs)

      assert staff_member == Schools.get_staff_member!(staff_member.id)
    end

    test "delete_staff_member/1 deletes the staff member" do
      staff_member = staff_member_fixture()
      assert {:ok, %StaffMember{}} = Schools.delete_staff_member(staff_member)
      assert_raise Ecto.NoResultsError, fn -> Schools.get_staff_member!(staff_member.id) end
    end

    test "deactivate_staff_member/1 sets deactivated_at for given staff member" do
      staff_member = staff_member_fixture()

      assert {:ok, %StaffMember{deactivated_at: %DateTime{}}} =
               Schools.deactivate_staff_member(staff_member)
    end

    test "reactivate_staff_member/1 sets deactivated_at to nil for given staff member" do
      staff_member = staff_member_fixture(%{deactivated_at: DateTime.utc_now()})

      assert {:ok, %StaffMember{deactivated_at: nil}} =
               Schools.reactivate_staff_member(staff_member)
    end

    test "change_staff_member/1 returns a staff member changeset" do
      staff_member = staff_member_fixture()
      assert %Ecto.Changeset{} = Schools.change_staff_member(staff_member)
    end
  end

  describe "csv parsing" do
    test "create_students_from_csv/3 creates classes and students, and returns a list with the registration status for each row" do
      school = school_fixture()
      cycle = cycle_fixture(%{school_id: school.id})
      class = class_fixture(name: "existing class", school_id: school.id, cycle_id: cycle.id)
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
        Schools.create_students_from_csv(csv_students, class_name_id_map, school.id, cycle.id)

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

    test "create_staff_members_from_csv/2 creates staff members, and returns a list with the registration status for each row" do
      school = school_fixture()
      user = Lanttern.IdentityFixtures.user_fixture(email: "existing-user@school.com")

      csv_staff_member_1 = %{
        name: "Teacher A",
        email: "teacher-a@school.com"
      }

      csv_staff_member_2 = %{
        name: "Teacher A same user",
        email: "teacher-a@school.com"
      }

      csv_staff_member_3 = %{
        name: "With existing user email",
        email: "existing-user@school.com"
      }

      csv_staff_member_4 = %{
        name: "No email",
        email: ""
      }

      csv_staff_member_5 = %{
        name: "",
        email: "teacher-x@school.com"
      }

      csv_staff_members = [
        csv_staff_member_1,
        csv_staff_member_2,
        csv_staff_member_3,
        csv_staff_member_4,
        csv_staff_member_5
      ]

      {:ok, expected} =
        Schools.create_staff_members_from_csv(csv_staff_members, school.id)

      [
        {returned_csv_staff_member_1, {:ok, teacher_1}},
        {returned_csv_staff_member_2, {:ok, teacher_2}},
        {returned_csv_staff_member_3, {:ok, teacher_3}},
        {returned_csv_staff_member_4, {:ok, teacher_4}},
        {returned_csv_staff_member_5, {:error, _error}}
      ] = expected

      # assert students and classes

      assert returned_csv_staff_member_1.name == csv_staff_member_1.name
      assert teacher_1.name == csv_staff_member_1.name
      assert get_user(teacher_1.id, "staff")

      assert returned_csv_staff_member_2.name == csv_staff_member_2.name
      assert teacher_2.name == csv_staff_member_2.name
      assert get_user(teacher_2.id, "staff")

      assert get_user(teacher_1.id, "staff") == get_user(teacher_2.id, "staff")

      assert returned_csv_staff_member_3.name == csv_staff_member_3.name
      assert teacher_3.name == csv_staff_member_3.name
      assert get_user(teacher_3.id, "staff").id == user.id

      assert returned_csv_staff_member_4.name == csv_staff_member_4.name
      assert teacher_4.name == csv_staff_member_4.name
      refute get_user(teacher_4.id, "staff")

      assert returned_csv_staff_member_5.name == csv_staff_member_5.name
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

    defp get_user(id, "staff") do
      from(t in Schools.StaffMember,
        left_join: p in Lanttern.Identity.Profile,
        on: p.staff_member_id == t.id,
        left_join: u in Lanttern.Identity.User,
        on: u.id == p.user_id,
        where: t.id == ^id,
        select: u
      )
      |> Lanttern.Repo.one!()
    end
  end

  describe "guardians" do
    alias Lanttern.Schools.Guardian

    @invalid_attrs %{name: nil, school_id: nil}

    test "list_guardians/1 returns all guardians" do
      scope = scope_fixture(permissions: ["school_management"])
      guardian = insert(:guardian, school_id: scope.school_id)
      assert Schools.list_guardians(scope) == [guardian]
    end

    test "list_guardians/1 with school_id filter returns only guardians from that school" do
      school_1 = school_fixture()
      school_2 = school_fixture()

      guardian_1 = insert(:guardian, school_id: school_1.id)
      _guardian_2 = insert(:guardian, school_id: school_2.id)

      scope_1 = scope_fixture(permissions: ["school_management"])
      scope_1 = %{scope_1 | school_id: school_1.id}

      assert [guardian_1] == Schools.list_guardians(scope_1)
    end

    test "get_guardian!/1 returns the guardian with given id" do
      scope = scope_fixture(permissions: ["school_management"])
      guardian = insert(:guardian, school_id: scope.school_id)
      assert Schools.get_guardian!(scope, guardian.id) == guardian
    end

    test "get_guardian/2 returns the guardian with given id" do
      scope = scope_fixture(permissions: ["school_management"])
      guardian = insert(:guardian, school_id: scope.school_id)
      assert Schools.get_guardian(scope, guardian.id) == guardian
    end

    test "get_guardian/2 with preloads returns the guardian with preloaded associations" do
      scope = scope_fixture(permissions: ["school_management"])
      guardian = insert(:guardian, school_id: scope.school_id)
      result = Schools.get_guardian(scope, guardian.id, preloads: [:school])

      assert result.id == guardian.id
      assert %Lanttern.Schools.School{} = result.school
    end

    test "create_guardian/1 with valid data creates a guardian" do
      scope = scope_fixture(permissions: ["school_management"])
      valid_attrs = %{name: "John Doe"}

      assert {:ok, %Guardian{} = guardian} = Schools.create_guardian(scope, valid_attrs)
      assert guardian.name == "John Doe"
      assert guardian.school_id == scope.school_id
    end

    test "create_guardian/1 with invalid data returns error changeset" do
      scope = scope_fixture(permissions: ["school_management"])
      assert {:error, %Ecto.Changeset{}} = Schools.create_guardian(scope, @invalid_attrs)
    end

    test "update_guardian/2 with valid data updates the guardian" do
      scope = scope_fixture(permissions: ["school_management"])
      guardian = insert(:guardian, school_id: scope.school_id)
      update_attrs = %{name: "Jane Doe"}

      assert {:ok, %Guardian{} = guardian} =
               Schools.update_guardian(scope, guardian, update_attrs)

      assert guardian.name == "Jane Doe"
    end

    test "update_guardian/2 with invalid data returns error changeset" do
      scope = scope_fixture(permissions: ["school_management"])
      guardian = insert(:guardian, school_id: scope.school_id)

      assert {:error, %Ecto.Changeset{}} =
               Schools.update_guardian(scope, guardian, @invalid_attrs)

      assert guardian == Schools.get_guardian!(scope, guardian.id)
    end

    test "delete_guardian/1 deletes the guardian" do
      scope = scope_fixture(permissions: ["school_management"])
      guardian = insert(:guardian, school_id: scope.school_id)
      assert {:ok, %Guardian{}} = Schools.delete_guardian(scope, guardian)
      assert_raise Ecto.NoResultsError, fn -> Schools.get_guardian!(scope, guardian.id) end
    end

    test "change_guardian/1 returns a guardian changeset" do
      scope = scope_fixture(permissions: ["school_management"])
      guardian = insert(:guardian, school_id: scope.school_id)
      assert %Ecto.Changeset{} = Schools.change_guardian(scope, guardian)
    end

    test "get_guardian!/2 with preloads returns the guardian with preloaded associations" do
      scope = scope_fixture(permissions: ["school_management"])
      guardian = insert(:guardian, school_id: scope.school_id)
      result = Schools.get_guardian!(scope, guardian.id, preloads: [:school])

      assert result.id == guardian.id
      assert %Lanttern.Schools.School{} = result.school
    end

    test "get_guardian/2 with students preload returns guardian with students" do
      scope = scope_fixture(permissions: ["school_management"])
      guardian = insert(:guardian, school_id: scope.school_id)
      student = student_fixture(%{school_id: guardian.school_id})

      # Link student to guardian via students_guardians table
      Lanttern.Repo.insert_all("students_guardians", [
        %{student_id: student.id, guardian_id: guardian.id}
      ])

      result = Schools.get_guardian(scope, guardian.id, preloads: [:students])

      assert result.id == guardian.id
      assert length(result.students) == 1
      assert hd(result.students).id == student.id
    end

    test "delete_guardian/1 removes associated students_guardians but keeps students" do
      scope = scope_fixture(permissions: ["school_management"])
      guardian = insert(:guardian, school_id: scope.school_id)
      student = student_fixture(%{school_id: guardian.school_id})

      # Link student to guardian
      Lanttern.Repo.insert_all("students_guardians", [
        %{student_id: student.id, guardian_id: guardian.id}
      ])

      # Verify relationship exists
      assert Lanttern.Repo.one(
               from sg in "students_guardians",
                 where: sg.student_id == ^student.id and sg.guardian_id == ^guardian.id,
                 select: 1
             ) == 1

      # Delete guardian
      assert {:ok, %Guardian{}} = Schools.delete_guardian(scope, guardian)

      # Verify guardian is deleted
      assert_raise Ecto.NoResultsError, fn -> Schools.get_guardian!(scope, guardian.id) end

      # Verify relationship is removed (cascade delete)
      assert Lanttern.Repo.one(
               from sg in "students_guardians",
                 where: sg.student_id == ^student.id and sg.guardian_id == ^guardian.id,
                 select: 1
             ) == nil

      # Verify student still exists
      assert Schools.get_student!(student.id)
    end

    test "create_guardian/1 requires school_id (via scope)" do
      scope = scope_fixture(permissions: ["school_management"])
      {:ok, guardian} = Schools.create_guardian(scope, %{name: "Test Guardian"})
      assert guardian.school_id == scope.school_id
    end

    test "create_guardian/1 requires name" do
      scope = scope_fixture(permissions: ["school_management"])
      result = Schools.create_guardian(scope, %{})
      assert {:error, changeset} = result
      assert "can't be blank" in errors_on(changeset).name
    end

    test "list_guardians/1 returns empty list when no guardians exist" do
      scope = scope_fixture(permissions: ["school_management"])
      assert Schools.list_guardians(scope) == []
    end

    test "list_guardians/1 with non-existent school_id returns empty list" do
      _guardian = insert(:guardian)
      scope = scope_fixture(permissions: ["school_management"])
      scope = %{scope | school_id: -1}
      assert Schools.list_guardians(scope) == []
    end

    test "get_guardian/2 returns nil for non-existent id" do
      scope = scope_fixture(permissions: ["school_management"])
      assert Schools.get_guardian(scope, -1) == nil
    end

    test "search_guardians/2 returns all items matched by search" do
      school = school_fixture()

      _guardian_1 = insert(:guardian, school_id: school.id, name: "lorem ipsum xolor sit amet")
      guardian_2 = insert(:guardian, school_id: school.id, name: "lorem ipsum dolor sit amet")
      guardian_3 = insert(:guardian, school_id: school.id, name: "lorem ipsum dolorxxx sit amet")
      _guardian_4 = insert(:guardian, school_id: school.id, name: "lorem ipsum xxxxx sit amet")

      assert [guardian_2, guardian_3] ==
               Schools.search_guardians("dolor", school_id: school.id)
    end

    test "search_guardians/2 with school_id filter returns only guardians from given school" do
      school_1 = school_fixture()
      school_2 = school_fixture()

      _guardian_1 = insert(:guardian, school_id: school_1.id, name: "lorem ipsum xolor sit amet")
      guardian_2 = insert(:guardian, school_id: school_1.id, name: "lorem ipsum dolor sit amet")
      _guardian_3 = insert(:guardian, school_id: school_2.id, name: "lorem ipsum dolorxxx sit amet")
      _guardian_4 = insert(:guardian, school_id: school_2.id, name: "lorem ipsum xxxxx sit amet")

      assert [guardian_2] ==
               Schools.search_guardians("dolor", school_id: school_1.id)
    end

    test "search_guardians/2 with non-matching query returns empty list" do
      school = school_fixture()
      _guardian = insert(:guardian, school_id: school.id, name: "John Doe")

      assert [] ==
               Schools.search_guardians("xyz", school_id: school.id)
    end
  end
end
