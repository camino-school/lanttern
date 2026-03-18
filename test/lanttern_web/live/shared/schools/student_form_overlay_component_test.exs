defmodule LantternWeb.Schools.StudentFormOverlayComponentTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory

  setup [:register_and_log_in_staff_member]

  defp open_overlay(conn, student) do
    live(conn, "/school/students?edit=#{student.id}")
  end

  describe "guardian emails section" do
    test "renders guardian email input for school manager", context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)
      school = Lanttern.Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      student = insert(:student, school: school)

      {:ok, view, _html} = open_overlay(conn, student)

      assert has_element?(view, "#guardian-email-0")
    end

    test "does not crash when validate fires with _unused_ debounce keys", context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)
      school = Lanttern.Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      student = insert(:student, school: school)

      {:ok, view, _html} = open_overlay(conn, student)

      # Simulate what phx-debounce injects: _unused_N key alongside real index key
      html =
        view
        |> element("#student-form-student-form-overlay")
        |> render_change(%{
          "student" => %{"name" => student.name},
          "guardian_emails" => %{"0" => "", "_unused_0" => ""}
        })

      assert html =~ "guardian-email-0"
    end

    test "guardian email value is preserved in user emails section after validate", context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)
      school = Lanttern.Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      student = insert(:student, school: school)

      {:ok, view, _html} = open_overlay(conn, student)

      # Type a guardian email in the User Emails section
      html =
        view
        |> element("#student-form-student-form-overlay")
        |> render_change(%{
          "student" => %{"name" => student.name},
          "guardian_emails" => %{"0" => "guardian@example.com"}
        })

      # The email should be preserved in the user emails section
      assert html =~ "guardian@example.com"
    end

    test "does not show guardian emails section without school_management permission", context do
      %{conn: conn, user: user} = set_user_permissions([], context)
      school = Lanttern.Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      student = insert(:student, school: school)

      {:ok, _view, html} = open_overlay(conn, student)

      refute html =~ "guardian-email-0"
    end

    test "shows error when guardian email is invalid on save", context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)
      school = Lanttern.Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      student = insert(:student, school: school)

      {:ok, view, _html} = open_overlay(conn, student)

      html =
        view
        |> element("#student-form-student-form-overlay")
        |> render_submit(%{
          "student" => %{"name" => student.name},
          "guardian_emails" => %{"0" => "not-an-email"}
        })

      assert html =~ "invalid"
    end

    test "save creates guardian user account for valid email", context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)
      school = Lanttern.Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      student = insert(:student, school: school)
      guardian_email = "newguardian#{System.unique_integer()}@example.com"

      {:ok, view, _html} = open_overlay(conn, student)

      view
      |> element("#student-form-student-form-overlay")
      |> render_submit(%{
        "student" => %{"name" => student.name},
        "guardian_emails" => %{"0" => guardian_email}
      })

      assert %Lanttern.Identity.User{} = Lanttern.Identity.get_user_by_email(guardian_email)
    end

    test "pre-populates existing guardian emails when editing student", context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)
      school = Lanttern.Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      student = insert(:student, school: school)

      guardian_user = insert(:user)

      insert(:profile,
        type: "guardian",
        user: guardian_user,
        staff_member: nil,
        guardian_of_student: student
      )

      {:ok, _view, html} = open_overlay(conn, student)

      assert html =~ guardian_user.email
    end
  end
end
