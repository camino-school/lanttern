defmodule LantternWeb.StudentLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.SchoolsFixtures
  alias Lanttern.StudentsCycleInfo
  alias Lanttern.StudentsCycleInfoFixtures

  @live_view_base_path "/school/students"

  setup [:register_and_log_in_staff_member]

  describe "Student live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id

      student =
        SchoolsFixtures.student_fixture(%{school_id: school_id, name: "some student abc xyz"})

      conn = get(conn, "#{@live_view_base_path}/#{student.id}")

      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*some student abc xyz\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "list classes", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      cycle_id = user.current_profile.current_school_cycle.id

      class_b =
        SchoolsFixtures.class_fixture(%{school_id: school_id, name: "bbb", cycle_id: cycle_id})

      class_a =
        SchoolsFixtures.class_fixture(%{school_id: school_id, name: "aaa", cycle_id: cycle_id})

      student =
        SchoolsFixtures.student_fixture(%{
          school_id: school_id,
          classes_ids: [class_a.id, class_b.id]
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{student.id}")

      assert view |> has_element?("span", class_a.name)
      assert view |> has_element?("span", class_b.name)
    end
  end

  describe "Student management permissions" do
    test "allow user with school management permissions to edit student", context do
      %{conn: conn, user: user} = add_school_management_permissions(context)
      school_id = user.current_profile.school_id
      student = SchoolsFixtures.student_fixture(%{school_id: school_id, name: "student abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{student.id}?edit=true")

      assert view |> has_element?("#student-form-overlay h2", "Edit student")
    end

    test "prevent user without school management permissions to edit staff member", %{
      conn: conn,
      user: user
    } do
      school_id = user.current_profile.school_id
      student = SchoolsFixtures.student_fixture(%{school_id: school_id, name: "student abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{student.id}?edit=true")

      refute view |> has_element?("#student-form-overlay h2", "Edit student")
    end
  end

  describe "student cycle info" do
    test "student cycle info is created when there's none", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      student = SchoolsFixtures.student_fixture(%{school_id: school_id})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{student.id}")

      assert view |> has_element?("p", "No information about student in school area")
      assert view |> has_element?("p", "No information in student area")
    end

    test "student cycle info displays correctly", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      student = SchoolsFixtures.student_fixture(%{school_id: school_id})

      student_cycle_info =
        StudentsCycleInfoFixtures.student_cycle_info_fixture(%{
          school_id: school_id,
          student_id: student.id,
          cycle_id: user.current_profile.current_school_cycle.id,
          school_info: "some school info"
        })

      StudentsCycleInfo.create_student_cycle_info_attachment(
        user.current_profile_id,
        student_cycle_info.id,
        %{
          "name" => "some attachment",
          "link" => "https://somevaliduri.com",
          "is_external" => true
        },
        true
      )

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{student.id}")

      assert view |> has_element?("p", "some school info")

      view
      |> element("a", "some attachment")
      |> render_click()

      assert_redirect(view, "https://somevaliduri.com")
    end
  end

  describe "Students records live view access" do
    alias Lanttern.StudentsRecordsFixtures

    test "user without full access can access only its own records, records shared with school, or records assigned to them",
         %{conn: conn, user: user} do
      %{staff_member_id: staff_member_id, school_id: school_id} = user.current_profile
      student = SchoolsFixtures.student_fixture(%{school_id: school_id, name: "std abc"})

      own_student_record =
        StudentsRecordsFixtures.student_record_fixture(%{
          created_by_staff_member_id: staff_member_id,
          name: "my student record",
          description: "my student record desc",
          school_id: school_id,
          students_ids: [student.id]
        })

      assigned_student_record =
        StudentsRecordsFixtures.student_record_fixture(%{
          name: "assigned student record",
          description: "assigned student record desc",
          school_id: school_id,
          students_ids: [student.id],
          assignees_ids: [staff_member_id]
        })

      shared_student_record =
        StudentsRecordsFixtures.student_record_fixture(%{
          name: "shared student record",
          description: "shared student record desc",
          school_id: school_id,
          students_ids: [student.id],
          shared_with_school: true
        })

      closed_student_record =
        StudentsRecordsFixtures.student_record_fixture(%{
          name: "closed student record",
          description: "closed student record desc",
          school_id: school_id,
          students_ids: [student.id]
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{student.id}/student_records")

      assert view |> has_element?("span", student.name)

      assert view |> has_element?("a", own_student_record.name)
      assert view |> has_element?("p", own_student_record.description)

      assert view |> has_element?("a", assigned_student_record.name)
      assert view |> has_element?("p", assigned_student_record.description)

      assert view |> has_element?("a", shared_student_record.name)
      assert view |> has_element?("p", shared_student_record.description)

      refute view |> has_element?("a", closed_student_record.name)
      refute view |> has_element?("p", closed_student_record.description)
    end

    test "user with full access can access any record from the school", context do
      %{conn: conn, user: user} = add_students_records_full_access_permissions(context)

      %{school_id: school_id} = user.current_profile
      student = SchoolsFixtures.student_fixture(%{school_id: school_id, name: "std abc"})

      closed_student_record =
        StudentsRecordsFixtures.student_record_fixture(%{
          name: "closed student record",
          description: "closed student record desc",
          school_id: school_id,
          students_ids: [student.id]
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{student.id}/student_records")

      assert view |> has_element?("span", student.name)
      assert view |> has_element?("a", closed_student_record.name)
      assert view |> has_element?("p", closed_student_record.description)
    end
  end
end
