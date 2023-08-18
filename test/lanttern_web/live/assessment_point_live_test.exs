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
        datetime: datetime
      } =
        AssessmentsFixtures.assessment_point_fixture(attrs)

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{id}")

      assert view |> has_element?("h2", name)
      assert view |> has_element?("p", description)

      assert view
             |> has_element?(
               "div",
               Timex.format!(Timex.local(datetime), "{Mshort} {D}, {YYYY}, {h12}:{m} {am}")
             )

      assert view |> has_element?("div", curriculum_item.name)
      assert view |> has_element?("div", scale.name)
    end

    test "redirect to /assessment_points when supplied id does not exist", %{conn: conn} do
      wrong_id = "1000000"

      {:error, {:redirect, %{to: path, flash: flash}}} =
        live(conn, "#{@live_view_path_base}/#{wrong_id}")

      assert path == "/assessment_points"
      assert flash["error"] == "Couldn't find assessment point"
    end

    test "redirect to /assessment_points when supplied id is string", %{conn: conn} do
      wrong_id = "abcd"

      {:error, {:redirect, %{to: path, flash: flash}}} =
        live(conn, "#{@live_view_path_base}/#{wrong_id}")

      assert path == "/assessment_points"
      assert flash["error"] == "Couldn't find assessment point"
    end

    test "update assessment point entries when scale is ordinal", %{conn: conn} do
      curriculum_item = CurriculaFixtures.item_fixture()
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ordinal_value_1 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id})
      ordinal_value_2 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id})

      assessment_point =
        AssessmentsFixtures.assessment_point_fixture(%{
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id
        })

      entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          observation: "initial obs",
          ordinal_value_id: ordinal_value_1.id
        })

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # validate if ordinal value and observation fields rendered with initial values
      view
      |> element("select option[selected][value=#{ordinal_value_1.id}]")
      |> has_element?()

      view
      |> element("textarea", "initial obs")
      |> has_element?()

      # send change event to form
      view
      |> element("form")
      |> render_change(%{
        "assessment_point_entry" => %{
          "ordinal_value_id" => ordinal_value_2.id,
          "observation" => "updated observation"
        }
      })

      # validate if ordinal value and observation fields rendered with updated values
      view
      |> element("select option[selected][value=#{ordinal_value_2.id}]")
      |> has_element?()

      view
      |> element("textarea", "updated observation")
      |> has_element?()

      # assert updated entry in DB
      assert updated_entry = Lanttern.Assessments.get_assessment_point_entry!(entry.id)
      assert updated_entry.ordinal_value_id == ordinal_value_2.id
      assert updated_entry.observation == "updated observation"
    end

    test "update assessment point entries when scale is numeric", %{conn: conn} do
      curriculum_item = CurriculaFixtures.item_fixture()
      scale = GradingFixtures.scale_fixture(%{type: "numeric", start: 0, stop: 10})

      assessment_point =
        AssessmentsFixtures.assessment_point_fixture(%{
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id
        })

      entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          observation: "initial obs",
          score: 5
        })

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # validate if score and observation fields rendered with initial values
      view
      |> element("input[type=number]", "5")
      |> has_element?()

      view
      |> element("textarea", "initial obs")
      |> has_element?()

      # send change event to form
      view
      |> element("form")
      |> render_change(%{
        "assessment_point_entry" => %{
          "score" => "6",
          "observation" => "updated observation"
        }
      })

      # validate if score and observation fields rendered with updated values
      view
      |> element("input[type=number]", "6")
      |> has_element?()

      view
      |> element("textarea", "updated observation")
      |> has_element?()

      # assert updated entry in DB
      assert updated_entry = Lanttern.Assessments.get_assessment_point_entry!(entry.id)
      assert updated_entry.score == 6
      assert updated_entry.observation == "updated observation"
    end
  end
end
