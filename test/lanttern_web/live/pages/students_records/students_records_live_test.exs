defmodule LantternWeb.StudentsRecordsLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.SchoolsFixtures
  alias Lanttern.StudentsRecordsFixtures

  @live_view_base_path "/students_records"

  describe "Students records live view basic navigation" do
    setup [:register_and_log_in_staff_member]

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

  # todo: replace with a test that lists the students records the user has access to
  # describe "Students records live view access" do
  #   setup [:register_and_log_in_staff_member]

  #   test "user without wcd permission is not allowed to access students records", %{conn: conn} do
  #     assert_raise(LantternWeb.NotFoundError, fn -> live(conn, @live_view_base_path) end)
  #   end
  # end

  describe "Student record details" do
    setup [:register_and_log_in_staff_member]

    test "view student record details", %{conn: conn, user: user} do
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

      {:ok, view, _html} =
        live(conn, "#{@live_view_base_path}?student_record=#{student_record.id}")

      assert view |> has_element?("#student-record-overlay h5", student_record.name)
      assert view |> has_element?("#student-record-overlay span", student.name)
      assert view |> has_element?("#student-record-overlay p", student_record.description)
      assert view |> has_element?("#student-record-overlay span", type.name)
      assert view |> has_element?("#student-record-overlay span", status.name)
    end
  end

  describe "Student record live school-based access" do
    setup [:register_and_log_in_staff_member]

    test "view records from other schools is not allowed", %{conn: conn} do
      student_record = StudentsRecordsFixtures.student_record_fixture()

      {:ok, view, _html} =
        live(conn, "#{@live_view_base_path}?student_record=#{student_record.id}")

      assert view |> has_element?("#student-record-overlay p", "Student record not found")
    end
  end
end
