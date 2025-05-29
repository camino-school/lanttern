defmodule LantternWeb.StudentLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

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
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)
      school_id = user.current_profile.school_id
      student = SchoolsFixtures.student_fixture(%{school_id: school_id, name: "student abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{student.id}?edit=true")

      assert view |> has_element?("#student-form-overlay h2", "Edit student")
    end

    test "prevent user without school management permissions to edit staff member", ctx do
      school_id = ctx.user.current_profile.school_id
      student = SchoolsFixtures.student_fixture(%{school_id: school_id, name: "student abc"})

      {:ok, view, _html} = live(ctx.conn, "#{@live_view_base_path}/#{student.id}?edit=true")

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
      %{conn: conn, user: user} = set_user_permissions(["students_records_full_access"], context)

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

    test "renders ok when student record is closed", ctx do
      %{conn: conn, user: user} = set_user_permissions(["students_records_full_access"], ctx)
      school = user.current_profile.staff_member.school
      student = SchoolsFixtures.student_fixture(%{school_id: school.id, name: "std abc"})
      status = insert(:student_records_status, %{school: school})

      student_record =
        insert(:student_record, %{
          name: "closed student record",
          school: school,
          students_ids: [student.id],
          date: ~D[2024-09-15],
          time: ~T[14:00:00],
          closed_at: ~U[2025-05-19 21:23:13Z],
          closed_by_staff_member: user.current_profile.staff_member,
          created_by_staff_member: user.current_profile.staff_member,
          status_id: status.id
        })

      insert(:student_record_relationship, %{
        student_record_id: student_record.id,
        school_id: school.id,
        student_id: student.id
      })

      url =
        "#{@live_view_base_path}/#{student.id}/student_records?student_record=#{student_record.id}"

      {:ok, view, _html} = live(conn, url)

      assert view |> has_element?("span", student.name)
      assert render(view) =~ "Closed by #{user.current_profile.name} on May 19, 2025, 18:23 ("
    end

    test "renders ok when locale pt_BR", ctx do
      user =
        Map.update!(ctx.user, :current_profile, fn profile ->
          %Lanttern.Identity.Profile{profile | current_locale: "pt_BR"}
        end)

      user_info = %{conn: ctx.conn, user: user}
      %{conn: conn} = set_user_permissions(["students_records_full_access"], user_info)
      school = user.current_profile.staff_member.school
      student = SchoolsFixtures.student_fixture(%{school_id: school.id, name: "std abc"})
      status = insert(:student_records_status, %{school: school})

      student_record =
        insert(:student_record, %{
          name: "closed student record",
          school: school,
          students_ids: [student.id],
          date: ~D[2024-09-15],
          time: ~T[14:00:00],
          closed_at: ~U[2025-05-19 21:23:13Z],
          closed_by_staff_member: user.current_profile.staff_member,
          created_by_staff_member: user.current_profile.staff_member,
          status_id: status.id
        })

      insert(:student_record_relationship, %{
        student_record_id: student_record.id,
        school_id: school.id,
        student_id: student.id
      })

      url =
        "#{@live_view_base_path}/#{student.id}/student_records?student_record=#{student_record.id}"

      {:ok, view, _html} = live(conn, url)

      assert view |> has_element?("span", student.name)
      assert render(view) =~ "Closed by #{user.current_profile.name} on May 19, 2025, 18:23 ("
    end
  end

  describe "Student ILP live view access" do
    test "renders ok when create a new ILP comment", ctx do
      school = ctx.user.current_profile.staff_member.school
      student = insert(:student, %{school: school})
      template = insert(:ilp_template, %{school: school})
      cycle = insert(:cycle, %{school: school})
      insert(:student_ilp, %{student: student, cycle: cycle, template: template, school: school})

      ctx.conn
      |> visit("#{@live_view_base_path}/#{student.id}/ilp")
      |> click_link("Add comment")
      |> assert_has("h2", text: "New Comment")
      |> fill_in("Title", with: "Quartely Feedback")
      |> fill_in("Content", with: "Content for quartely feedback")
      |> click_button("Save")

      ctx.conn
      |> visit("#{@live_view_base_path}/#{student.id}/ilp")
      |> assert_has("a", text: "Quartely Feedback")
      |> assert_has("p", text: "Content for quartely feedback")
    end

    test "renders ok when edit a new ILP comment", ctx do
      school = ctx.user.current_profile.staff_member.school
      student = insert(:student, %{school: school})
      template = insert(:ilp_template, %{school: school})
      cycle = insert(:cycle, %{school: school})

      ilp =
        insert(:student_ilp, %{student: student, cycle: cycle, template: template, school: school})

      insert(:ilp_comment, %{student_ilp: ilp, owner: ctx.user.current_profile})

      ctx.conn
      |> visit("#{@live_view_base_path}/#{student.id}/ilp")
      |> click_link("Edit comment")
      |> assert_has("h2", text: "Edit Comment")
      |> fill_in("Title", with: "Teacher's feedback'")
      |> fill_in("Content", with: "Feedback content.")
      |> click_button("Save")

      ctx.conn
      |> visit("#{@live_view_base_path}/#{student.id}/ilp")
      |> assert_has("a", text: "Teacher's feedback'")
      |> assert_has("p", text: "Feedback content.")
    end

    test "renders ok when list all ILP comment for a student_ilp", ctx do
      school = ctx.user.current_profile.staff_member.school
      student = insert(:student, %{school: school})
      template = insert(:ilp_template, %{school: school})
      cycle = insert(:cycle, %{school: school})

      ilp =
        insert(:student_ilp, %{student: student, cycle: cycle, template: template, school: school})

      comment1 = insert(:ilp_comment, %{student_ilp: ilp, owner: ctx.user.current_profile})

      comment2 =
        insert(:ilp_comment, %{
          student_ilp: ilp,
          name: "Review",
          content: "Content.",
          owner: ctx.user.current_profile
        })

      ctx.conn
      |> visit("#{@live_view_base_path}/#{student.id}/ilp")
      |> assert_has("a", text: comment1.name)
      |> assert_has("p", text: comment1.content)
      |> assert_has("a", text: comment2.name)
      |> assert_has("p", text: comment2.content)
    end
  end
end
