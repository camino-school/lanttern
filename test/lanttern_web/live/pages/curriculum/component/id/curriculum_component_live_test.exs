defmodule LantternWeb.CurriculumComponentLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.CurriculaFixtures

  @live_view_base_path "/curriculum/component"

  setup :register_and_log_in_staff_member

  describe "Curriculum live view" do
    test "disconnected and connected mount", %{conn: conn} do
      curriculum = curriculum_fixture(%{name: "Curriculum ABC"})

      curriculum_component =
        curriculum_component_fixture(%{name: "Component XYZ", curriculum_id: curriculum.id})

      conn = get(conn, "#{@live_view_base_path}/#{curriculum_component.id}")
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*Component XYZ\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "view curriculum component info", %{conn: conn} do
      curriculum_component =
        curriculum_component_fixture(%{description: "lorem ipsum description"})

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{curriculum_component.id}")

      assert view |> has_element?("h2", "About the curriculum component")

      assert view |> has_element?("p", "lorem ipsum description")
    end

    test "listing curriculum items", %{conn: conn} do
      curriculum_component = curriculum_component_fixture()

      curriculum_item_fixture(%{
        name: "item AAA",
        curriculum_component_id: curriculum_component.id
      })

      curriculum_item_fixture(%{
        name: "item BBB",
        curriculum_component_id: curriculum_component.id
      })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{curriculum_component.id}")

      assert view |> has_element?("div", "item AAA")
      assert view |> has_element?("div", "item BBB")
    end
  end
end
