defmodule LantternWeb.StudentsRecordsLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.SchoolsFixtures
  alias Lanttern.StudentsRecordsFixtures

  @live_view_base_path "/students_records"

  setup [:register_and_log_in_staff_member]

  describe "Students records live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_base_path)
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*Students records\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "list students records", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      student = SchoolsFixtures.student_fixture(%{school_id: school_id, name: "std abc"})

      type =
        StudentsRecordsFixtures.student_record_type_fixture(%{
          school_id: school_id,
          name: "type abc"
        })

      status =
        StudentsRecordsFixtures.student_record_status_fixture(%{
          school_id: school_id,
          name: "status abc"
        })

      student_record =
        StudentsRecordsFixtures.student_record_fixture(%{
          created_by_staff_member_id: user.current_profile.staff_member_id,
          name: "student record abc",
          description: "student record desc",
          school_id: school_id,
          students_ids: [student.id],
          type_id: type.id,
          status_id: status.id
        })

      {:ok, view, _html} = live(conn, @live_view_base_path)

      assert view |> has_element?("span", student.name)
      assert view |> has_element?("a", student_record.name)
      assert view |> has_element?("p", student_record.description)
      assert view |> has_element?("span", type.name)
      assert view |> has_element?("span", status.name)
    end
  end

  describe "Students records live view access" do
    test "user (even with full access) can't access records from other schools", context do
      %{conn: conn} = add_students_records_full_access_permissions(context)

      student = SchoolsFixtures.student_fixture(%{name: "std abc"})

      student_record =
        StudentsRecordsFixtures.student_record_fixture(%{
          name: "student record abc",
          description: "student record desc",
          school_id: student.school_id,
          students_ids: [student.id]
        })

      {:ok, view, _html} = live(conn, @live_view_base_path)

      refute view |> has_element?("span", student.name)
      refute view |> has_element?("a", student_record.name)
      refute view |> has_element?("p", student_record.description)
    end

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

      {:ok, view, _html} = live(conn, @live_view_base_path)

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

      {:ok, view, _html} = live(conn, @live_view_base_path)

      assert view |> has_element?("span", student.name)
      assert view |> has_element?("a", closed_student_record.name)
      assert view |> has_element?("p", closed_student_record.description)
    end
  end

  describe "Student record details" do
    test "user (even with full access) can't access records from other schools", context do
      %{conn: conn} = add_students_records_full_access_permissions(context)

      student = SchoolsFixtures.student_fixture(%{name: "std abc"})

      student_record =
        StudentsRecordsFixtures.student_record_fixture(%{
          name: "student record abc",
          description: "student record desc",
          school_id: student.school_id,
          students_ids: [student.id]
        })

      {:ok, view, _html} =
        live(conn, "#{@live_view_base_path}?student_record=#{student_record.id}")

      refute view |> has_element?("#student-record-overlay h5", student_record.name)
      refute view |> has_element?("#student-record-overlay span", student.name)
      refute view |> has_element?("#student-record-overlay p", student_record.description)
    end

    test "user without full access can't access records not shared with school, not created by or not assigned to them",
         %{conn: conn, user: user} do
      %{school_id: school_id} = user.current_profile
      student = SchoolsFixtures.student_fixture(%{school_id: school_id, name: "std abc"})

      student_record =
        StudentsRecordsFixtures.student_record_fixture(%{
          name: "shared student record",
          description: "shared student record desc",
          school_id: school_id,
          students_ids: [student.id]
        })

      {:ok, view, _html} =
        live(conn, "#{@live_view_base_path}?student_record=#{student_record.id}")

      refute view |> has_element?("#student-record-overlay h5", student_record.name)
      refute view |> has_element?("#student-record-overlay span", student.name)
      refute view |> has_element?("#student-record-overlay p", student_record.description)
    end

    test "user without full access can access their own records", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      student = SchoolsFixtures.student_fixture(%{school_id: school_id, name: "std abc"})

      type =
        StudentsRecordsFixtures.student_record_type_fixture(%{
          school_id: school_id,
          name: "type abc"
        })

      status =
        StudentsRecordsFixtures.student_record_status_fixture(%{
          school_id: school_id,
          name: "status abc"
        })

      student_record =
        StudentsRecordsFixtures.student_record_fixture(%{
          created_by_staff_member_id: user.current_profile.staff_member_id,
          name: "student record abc",
          description: "student record desc",
          school_id: school_id,
          students_ids: [student.id],
          type_id: type.id,
          status_id: status.id
        })

      {:ok, view, _html} =
        live(conn, "#{@live_view_base_path}?student_record=#{student_record.id}")

      assert view |> has_element?("#student-record-overlay h5", student_record.name)
      assert view |> has_element?("#student-record-overlay span", student.name)
      assert view |> has_element?("#student-record-overlay p", student_record.description)
      assert view |> has_element?("#student-record-overlay span", type.name)
      assert view |> has_element?("#student-record-overlay span", status.name)
    end

    test "user without full access can access records shared with school",
         %{conn: conn, user: user} do
      %{school_id: school_id} = user.current_profile
      student = SchoolsFixtures.student_fixture(%{school_id: school_id, name: "std abc"})

      student_record =
        StudentsRecordsFixtures.student_record_fixture(%{
          name: "shared student record",
          description: "shared student record desc",
          school_id: school_id,
          students_ids: [student.id],
          shared_with_school: true
        })

      {:ok, view, _html} =
        live(conn, "#{@live_view_base_path}?student_record=#{student_record.id}")

      assert view |> has_element?("#student-record-overlay h5", student_record.name)
      assert view |> has_element?("#student-record-overlay span", student.name)
      assert view |> has_element?("#student-record-overlay p", student_record.description)
    end

    test "user without full access can access records assigned to them",
         %{conn: conn, user: user} do
      %{staff_member_id: staff_member_id, school_id: school_id} = user.current_profile
      student = SchoolsFixtures.student_fixture(%{school_id: school_id, name: "std abc"})

      student_record =
        StudentsRecordsFixtures.student_record_fixture(%{
          name: "assigned student record",
          description: "assigned student record desc",
          school_id: school_id,
          students_ids: [student.id],
          assignees_ids: [staff_member_id]
        })

      {:ok, view, _html} =
        live(conn, "#{@live_view_base_path}?student_record=#{student_record.id}")

      assert view |> has_element?("#student-record-overlay h5", student_record.name)
      assert view |> has_element?("#student-record-overlay span", student.name)
      assert view |> has_element?("#student-record-overlay p", student_record.description)
    end

    test "user with full access can access any record from the school", context do
      %{conn: conn, user: user} = add_students_records_full_access_permissions(context)

      %{school_id: school_id} = user.current_profile
      student = SchoolsFixtures.student_fixture(%{school_id: school_id, name: "std abc"})

      student_record =
        StudentsRecordsFixtures.student_record_fixture(%{
          name: "closed student record",
          description: "closed student record desc",
          school_id: school_id,
          students_ids: [student.id]
        })

      {:ok, view, _html} =
        live(conn, "#{@live_view_base_path}?student_record=#{student_record.id}")

      assert view |> has_element?("#student-record-overlay h5", student_record.name)
      assert view |> has_element?("#student-record-overlay span", student.name)
      assert view |> has_element?("#student-record-overlay p", student_record.description)
    end
  end
end
