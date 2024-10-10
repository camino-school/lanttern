defmodule LantternWeb.StudentRecordLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.SchoolsFixtures
  alias Lanttern.StudentsRecordsFixtures

  @live_view_base_path "/students_records"

  setup [:register_and_log_in_teacher]

  describe "Student record live view basic navigation" do
    setup [:register_and_log_in_teacher, :add_wcd_permissions]

    test "disconnected and connected mount", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id

      student_record =
        StudentsRecordsFixtures.student_record_fixture(%{
          school_id: school_id,
          name: "student record abc"
        })

      conn = get(conn, "#{@live_view_base_path}/#{student_record.id}")
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*student record abc\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "view student record", %{conn: conn, user: user} do
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
          name: "student record abc",
          description: "student record desc",
          school_id: school_id,
          students_ids: [student.id],
          type_id: type.id,
          status_id: status.id
        })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{student_record.id}")

      assert view |> has_element?("h1", student_record.name)
      assert view |> has_element?("span", student.name)
      assert view |> has_element?("p", student_record.description)
      assert view |> has_element?("span", type.name)
      assert view |> has_element?("span", status.name)
    end
  end

  describe "Student record live school-based access" do
    setup [:register_and_log_in_teacher, :add_wcd_permissions]

    test "view records from other schools is not allowed", %{conn: conn} do
      student_record = StudentsRecordsFixtures.student_record_fixture()

      assert_raise(LantternWeb.NotFoundError, fn ->
        live(conn, "#{@live_view_base_path}/#{student_record.id}")
      end)
    end
  end

  describe "Student record live permissions-based access" do
    setup [:register_and_log_in_teacher]

    test "user without wcd permission is not allowed to access student record", %{
      conn: conn,
      user: user
    } do
      school_id = user.current_profile.school_id

      student_record =
        StudentsRecordsFixtures.student_record_fixture(%{school_id: school_id})

      assert_raise(LantternWeb.NotFoundError, fn ->
        live(conn, "#{@live_view_base_path}/#{student_record.id}")
      end)
    end
  end
end
