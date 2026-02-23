defmodule LantternWeb.Schools.ClassFormOverlayComponentTest do
  use LantternWeb.ConnCase

  alias Lanttern.SchoolsFixtures
  alias LantternWeb.Schools.ClassFormOverlayComponent
  alias LantternWeb.Schools.StaffMemberSearchComponent

  @live_view_base_path "/school/classes"

  setup [:register_and_log_in_staff_member]

  defp open_overlay(conn, user, class) do
    school_id = user.current_profile.school_id
    # ensure class belongs to user's school
    _ = school_id
    live(conn, "#{@live_view_base_path}/#{class.id}/people?edit=true")
  end

  describe "ClassFormOverlayComponent staff member operations" do
    test "add staff member via send_update", context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)
      school_id = user.current_profile.school_id
      class = SchoolsFixtures.class_fixture(%{school_id: school_id})
      staff_member = SchoolsFixtures.staff_member_fixture(%{school_id: school_id})

      {:ok, view, _html} = open_overlay(conn, user, class)

      Phoenix.LiveView.send_update(
        view.pid,
        ClassFormOverlayComponent,
        id: "class-form-overlay",
        action: {StaffMemberSearchComponent, {:selected, staff_member}}
      )

      assert render(view) =~ staff_member.name
    end

    test "remove staff member via button click", context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)
      school_id = user.current_profile.school_id
      class = SchoolsFixtures.class_fixture(%{school_id: school_id})
      staff_member = SchoolsFixtures.staff_member_fixture(%{school_id: school_id})

      SchoolsFixtures.class_staff_member_fixture(%{
        class_id: class.id,
        staff_member_id: staff_member.id
      })

      {:ok, view, _html} = open_overlay(conn, user, class)

      assert render(view) =~ staff_member.name

      view
      |> element("button[phx-click*='remove_staff_member'][phx-value-id='#{staff_member.id}']")
      |> render_click()

      refute render(view) =~ staff_member.name
    end

    test "reorder staff members via sortable_update hook event", context do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], context)
      school_id = user.current_profile.school_id
      class = SchoolsFixtures.class_fixture(%{school_id: school_id})

      staff_a = SchoolsFixtures.staff_member_fixture(%{school_id: school_id, name: "AAA Staff"})
      staff_b = SchoolsFixtures.staff_member_fixture(%{school_id: school_id, name: "ZZZ Staff"})

      SchoolsFixtures.class_staff_member_fixture(%{
        class_id: class.id,
        staff_member_id: staff_a.id,
        position: 0
      })

      SchoolsFixtures.class_staff_member_fixture(%{
        class_id: class.id,
        staff_member_id: staff_b.id,
        position: 1
      })

      {:ok, view, _html} = open_overlay(conn, user, class)

      # staff_a should appear before staff_b initially
      html = render(view)
      assert html =~ ~r/#{staff_a.name}.*#{staff_b.name}/s

      view
      |> element("#staff-members-list")
      |> render_hook("sortable_update", %{
        "from" => %{"groupId" => "staff-members-list", "sortableHandle" => ".sortable-handle"},
        "to" => %{"groupId" => "staff-members-list", "sortableHandle" => ".sortable-handle"},
        "oldIndex" => 0,
        "newIndex" => 1
      })

      html = render(view)
      assert html =~ ~r/#{staff_b.name}.*#{staff_a.name}/s
    end
  end
end
