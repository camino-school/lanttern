defmodule LantternWeb.CurriculaSettingsLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import Phoenix.LiveViewTest
  import PhoenixTest

  alias Lanttern.Identity.Scope
  alias Lanttern.Repo
  alias LantternWeb.CurriculaSettingsLive.CurriculumCardComponent

  @live_view_path "/settings/curricula"

  setup [:register_and_log_in_staff_member]

  describe "CurriculaSettingsLive access control" do
    test "raises NotFoundError for user without curriculum_management permission", %{conn: conn} do
      assert_raise LantternWeb.NotFoundError, fn ->
        live(conn, @live_view_path)
      end
    end
  end

  describe "CurriculaSettingsLive listing" do
    test "lists active curricula for the user's school", context do
      %{conn: conn, user: user} = set_user_permissions(["curriculum_management"], context)
      school_id = Scope.for_user(user).school_id

      curriculum_a = insert(:curriculum, name: "Alpha Curriculum", school_id: school_id)
      curriculum_b = insert(:curriculum, name: "Beta Curriculum", school_id: school_id)

      # another school's curriculum should not appear
      other = insert(:curriculum, name: "Other School Curriculum")

      conn
      |> visit(@live_view_path)
      |> assert_has("#curricula-#{curriculum_a.id}", text: "Alpha Curriculum")
      |> assert_has("#curricula-#{curriculum_b.id}", text: "Beta Curriculum")
      |> refute_has("#curricula-#{other.id}", text: "Other School Curriculum")
    end

    test "shows empty state when no curricula exist", context do
      %{conn: conn} = set_user_permissions(["curriculum_management"], context)

      conn
      |> visit(@live_view_path)
      |> assert_has("p", text: "No curricula created yet")
    end

    test "lists deactivated curricula in a separate section", context do
      %{conn: conn, user: user} = set_user_permissions(["curriculum_management"], context)
      school_id = Scope.for_user(user).school_id

      active = insert(:curriculum, name: "Active Curriculum", school_id: school_id)

      inactive =
        insert(:curriculum,
          name: "Inactive Curriculum",
          school_id: school_id,
          deactivated_at: ~U[2025-01-01 00:00:00Z]
        )

      conn
      |> visit(@live_view_path)
      |> assert_has("#curricula-#{active.id}", text: "Active Curriculum")
      |> assert_has("h3", text: "Deactivated curricula")
      |> assert_has("#curricula-#{inactive.id}", text: "Inactive Curriculum")
    end
  end

  describe "CurriculaSettingsLive create curriculum" do
    test "creates a new curriculum via modal form", context do
      %{conn: conn} = set_user_permissions(["curriculum_management"], context)

      conn
      |> visit(@live_view_path)
      |> click_button("New curriculum")
      |> within("#curriculum-form-modal", fn session ->
        session
        |> fill_in("Curriculum name", with: "My New Curriculum")
        |> click_button("Save")
      end)
      |> assert_has("#curricula-list", text: "My New Curriculum")
    end

    test "shows validation errors for invalid data", context do
      %{conn: conn} = set_user_permissions(["curriculum_management"], context)

      conn
      |> visit(@live_view_path)
      |> click_button("New curriculum")
      |> within("#curriculum-form-modal", fn session ->
        session
        |> fill_in("Curriculum name", with: "")
        |> click_button("Save")
      end)
      |> assert_has("#curriculum-form-modal", text: "can't be blank")
    end
  end

  describe "CurriculaSettingsLive edit curriculum" do
    test "edits an existing curriculum via modal form", context do
      %{conn: conn, user: user} = set_user_permissions(["curriculum_management"], context)

      curriculum =
        insert(:curriculum, name: "Old Name", school_id: Scope.for_user(user).school_id)

      conn
      |> visit("#{@live_view_path}/#{curriculum.id}")
      |> click_button("Edit curriculum")
      |> within("#curriculum-form-modal", fn session ->
        session
        |> fill_in("Curriculum name", with: "Updated Name")
        |> click_button("Save")
      end)
      |> assert_has("#curricula-list", text: "Updated Name")
    end

    test "deletes a curriculum", context do
      %{conn: conn, user: user} = set_user_permissions(["curriculum_management"], context)

      curriculum =
        insert(:curriculum, name: "To Be Deleted", school_id: Scope.for_user(user).school_id)

      conn
      |> visit("#{@live_view_path}/#{curriculum.id}")
      |> click_button("Edit curriculum")
      |> click_button("#curriculum-form button", "Delete")
      |> refute_has("#curricula-list", text: "To Be Deleted")

      assert Repo.get(Lanttern.Curricula.Curriculum, curriculum.id) == nil
    end
  end

  describe "CurriculaSettingsLive activate/deactivate curriculum" do
    test "deactivates an active curriculum", context do
      %{conn: conn, user: user} = set_user_permissions(["curriculum_management"], context)

      curriculum =
        insert(:curriculum, name: "Active Curriculum", school_id: Scope.for_user(user).school_id)

      {:ok, view, _html} = live(conn, @live_view_path)

      # The toggle button targets the live component, which sends a message to the view.
      # We send the message directly to the view process and flush to ensure it's processed.
      send(view.pid, {CurriculumCardComponent, {:deactivate_curriculum, curriculum.id}})
      render(view)

      assert Repo.get!(Lanttern.Curricula.Curriculum, curriculum.id).deactivated_at != nil
    end

    test "reactivates a deactivated curriculum", context do
      %{conn: conn, user: user} = set_user_permissions(["curriculum_management"], context)

      curriculum =
        insert(:curriculum,
          name: "Inactive Curriculum",
          school_id: Scope.for_user(user).school_id,
          deactivated_at: ~U[2025-01-01 00:00:00Z]
        )

      {:ok, view, _html} = live(conn, @live_view_path)

      send(view.pid, {CurriculumCardComponent, {:activate_curriculum, curriculum.id}})
      render(view)

      assert Repo.get!(Lanttern.Curricula.Curriculum, curriculum.id).deactivated_at == nil
    end
  end

  describe "CurriculaSettingsLive curriculum components" do
    test "creates a new component via modal form when curriculum is expanded", context do
      %{conn: conn, user: user} = set_user_permissions(["curriculum_management"], context)

      curriculum =
        insert(:curriculum, name: "My Curriculum", school_id: Scope.for_user(user).school_id)

      conn
      |> visit("#{@live_view_path}/#{curriculum.id}")
      |> click_button("Add component")
      |> within("#curriculum-component-form-modal", fn session ->
        session
        |> fill_in("Name", with: "New Component")
        |> click_button("Save")
      end)

      assert Repo.get_by(Lanttern.Curricula.CurriculumComponent,
               name: "New Component",
               curriculum_id: curriculum.id
             )
    end

    test "reorders components via sortable_update, only affecting the school's components",
         context do
      %{conn: conn, user: user} = set_user_permissions(["curriculum_management"], context)
      school_id = Scope.for_user(user).school_id
      curriculum = insert(:curriculum, school_id: school_id)

      cc1 =
        insert(:curriculum_component, curriculum: curriculum, school_id: school_id, position: 0)

      cc2 =
        insert(:curriculum_component, curriculum: curriculum, school_id: school_id, position: 1)

      cc3 =
        insert(:curriculum_component, curriculum: curriculum, school_id: school_id, position: 2)

      # other school's component — should not be affected
      other_cc = insert(:curriculum_component, position: 5)

      {:ok, view, _html} = live(conn, "#{@live_view_path}/#{curriculum.id}")

      # Simulate drag: move cc1 (index 0) to last position (index 2)
      # The card component handles sortable_update and sends the reorder message to the view.
      send(
        view.pid,
        {CurriculumCardComponent, {:reorder_curriculum_components, [cc2.id, cc3.id, cc1.id]}}
      )

      render(view)

      assert Repo.get!(Lanttern.Curricula.CurriculumComponent, cc2.id).position == 0
      assert Repo.get!(Lanttern.Curricula.CurriculumComponent, cc3.id).position == 1
      assert Repo.get!(Lanttern.Curricula.CurriculumComponent, cc1.id).position == 2

      # other school's component must not be affected
      assert Repo.get!(Lanttern.Curricula.CurriculumComponent, other_cc.id).position == 5
    end
  end
end
