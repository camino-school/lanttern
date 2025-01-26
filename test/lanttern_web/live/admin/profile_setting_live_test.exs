defmodule LantternWeb.Admin.ProfileSettingsLiveTest do
  use LantternWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lanttern.IdentityFixtures
  import Lanttern.SchoolsFixtures

  setup :register_and_log_in_root_admin

  defp create_profile(_) do
    staff_member = staff_member_fixture()
    profile = staff_member_profile_fixture(%{staff_member_id: staff_member.id})
    profile = %{profile | name: staff_member.name}
    %{profile: profile}
  end

  describe "Index" do
    setup [:create_profile]

    test "lists all profiles", %{conn: conn, profile: profile} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/profile_settings")

      assert html =~ "Listing profile settings"
      assert html =~ profile.name
    end

    test "edit new student profile", %{conn: conn, profile: profile} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/profile_settings")

      assert index_live |> element("#profiles-#{profile.id} a", "Edit") |> render_click() =~
               "Edit profile setting"

      assert_patch(index_live, ~p"/admin/profile_settings/#{profile.id}/edit")

      assert index_live
             |> form("#profile-settings-form", profile_settings: %{permissions: ["wcd"]})
             |> render_submit()

      assert_patch(index_live, ~p"/admin/profile_settings")

      html = render(index_live)
      assert html =~ "Permissions updated successfully"
      assert html =~ "wcd"
    end
  end
end
