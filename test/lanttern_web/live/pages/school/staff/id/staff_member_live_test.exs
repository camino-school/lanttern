defmodule LantternWeb.StaffMemberLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.SchoolsFixtures

  @live_view_base_path "/school/staff"

  setup [:register_and_log_in_staff_member]

  describe "Staff member live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id

      staff_member =
        SchoolsFixtures.staff_member_fixture(%{
          school_id: school_id,
          name: "some staff member abc xyz"
        })

      conn = get(conn, "#{@live_view_base_path}/#{staff_member.id}")

      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*some staff member abc xyz\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end
  end

  describe "Staff member management permissions" do
    test "allow user with school management permissions to edit staff member", context do
      %{conn: conn, user: user} = add_school_management_permissions(context)
      school_id = user.current_profile.school_id

      staff_member =
        SchoolsFixtures.staff_member_fixture(%{school_id: school_id, name: "staff member abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{staff_member.id}?edit=true")

      assert view |> has_element?("#staff-member-form-overlay h2", "Edit staff member")
    end

    test "allow user without school management permissions to edit their own staff member", %{
      conn: conn,
      user: user
    } do
      {:ok, view, _html} =
        live(conn, "#{@live_view_base_path}/#{user.current_profile.staff_member.id}?edit=true")

      assert view |> has_element?("#staff-member-form-overlay h2", "Edit staff member")
    end

    test "prevent user without school management permissions to edit staff member", %{
      conn: conn,
      user: user
    } do
      school_id = user.current_profile.school_id

      staff_member =
        SchoolsFixtures.staff_member_fixture(%{school_id: school_id, name: "staff member abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{staff_member.id}?edit=true")

      refute view |> has_element?("#staff-member-form-overlay h2", "Edit staff member")
    end
  end

  describe "Students records live view access" do
    alias Lanttern.StudentsRecordsFixtures

    test "user without full access can access only its own records, records shared with school, or records assigned to them",
         %{conn: conn, user: user} do
      %{staff_member_id: staff_member_id, school_id: school_id} = user.current_profile
      student = SchoolsFixtures.student_fixture(%{school_id: school_id, name: "std abc"})
      other_staff_member = SchoolsFixtures.staff_member_fixture(%{school_id: school_id})

      assigned_student_record =
        StudentsRecordsFixtures.student_record_fixture(%{
          created_by_staff_member_id: other_staff_member.id,
          name: "assigned student record",
          description: "assigned student record desc",
          school_id: school_id,
          students_ids: [student.id],
          assignees_ids: [staff_member_id]
        })

      shared_student_record =
        StudentsRecordsFixtures.student_record_fixture(%{
          created_by_staff_member_id: other_staff_member.id,
          name: "shared student record",
          description: "shared student record desc",
          school_id: school_id,
          students_ids: [student.id],
          shared_with_school: true
        })

      closed_student_record =
        StudentsRecordsFixtures.student_record_fixture(%{
          created_by_staff_member_id: other_staff_member.id,
          name: "closed student record",
          description: "closed student record desc",
          school_id: school_id,
          students_ids: [student.id]
        })

      {:ok, view, _html} =
        live(
          conn,
          "#{@live_view_base_path}/#{other_staff_member.id}/students_records"
        )

      assert view |> has_element?("span", student.name)

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
      other_staff_member = SchoolsFixtures.staff_member_fixture(%{school_id: school_id})

      closed_student_record =
        StudentsRecordsFixtures.student_record_fixture(%{
          created_by_staff_member_id: other_staff_member.id,
          name: "closed student record",
          description: "closed student record desc",
          school_id: school_id,
          students_ids: [student.id]
        })

      {:ok, view, _html} =
        live(
          conn,
          "#{@live_view_base_path}/#{other_staff_member.id}/students_records"
        )

      assert view |> has_element?("span", student.name)
      assert view |> has_element?("a", closed_student_record.name)
      assert view |> has_element?("p", closed_student_record.description)
    end
  end
end
