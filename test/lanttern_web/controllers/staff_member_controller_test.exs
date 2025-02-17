defmodule LantternWeb.StaffMemberControllerTest do
  use LantternWeb.ConnCase

  import Lanttern.SchoolsFixtures

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  setup :register_and_log_in_root_admin

  describe "index" do
    test "lists all staff members", %{conn: conn} do
      conn = get(conn, ~p"/admin/staff_members")
      assert html_response(conn, 200) =~ "Listing staff members"
    end
  end

  describe "new staff member" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/staff_members/new")
      assert html_response(conn, 200) =~ "New staff member"
    end
  end

  describe "create staff member" do
    test "redirects to show when data is valid", %{conn: conn} do
      school = school_fixture()
      create_attrs = @create_attrs |> Map.put_new(:school_id, school.id)
      conn = post(conn, ~p"/admin/staff_members", staff_member: create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/staff_members/#{id}"

      conn = get(conn, ~p"/admin/staff_members/#{id}")
      assert html_response(conn, 200) =~ "Staff member #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/staff_members", staff_member: @invalid_attrs)
      assert html_response(conn, 200) =~ "New staff member"
    end
  end

  describe "edit staff member" do
    setup [:create_staff_member]

    test "renders form for editing chosen staff member", %{conn: conn, staff_member: staff_member} do
      conn = get(conn, ~p"/admin/staff_members/#{staff_member}/edit")
      assert html_response(conn, 200) =~ "Edit staff member"
    end
  end

  describe "update staff member" do
    setup [:create_staff_member]

    test "redirects when data is valid", %{conn: conn, staff_member: staff_member} do
      conn = put(conn, ~p"/admin/staff_members/#{staff_member}", staff_member: @update_attrs)
      assert redirected_to(conn) == ~p"/admin/staff_members/#{staff_member}"

      conn = get(conn, ~p"/admin/staff_members/#{staff_member}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, staff_member: staff_member} do
      conn = put(conn, ~p"/admin/staff_members/#{staff_member}", staff_member: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit staff member"
    end
  end

  describe "delete staff member" do
    setup [:create_staff_member]

    test "deletes chosen staff member", %{conn: conn, staff_member: staff_member} do
      conn = delete(conn, ~p"/admin/staff_members/#{staff_member}")
      assert redirected_to(conn) == ~p"/admin/staff_members"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/staff_members/#{staff_member}")
      end
    end
  end

  defp create_staff_member(_) do
    staff_member = staff_member_fixture()
    %{staff_member: staff_member}
  end
end
