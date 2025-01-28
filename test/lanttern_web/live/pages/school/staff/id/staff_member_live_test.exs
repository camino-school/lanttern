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
end
