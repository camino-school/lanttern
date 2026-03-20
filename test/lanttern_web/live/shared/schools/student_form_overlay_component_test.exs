defmodule LantternWeb.Schools.StudentFormOverlayComponentTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  setup [:register_and_log_in_staff_member]

  describe "guardian emails section" do
    test "renders guardian email input for school manager", context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)
      school = Lanttern.Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      student = insert(:student, school: school)

      conn
      |> visit("/school/students?edit=#{student.id}")
      |> assert_has("#guardian-email-0")
    end

    test "guardian email value is preserved in user emails section after validate", context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)
      school = Lanttern.Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      student = insert(:student, school: school)

      conn
      |> visit("/school/students?edit=#{student.id}")
      |> fill_in("#guardian-email-0", "", with: "guardian@example.com")
      |> assert_has("#guardian-email-0[value='guardian@example.com']")
    end

    test "does not show guardian emails section without school_management permission", context do
      %{conn: conn, user: user} = set_user_permissions([], context)
      school = Lanttern.Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      student = insert(:student, school: school)

      conn
      |> visit("/school/students?edit=#{student.id}")
      |> refute_has("#guardian-email-0")
    end

    test "shows error when guardian email is invalid on save", context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)
      school = Lanttern.Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      student = insert(:student, school: school)

      conn
      |> visit("/school/students?edit=#{student.id}")
      |> fill_in("#guardian-email-0", "", with: "not-an-email")
      |> click_button("[form='student-form-student-form-overlay']", "Save")
      |> assert_has("div", text: "emails are invalid")
    end

    test "save creates guardian user account for valid email", context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)
      school = Lanttern.Repo.get!(Lanttern.Schools.School, user.current_profile.school_id)
      student = insert(:student, school: school)
      guardian_email = "newguardian#{System.unique_integer()}@example.com"

      conn
      |> visit("/school/students?edit=#{student.id}")
      |> fill_in("#guardian-email-0", "", with: guardian_email)
      |> click_button("[form='student-form-student-form-overlay']", "Save")

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

      conn
      |> visit("/school/students?edit=#{student.id}")
      |> assert_has("#guardian-email-0[value='#{guardian_user.email}']")
    end
  end
end
