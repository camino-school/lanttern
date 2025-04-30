defmodule LantternWeb.StudentsRecordsSettingsLiveTest do
  use LantternWeb.ConnCase

  @live_view_path "/students_records/settings/status"

  setup [:register_and_log_in_staff_member]

  describe "Students records settings live view basic navigation" do
    test "user with full access can access settings page", context do
      %{conn: conn} = set_user_permissions(["students_records_full_access"], context)
      conn = get(conn, @live_view_path)
      html = html_response(conn, 200)
      assert html =~ "Student records"
      assert html =~ ~r/<h1 .+>\s*Settings\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end
  end

  describe "Students records settings live view access" do
    test "user without full access can't access settings page", %{conn: conn} do
      assert_raise LantternWeb.NotFoundError, fn ->
        get(conn, @live_view_path)
      end
    end

    # test "user without full access can't access settings page through live navigation", %{
    #   conn: conn
    # } do
    #   assert_raise LantternWeb.NotFoundError, fn ->
    #     live(conn, @live_view_path)
    #   end
    # end
  end
end
