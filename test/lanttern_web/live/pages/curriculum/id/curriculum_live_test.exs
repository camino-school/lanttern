defmodule LantternWeb.CurriculumLiveTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory

  @live_view_base_path "/curriculum"

  setup :register_and_log_in_staff_member

  describe "Curriculum live view" do
    test "disconnected and connected mount", %{conn: conn, staff_member: staff_member} do
      curriculum =
        insert(:curriculum, name: "Some curriculum name ABC", school_id: staff_member.school_id)

      conn = get(conn, "#{@live_view_base_path}/#{curriculum.id}")
      assert html_response(conn, 200) =~ ~r/<h1 .+>\s*Some curriculum name ABC\s*<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "view curriculum info", %{conn: conn, staff_member: staff_member} do
      curriculum =
        insert(:curriculum,
          description: "lorem ipsum description",
          school_id: staff_member.school_id
        )

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{curriculum.id}")

      assert view |> has_element?("h2", "About the curriculum")
      assert view |> has_element?("p", "lorem ipsum description")
    end

    test "listing curriculum components", %{conn: conn, staff_member: staff_member} do
      curriculum = insert(:curriculum, school_id: staff_member.school_id)

      _component_a =
        insert(:curriculum_component,
          name: "component AAA",
          curriculum_id: curriculum.id,
          school_id: staff_member.school_id
        )

      component_b =
        insert(:curriculum_component,
          name: "component BBB",
          curriculum_id: curriculum.id,
          school_id: staff_member.school_id
        )

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{curriculum.id}")

      assert view |> has_element?("a", "component AAA")

      view
      |> element("a", "component BBB")
      |> render_click()

      assert_redirect(view, ~p"/curriculum/component/#{component_b.id}")
    end
  end
end
