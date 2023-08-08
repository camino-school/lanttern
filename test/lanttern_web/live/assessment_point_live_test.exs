defmodule LantternWeb.AssessmentPointLiveTest do
  use LantternWeb.ConnCase

  alias Lanttern.AssessmentsFixtures
  alias Lanttern.CurriculaFixtures
  alias Lanttern.GradingFixtures

  @live_view_path_base "/assessment_points"

  describe "Assessment points explorer live view" do
    test "disconnected and connected mount", %{conn: conn} do
      %{id: id} = AssessmentsFixtures.assessment_point_fixture()

      conn = get(conn, "#{@live_view_path_base}/#{id}")
      assert html_response(conn, 200) =~ ~r/<h1 .+>Assessment point details<\/h1>/

      {:ok, _view, _html} = live(conn)
    end

    test "display assessment point details", %{conn: conn} do
      curriculum_item = CurriculaFixtures.item_fixture()
      scale = GradingFixtures.scale_fixture()
      attrs = %{curriculum_item_id: curriculum_item.id, scale: scale.id}

      %{
        id: id,
        name: name,
        description: description,
        date: date
      } =
        AssessmentsFixtures.assessment_point_fixture(attrs)

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{id}")

      assert view |> has_element?("h2", name)
      assert view |> has_element?("p", description)

      assert view
             |> has_element?("div", Timex.format!(date, "{Mshort} {D}, {YYYY}, {h12}:{m} {am}"))

      assert view |> has_element?("div", curriculum_item.name)
      assert view |> has_element?("div", scale.name)
    end

    test "redirect to /assessment_points when supplied id does not exist", %{conn: conn} do
      %{id: id} = AssessmentsFixtures.assessment_point_fixture()
      wrong_id = "#{id}000000"

      {:error, {:redirect, %{to: path, flash: flash}}} =
        live(conn, "#{@live_view_path_base}/#{wrong_id}")

      assert path == "/assessment_points"
      assert flash["error"] == "Assessment point id #{wrong_id} does not exist"
    end
  end
end
