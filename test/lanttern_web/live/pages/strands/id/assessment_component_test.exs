defmodule LantternWeb.StrandLive.AssessmentComponentTest do
  use LantternWeb.ConnCase

  import Lanttern.Factory
  import PhoenixTest

  alias Lanttern.AssessmentsFixtures
  alias Lanttern.CurriculaFixtures
  alias Lanttern.GradingFixtures

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
      scale = GradingFixtures.scale_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()

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
      curriculum_component = CurriculaFixtures.curriculum_component_fixture()

      curriculum_item =
        CurriculaFixtures.curriculum_item_fixture(%{
          curriculum_component_id: curriculum_component.id,
          name: "CI name xyz"
        })

      scale = GradingFixtures.scale_fixture()

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
    test "create moment assessment point", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand, name: "Test Moment")
      scale = GradingFixtures.scale_fixture(%{name: "Test Scale"})
      curriculum_component = CurriculaFixtures.curriculum_component_fixture()

      curriculum_item =
        CurriculaFixtures.curriculum_item_fixture(%{
          curriculum_component_id: curriculum_component.id,
          name: "CI for moment AP"
        })

      # Create a strand-level AP so that curriculum item is available in the moment AP dropdown
      AssessmentsFixtures.assessment_point_fixture(%{
        strand_id: strand.id,
        scale_id: scale.id,
        curriculum_item_id: curriculum_item.id
      })

      conn
      |> visit("#{@live_view_base_path}/#{strand.id}/assessment")
      |> click_button("#new-moment-assessment button", moment.name)
      |> fill_in("Assessment point name", with: "New moment AP")
      |> select("Scale", option: "Test Scale")
      |> select("Curriculum item", option: "(#{curriculum_component.name}) CI for moment AP")
      |> click_button("Save")
      |> assert_has("button", text: "New moment AP")
    end

    test "update moment assessment point name", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)
      scale = GradingFixtures.scale_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()

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

    test "delete moment assessment point", %{conn: conn} do
      strand = insert(:strand)
      moment = insert(:moment, strand: strand)
      scale = GradingFixtures.scale_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()

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
      scale = GradingFixtures.scale_fixture()
      curriculum_item_1 = CurriculaFixtures.curriculum_item_fixture()
      curriculum_item_2 = CurriculaFixtures.curriculum_item_fixture()

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
      scale = GradingFixtures.scale_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()

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
end
