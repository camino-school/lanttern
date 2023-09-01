defmodule LantternWeb.AssessmentPointUpdateOverlayComponentTest do
  use LantternWeb.ConnCase

  import Lanttern.AssessmentsFixtures

  @live_view_path_base "/assessment_points"

  describe "Update assessment point in assessment point details live view" do
    test "overlay shows in live view", %{conn: conn} do
      assessment_point = assessment_point_fixture()
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # confirms overlay is not rendered
      refute view
             |> element("h2", "Update assessment point")
             |> has_element?()

      # click button to render
      view
      |> element("button", "Edit")
      |> render_click()

      # assert overlay is rendered
      assert view
             |> element("h2", "Update assessment point")
             |> render() =~ "Update assessment point"
    end

    test "submit valid form saves and update view", %{conn: conn} do
      curriculum_item = Lanttern.CurriculaFixtures.curriculum_item_fixture()
      scale = Lanttern.GradingFixtures.scale_fixture()

      assessment_point =
        assessment_point_fixture(%{
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id
        })

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # open overlay
      view
      |> element("button", "Edit")
      |> render_click()

      # validate form rendered with correct initial values
      assert view |> has_element?("input[value='#{assessment_point.name}']")
      assert view |> has_element?("textarea", assessment_point.description)
      assert view |> has_element?("select option[selected][value=#{curriculum_item.id}]")

      # TODO: uncomment
      # scale temporary disabled to avoid breaking UI when assessment already has registered entries
      # assert view |> has_element?("select option[selected][value=#{scale.id}]")

      # submit with extra info
      other_curriculum_item = Lanttern.CurriculaFixtures.curriculum_item_fixture()
      # TODO: uncomment
      # scale temporary disabled to avoid breaking UI when assessment already has registered entries
      # other_scale = Lanttern.GradingFixtures.scale_fixture()

      view
      |> element("#update-assessment-point-form")
      |> render_submit(%{
        "assessment_point" => %{
          "name" => "updated name",
          "description" => "updated description",
          "curriculum_item_id" => other_curriculum_item.id
          # TODO: uncomment
          # scale temporary disabled to avoid breaking UI when assessment already has registered entries
          # "scale_id" => other_scale.id
        }
      })

      {path, flash} = assert_redirect(view)
      assert path == "#{@live_view_path_base}/#{assessment_point.id}"
      assert %{"info" => "Assessment point updated!"} = flash

      # assert updated assessment point
      assert updated = Lanttern.Assessments.get_assessment_point!(assessment_point.id)

      assert updated.name == "updated name"
      assert updated.description == "updated description"
      assert updated.curriculum_item_id == other_curriculum_item.id

      # TODO: uncomment
      # scale temporary disabled to avoid breaking UI when assessment already has registered entries
      # assert updated.scale_id == other_scale.id
    end

    test "submit invalid form prevents save/redirect", %{conn: conn} do
      assessment_point = assessment_point_fixture()
      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # open overlay
      view
      |> element("button", "Edit")
      |> render_click()

      # submit
      assert view
             |> element("#update-assessment-point-form")
             |> render_submit(%{
               "assessment_point" => %{"name" => ""}
             }) =~ "Oops, something went wrong! Please check the errors below."
    end
  end
end
