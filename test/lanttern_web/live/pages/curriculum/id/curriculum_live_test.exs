defmodule LantternWeb.CurriculumLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.CurriculaFixtures

  @live_view_base_path "/curriculum"

  setup :register_and_log_in_staff_member

  describe "Curriculum live view" do
    test "disconnected and connected mount", %{conn: conn} do
      curriculum = curriculum_fixture(%{name: "Some curriculum name ABC"})
      conn = get(conn, "#{@live_view_base_path}/#{curriculum.id}")
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*Some curriculum name ABC\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "view curriculum info", %{conn: conn} do
      curriculum = curriculum_fixture(%{description: "lorem ipsum description"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{curriculum.id}")

      assert view |> has_element?("h2", "About the curriculum")
      assert view |> has_element?("p", "lorem ipsum description")
    end

    test "listing curriculum components", %{conn: conn} do
      curriculum = curriculum_fixture()

      _component_a =
        curriculum_component_fixture(%{name: "component AAA", curriculum_id: curriculum.id})

      component_b =
        curriculum_component_fixture(%{name: "component BBB", curriculum_id: curriculum.id})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{curriculum.id}")

      assert view |> has_element?("a", "component AAA")

      view
      |> element("a", "component BBB")
      |> render_click()

      assert_redirect(view, ~p"/curriculum/component/#{component_b.id}")
    end
  end
end
