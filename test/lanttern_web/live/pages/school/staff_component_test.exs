defmodule LantternWeb.SchoolLive.StaffComponentTest do
  use LantternWeb.ConnCase

  alias Lanttern.SchoolsFixtures

  @live_view_path "/school/staff"

  setup [:register_and_log_in_staff_member]

  describe "Staff management" do
    test "list staff", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id

      staff_member =
        SchoolsFixtures.staff_member_fixture(%{school_id: school_id, name: "staff member abc"})

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("div", staff_member.name)
    end

    test "allow user with school management permissions to create staff member", context do
      %{conn: conn} = add_school_management_permissions(context)
      {:ok, view, _html} = live(conn, "#{@live_view_path}?new=true")

      assert view |> has_element?("#staff-member-form-overlay h2", "New staff member")
    end

    test "prevent user without school management permissions to create staff member", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, "#{@live_view_path}?new=true")

      refute view |> has_element?("#staff-member-form-overlay h2", "New staff member")
    end

    test "allow user with school management permissions to edit staff member", context do
      %{conn: conn, user: user} = add_school_management_permissions(context)
      school_id = user.current_profile.school_id

      staff_member =
        SchoolsFixtures.staff_member_fixture(%{school_id: school_id, name: "staff member abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_path}?edit=#{staff_member.id}")

      assert view |> has_element?("#staff-member-form-overlay h2", "Edit staff member")
    end

    test "prevent user without school management permissions to edit staff member", %{
      conn: conn,
      user: user
    } do
      school_id = user.current_profile.school_id

      staff_member =
        SchoolsFixtures.staff_member_fixture(%{school_id: school_id, name: "staff member abc"})

      {:ok, view, _html} = live(conn, "#{@live_view_path}?edit=#{staff_member.id}")

      refute view |> has_element?("#staff-member-form-overlay h2", "Edit staff member")
    end

    test "prevent user to edit staff member from other schools", context do
      %{conn: conn} = add_school_management_permissions(context)

      staff_member =
        SchoolsFixtures.staff_member_fixture(%{name: "staff member from other school"})

      {:ok, view, _html} = live(conn, "#{@live_view_path}?edit=#{staff_member.id}")

      refute view |> has_element?("#staff-member-form-overlay h2", "Edit staff member")
    end
  end
end
