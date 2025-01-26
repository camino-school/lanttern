defmodule LantternWeb.DeactivatedStaffLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.SchoolsFixtures

  @live_view_path "/school/staff/deactivated"

  setup [:register_and_log_in_staff_member]

  describe "Deactivated staff live view basic navigation" do
    test "disconnected and connected mount", %{conn: conn} do
      conn = get(conn, @live_view_path)

      {:ok, regex} = Regex.compile("<h1 .+>\\s*Deactivated staff members\\s*<\/h1>")

      assert html_response(conn, 200) =~ regex

      {:ok, _view, _html} = live(conn)
    end

    test "list deactivated staff members", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id

      staff_member =
        SchoolsFixtures.staff_member_fixture(%{
          school_id: school_id,
          name: "staff member abc",
          deactivated_at: DateTime.utc_now()
        })

      other_staff_member =
        SchoolsFixtures.staff_member_fixture(%{
          name: "staff member from other school",
          deactivated_at: DateTime.utc_now()
        })

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("div", staff_member.name)
      refute view |> has_element?("div", other_staff_member.name)
    end
  end

  describe "Staff management" do
    test "allow user with school management permissions to reactivate and delete staff member",
         context do
      %{conn: conn, user: user} = add_school_management_permissions(context)

      school_id = user.current_profile.school_id

      staff_member =
        SchoolsFixtures.staff_member_fixture(%{
          school_id: school_id,
          deactivated_at: DateTime.utc_now()
        })

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("#staff-#{staff_member.id} button", "Reactivate")
      assert view |> has_element?("#staff-#{staff_member.id} button", "Delete")
    end

    test "prevent user without school management permissions to reactivate or delete staff member",
         %{
           conn: conn,
           user: user
         } do
      school_id = user.current_profile.school_id

      staff_member =
        SchoolsFixtures.staff_member_fixture(%{
          school_id: school_id,
          deactivated_at: DateTime.utc_now()
        })

      {:ok, view, _html} = live(conn, @live_view_path)

      refute view |> has_element?("#staff-#{staff_member.id} button", "Reactivate")
      refute view |> has_element?("#staff-#{staff_member.id} button", "Delete")
    end
  end
end
