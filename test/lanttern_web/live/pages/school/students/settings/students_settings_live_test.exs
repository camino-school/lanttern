defmodule LantternWeb.StudentsSettingsLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.StudentTagsFixtures

  @live_view_path "/school/students/settings"

  setup [:register_and_log_in_staff_member]

  describe "Students settings live view basic navigation" do
    test "school manager disconnected and connected mount", context do
      %{conn: conn} = set_user_permissions(["school_management"], context)
      conn = get(conn, @live_view_path)
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*Students settings\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "list tags", context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)

      school_id = user.current_profile.school_id

      _student_tag =
        StudentTagsFixtures.student_tag_fixture(%{school_id: school_id, name: "student tag abc"})

      {:ok, view, _html} = live(conn, @live_view_path)

      assert view |> has_element?("span", "student tag abc")
    end
  end

  describe "Students settings live view access" do
    test "user without school management can't access settings page", %{conn: conn} do
      {:error,
       {:live_redirect,
        %{
          to: "/school/students",
          flash: %{"error" => "You don't have access to students settings page"}
        }}} =
        live(conn, @live_view_path)
    end
  end
end
