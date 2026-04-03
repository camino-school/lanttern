defmodule LantternWeb.CurriculumComponentLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory

  @live_view_base_path "/curriculum/component"

  setup :register_and_log_in_staff_member

  describe "Curriculum live view" do
    test "disconnected and connected mount", %{conn: conn, staff_member: staff_member} do
      curriculum =
        insert(:curriculum, name: "Curriculum ABC", school_id: staff_member.school_id)

      curriculum_component =
        insert(:curriculum_component,
          name: "Component XYZ",
          curriculum_id: curriculum.id,
          school_id: staff_member.school_id
        )

      conn = get(conn, "#{@live_view_base_path}/#{curriculum_component.id}")
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*Component XYZ\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "view curriculum component info", %{conn: conn, staff_member: staff_member} do
      curriculum_component =
        insert(:curriculum_component,
          description: "lorem ipsum description",
          school_id: staff_member.school_id
        )

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{curriculum_component.id}")

      assert view |> has_element?("h2", "About the curriculum component")

      assert view |> has_element?("p", "lorem ipsum description")
    end

    test "listing curriculum items", %{conn: conn, staff_member: staff_member} do
      curriculum_component =
        insert(:curriculum_component, school_id: staff_member.school_id)

      insert(:curriculum_item,
        name: "item AAA",
        curriculum_component_id: curriculum_component.id,
        school_id: staff_member.school_id
      )

      insert(:curriculum_item,
        name: "item BBB",
        curriculum_component_id: curriculum_component.id,
        school_id: staff_member.school_id
      )

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{curriculum_component.id}")

      assert view |> has_element?("div", "item AAA")
      assert view |> has_element?("div", "item BBB")
    end
  end
end
