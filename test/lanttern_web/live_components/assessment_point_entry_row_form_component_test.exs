defmodule LantternWeb.AssessmentPointEntryRowFormComponentTest do
  use LantternWeb.ConnCase

  alias Lanttern.AssessmentsFixtures
  alias Lanttern.CurriculaFixtures
  alias Lanttern.GradingFixtures

  @live_view_path_base "/assessment_points"

  describe "Edit assessment point entries in assessment point details live view" do
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

    test "update assessment point entries with invalid data when scale is numeric flashes an error message",
         %{conn: conn} do
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

      # send change event to form
      view
      |> element("form")
      |> render_change(%{
        "assessment_point_entry" => %{
          "score" => "11"
        }
      })

      # assert flash message
      render(view) =~ "score should be between 0.0 and 10.0"

      # assert entry in DB didn't change
      assert updated_entry = Lanttern.Assessments.get_assessment_point_entry!(entry.id)
      assert updated_entry.score == 5
    end
  end
end
