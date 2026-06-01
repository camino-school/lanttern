defmodule LantternWeb.StrandLive.AssessmentComponentTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  alias Lanttern.Assessments
  alias Lanttern.AssessmentsFixtures

  @live_view_base_path "/strands"

  setup [:register_and_log_in_staff_member]

  describe "display" do
    test "shows assessment info when present", %{conn: conn} do
      strand = insert(:strand, assessment_info: "Some **assessment info**")

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> assert_has("button", text: "Edit assessment info")
    end

    test "shows 'Add assessment info' button when no assessment info present", %{conn: conn} do
      strand = insert(:strand)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> assert_has("button", text: "Add assessment info")
    end

    test "shows moment assessment points grouped by moment", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand, name: "Moment One")
      scale = insert(:scale)
      curriculum_item = insert(:curriculum_item)

      AssessmentsFixtures.assessment_point_fixture(%{
        name: "AP name abc",
        moment_id: moment.id,
        scale_id: scale.id,
        curriculum_item_id: curriculum_item.id
      })

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> assert_has("h4", text: "Moment One")
      |> assert_has("button", text: "AP name abc")
    end

    test "shows strand assessment points in goals assessment section", %{conn: conn} do
      strand = insert(:strand)
      curriculum_component = insert(:curriculum_component)

      curriculum_item =
        insert(:curriculum_item, %{
          curriculum_component_id: curriculum_component.id,
          name: "CI name xyz"
        })

      scale = insert(:scale)

      AssessmentsFixtures.assessment_point_fixture(%{
        strand_id: strand.id,
        scale_id: scale.id,
        curriculum_item_id: curriculum_item.id
      })

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> assert_has("h4", text: "Goals assessment")
      |> assert_has("button", text: "(#{curriculum_component.name}) CI name xyz")
    end

    test "shows empty state when moment has no assessment points", %{conn: conn} do
      strand = insert(:strand)
      _moment = insert(:moment, strand: strand, name: "Empty Moment")

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> assert_has("h4", text: "Empty Moment")
      |> assert_has("p", text: "No assessment points in this moment yet")
    end
  end

  describe "assessment info management" do
    test "add assessment info", %{conn: conn} do
      strand = insert(:strand)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> click_button("Add assessment info")
      |> fill_in("Strand assessment info", with: "New assessment info")
      |> click_button("Save")
      |> assert_has("div", text: "New assessment info")
      |> assert_has("button", text: "Edit assessment info")
    end

    test "edit assessment info", %{conn: conn} do
      strand = insert(:strand, assessment_info: "Old info")

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> click_button("Edit assessment info")
      |> fill_in("Strand assessment info", with: "Updated info")
      |> click_button("Save")
      |> assert_has("div", text: "Updated info")
    end

    test "cancel assessment info edit", %{conn: conn} do
      strand = insert(:strand)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> click_button("Add assessment info")
      |> within("#strand-assessment-info-form", fn session ->
        session |> click_button("Cancel")
      end)
      |> assert_has("button", text: "Add assessment info")
    end
  end

  describe "assessment point management" do
    test "create moment assessment point", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      strand = insert(:strand)
      moment = insert(:moment, strand: strand, name: "Test Moment")
      scale = insert(:scale, school_id: school_id, name: "Test Scale")
      curriculum_component = insert(:curriculum_component)

      curriculum_item =
        insert(:curriculum_item, %{
          curriculum_component_id: curriculum_component.id,
          name: "CI for moment AP"
        })

      # Create a strand-level AP so that curriculum item is available in the moment AP dropdown
      AssessmentsFixtures.assessment_point_fixture(%{
        strand_id: strand.id,
        scale_id: scale.id,
        curriculum_item_id: curriculum_item.id
      })

      {:ok, view, _html} = live(conn, "#{@live_view_base_path}/#{strand.id}/assessment")

      view
      |> element("#new-moment-assessment button", moment.name)
      |> render_click()

      view
      |> element("#assessment-point-form-overlay-form")
      |> render_submit(%{
        "assessment_point" => %{
          "name" => "New moment AP",
          "scale_id" => "#{scale.id}",
          "curriculum_item_id" => "#{curriculum_item.id}"
        }
      })

      assert view |> has_element?("button", "New moment AP")
    end

    test "update moment assessment point name", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)
      scale = insert(:scale, school_id: school_id)
      curriculum_item = insert(:curriculum_item, %{school_id: school_id})

      AssessmentsFixtures.assessment_point_fixture(%{
        name: "Original AP name",
        moment_id: moment.id,
        scale_id: scale.id,
        curriculum_item_id: curriculum_item.id
      })

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> click_button("Original AP name")
      |> fill_in("Assessment point name", with: "Updated AP name")
      |> click_button("Save")
      |> assert_has("button", text: "Updated AP name")
    end

    test "delete moment assessment point", %{conn: conn, user: user} do
      school_id = user.current_profile.school_id
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)
      scale = insert(:scale, school_id: school_id)
      curriculum_item = insert(:curriculum_item, %{school_id: school_id})

      AssessmentsFixtures.assessment_point_fixture(%{
        name: "AP to delete",
        moment_id: moment.id,
        scale_id: scale.id,
        curriculum_item_id: curriculum_item.id
      })

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> click_button("AP to delete")
      |> within("#assessment-point-form-overlay", fn session ->
        session |> click_button("Delete")
      end)
      |> refute_has("button", text: "AP to delete")
    end
  end

  describe "reorder assessment points" do
    test "reorder assessment points within the same moment", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)
      scale = insert(:scale)
      curriculum_item_1 = insert(:curriculum_item)
      curriculum_item_2 = insert(:curriculum_item)

      ap1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          name: "AP First",
          moment_id: moment.id,
          scale_id: scale.id,
          curriculum_item_id: curriculum_item_1.id,
          position: 0
        })

      ap2 =
        AssessmentsFixtures.assessment_point_fixture(%{
          name: "AP Second",
          moment_id: moment.id,
          scale_id: scale.id,
          curriculum_item_id: curriculum_item_2.id,
          position: 1
        })

      {:ok, view, _html} = live(conn, "/strands/#{strand.id}/assessment")

      view
      |> element("#moment-#{moment.id}-sortable-aps")
      |> render_hook("sortable_ap_update", %{
        "from" => %{
          "momentId" => "#{moment.id}",
          "sortableHandle" => ".sortable-handle",
          "sortableEvent" => "sortable_ap_update",
          "sortableGroup" => "assessment_points"
        },
        "to" => %{
          "momentId" => "#{moment.id}",
          "sortableHandle" => ".sortable-handle",
          "sortableEvent" => "sortable_ap_update",
          "sortableGroup" => "assessment_points"
        },
        "oldIndex" => 0,
        "newIndex" => 1
      })

      updated_ap1 = Lanttern.Repo.get!(Lanttern.Assessments.AssessmentPoint, ap1.id)
      updated_ap2 = Lanttern.Repo.get!(Lanttern.Assessments.AssessmentPoint, ap2.id)

      assert updated_ap2.position < updated_ap1.position
    end

    test "move assessment point between moments", %{conn: conn} do
      strand = insert(:strand)
      moment1 = insert(:moment, strand: strand)
      moment2 = insert(:moment, strand: strand)
      scale = insert(:scale)
      curriculum_item = insert(:curriculum_item)

      ap =
        AssessmentsFixtures.assessment_point_fixture(%{
          name: "AP to move",
          moment_id: moment1.id,
          scale_id: scale.id,
          curriculum_item_id: curriculum_item.id
        })

      {:ok, view, _html} = live(conn, "/strands/#{strand.id}/assessment")

      view
      |> element("#moment-#{moment1.id}-sortable-aps")
      |> render_hook("sortable_ap_update", %{
        "from" => %{
          "momentId" => "#{moment1.id}",
          "sortableHandle" => ".sortable-handle",
          "sortableEvent" => "sortable_ap_update",
          "sortableGroup" => "assessment_points"
        },
        "to" => %{
          "momentId" => "#{moment2.id}",
          "sortableHandle" => ".sortable-handle",
          "sortableEvent" => "sortable_ap_update",
          "sortableGroup" => "assessment_points"
        },
        "oldIndex" => 0,
        "newIndex" => 0
      })

      updated_ap = Lanttern.Repo.get!(Lanttern.Assessments.AssessmentPoint, ap.id)
      assert updated_ap.moment_id == moment2.id
    end
  end

  describe "composition overlay" do
    test "shows 'Add composition' button for AP without composition", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)
      insert(:assessment_point, name: "AP no composition", moment_id: moment.id)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> assert_has("button", text: "Add composition")
    end

    test "shows composition type button when AP uses composition", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)
      ap = insert(:assessment_point, name: "AP with avg composition", moment_id: moment.id)

      {:ok, _} =
        Assessments.update_assessment_point(%Lanttern.Identity.Scope{}, ap, %{
          uses_composition: true
        })

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> assert_has("button", text: "Uses composition")
    end

    test "opens composition overlay when clicking composition type button", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)
      ap = insert(:assessment_point, name: "AP with avg composition", moment_id: moment.id)

      {:ok, _} =
        Assessments.update_assessment_point(%Lanttern.Identity.Scope{}, ap, %{
          uses_composition: true
        })

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> click_button("Uses composition")
      |> assert_has("#ap-composition-overlay")
      |> assert_has("#ap-composition-overlay", text: "Grade composition")
    end

    test "composition overview shows existing components", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)
      ap = insert(:assessment_point, name: "Parent AP", moment_id: moment.id)

      {:ok, parent_ap} =
        Assessments.update_assessment_point(%Lanttern.Identity.Scope{}, ap, %{
          uses_composition: true
        })

      sibling_ap = insert(:assessment_point, name: "Sibling AP", moment_id: moment.id)
      insert(:assessment_point_component, parent: parent_ap, component: sibling_ap)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> click_button("button:not([role='menuitem'])", "Uses composition")
      |> assert_has("#ap-composition-overlay", text: "Sibling AP")
    end

    test "setup view shows sibling APs for selection", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)
      ap = insert(:assessment_point, name: "Parent AP", moment_id: moment.id)

      {:ok, _} =
        Assessments.update_assessment_point(%Lanttern.Identity.Scope{}, ap, %{
          uses_composition: true
        })

      sibling_ap = insert(:assessment_point, name: "Sibling AP to select", moment_id: moment.id)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> click_button("button:not([role='menuitem'])", "Uses composition")
      |> within("#ap-composition-overlay", fn session ->
        click_button(session, "Setup composition")
      end)
      |> assert_has("#ap-composition-overlay", text: sibling_ap.name)
    end

    test "save composition re-saves existing selection and returns to overview", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)
      ap = insert(:assessment_point, name: "Parent AP", moment_id: moment.id)

      {:ok, parent_ap} =
        Assessments.update_assessment_point(%Lanttern.Identity.Scope{}, ap, %{
          uses_composition: true
        })

      sibling_ap = insert(:assessment_point, name: "Sibling AP", moment_id: moment.id)
      insert(:assessment_point_component, parent: parent_ap, component: sibling_ap)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> click_button("button:not([role='menuitem'])", "Uses composition")
      |> within("#ap-composition-overlay", fn session ->
        click_button(session, "Manage composition")
      end)
      |> within("#ap-composition-overlay", fn session ->
        click_button(session, "Save")
      end)
      |> assert_has("#ap-composition-overlay", text: "Sibling AP")
    end

    test "delete composition removes components and closes overlay", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)
      ap = insert(:assessment_point, name: "Parent AP", moment_id: moment.id)

      {:ok, parent_ap} =
        Assessments.update_assessment_point(%Lanttern.Identity.Scope{}, ap, %{
          uses_composition: true
        })

      sibling_ap = insert(:assessment_point, name: "Sibling AP", moment_id: moment.id)
      insert(:assessment_point_component, parent: parent_ap, component: sibling_ap)

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> click_button("button:not([role='menuitem'])", "Uses composition")
      |> within("#ap-composition-overlay", fn session ->
        click_button(session, "Manage composition")
      end)
      |> within("#ap-composition-overlay", fn session ->
        click_button(session, "Delete")
      end)
      |> refute_has("#ap-composition-overlay")
      |> assert_has("button", text: "Add composition")
    end
  end

  describe "toggle_hidden" do
    test "clicking 'Hide' changes button label to 'Hidden'", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)
      scale = insert(:scale)
      ci = insert(:curriculum_item)

      AssessmentsFixtures.assessment_point_fixture(%{
        name: "Visible AP",
        moment_id: moment.id,
        scale_id: scale.id,
        curriculum_item_id: ci.id,
        is_hidden: false
      })

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> click_button("Hide")
      |> assert_has("button", text: "Hidden")
    end

    test "clicking 'Hidden' changes button label back to 'Hide'", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)
      scale = insert(:scale)
      ci = insert(:curriculum_item)

      AssessmentsFixtures.assessment_point_fixture(%{
        name: "Test AP",
        moment_id: moment.id,
        scale_id: scale.id,
        curriculum_item_id: ci.id,
        is_hidden: true
      })

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> click_button("Hidden")
      |> assert_has("button", text: "Hide")
    end
  end
end
