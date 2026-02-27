defmodule LantternWeb.GuardianLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  alias Lanttern.Schools

  @live_view_base_path "/school/guardians"

  setup [:register_and_log_in_staff_member]

  describe "Guardian detail live view - browser integration tests" do
    setup %{conn: conn, user: user} do
      %{conn: conn, user: user} = set_user_permissions(["school_management"], %{
        conn: conn,
        user: user
      })

      school_id = user.current_profile.school_id
      guardian = insert(:guardian, school_id: school_id, name: "Test Guardian")

      %{conn: conn, user: user, school_id: school_id, guardian: guardian}
    end

    test "displays guardian name", %{conn: conn, guardian: guardian} do
      conn
      |> visit("#{@live_view_base_path}/#{guardian.id}")
      |> assert_has("h2", text: "Test Guardian")
    end

    test "displays linked students", %{conn: conn, user: user, guardian: guardian, school_id: school_id} do
      student = insert(:student, school_id: school_id, name: "Alice Smith")

      Schools.add_guardian_to_student(user.current_profile, student, guardian)

      conn
      |> visit("#{@live_view_base_path}/#{guardian.id}")
      |> assert_has("a", text: "Alice Smith")
    end

    test "displays shared guardians", %{conn: conn, user: user, guardian: guardian1, school_id: school_id} do
      guardian2 = insert(:guardian, school_id: school_id, name: "Guardian Two")
      student = insert(:student, school_id: school_id)

      Schools.add_guardian_to_student(user.current_profile, student, guardian1)
      Schools.add_guardian_to_student(user.current_profile, student, guardian2)

      conn
      |> visit("#{@live_view_base_path}/#{guardian1.id}")
      |> assert_has("h3", text: "Shared Guardians")
      |> assert_has("a", text: "Guardian Two")
    end

    test "edit guardian name flow", %{conn: conn, guardian: guardian} do
      conn
      |> visit("#{@live_view_base_path}/#{guardian.id}?edit=true")
      |> assert_has("h2", text: "Edit guardian")
      |> fill_in("Name", with: "Updated Guardian Name")
      |> click_button("Save")

      # Verify by visiting again
      conn
      |> visit("#{@live_view_base_path}/#{guardian.id}")
      |> assert_has("h2", text: "Updated Guardian Name")
    end

    test "cancel editing returns to view mode", %{conn: conn, guardian: guardian} do
      conn
      |> visit("#{@live_view_base_path}/#{guardian.id}?edit=true")
      |> click_button("Cancel")
      |> assert_has("a", text: "Edit guardian")
    end

    test "delete guardian workflow", %{conn: conn, user: user, guardian: guardian} do
      conn
      |> visit("#{@live_view_base_path}/#{guardian.id}?edit=true")
      |> click_button("Delete")

      # Verify guardian is deleted by trying to fetch it
      refute Schools.get_guardian(user.current_profile, guardian.id)
    end
  end
end
