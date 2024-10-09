defmodule LantternWeb.StudentsRecordsLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.SchoolsFixtures
  alias Lanttern.StudentsRecordsFixtures

  @live_view_path "/students_records"

  setup [:register_and_log_in_teacher]

  describe "Students records live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)
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

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("span", student.name)
      assert view |> has_element?("p", student_record.name)
      assert view |> has_element?("p", student_record.description)
      assert view |> has_element?("span", type.name)
      assert view |> has_element?("span", status.name)
    end
  end
end
