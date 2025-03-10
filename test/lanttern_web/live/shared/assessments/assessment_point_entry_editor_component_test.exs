defmodule LantternWeb.Assessments.AssessmentPointEntryEditorComponentTest do
  use LantternWeb.ConnCase

  alias Lanttern.AssessmentsFixtures
  alias Lanttern.CurriculaFixtures
  alias Lanttern.GradingFixtures

  @live_view_path_base "/assessment_points"

  setup [:register_and_log_in_root_admin, :register_and_log_in_staff_member]

  describe "Edit assessment point entries in assessment point details live view" do
    test "update assessment point entries when scale is ordinal", %{conn: conn} do
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()
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
          ordinal_value_id: ordinal_value_1.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      form_selector = "#entry-#{entry.id}-marking-form"

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # validate if ordinal value and observation fields rendered with initial values
      assert view
             |> element("#{form_selector} select option[selected][value=#{ordinal_value_1.id}]")
             |> has_element?()

      assert view
             |> element("#{form_selector} textarea", "initial obs")
             |> has_element?()

      # send change event to form
      view
      |> element(form_selector)
      |> render_change(%{
        "assessment_point_entry" => %{
          "ordinal_value_id" => ordinal_value_2.id,
          "observation" => "updated observation"
        }
      })

      # validate if ordinal value and observation fields rendered with updated values
      assert view
             |> element("#{form_selector} select option[selected][value=#{ordinal_value_2.id}]")
             |> has_element?()

      assert view
             |> element("#{form_selector} textarea", "updated observation")
             |> has_element?()

      # assert updated entry in DB
      assert updated_entry = Lanttern.Assessments.get_assessment_point_entry!(entry.id)
      assert updated_entry.ordinal_value_id == ordinal_value_2.id
      assert updated_entry.observation == "updated observation"
    end

    test "update assessment point entries when scale is numeric", %{conn: conn} do
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()
      scale = GradingFixtures.scale_fixture(%{type: "numeric", start: 0, stop: 10})

      assessment_point =
        AssessmentsFixtures.assessment_point_fixture(%{
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id
        })

      entry =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          scale_id: scale.id,
          observation: "initial obs",
          score: 5
        })

      form_selector = "#entry-#{entry.id}-marking-form"

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # validate if score and observation fields rendered with initial values
      assert view
             |> element("#{form_selector} input[type=number][value='5.0']")
             |> has_element?()

      assert view
             |> element("#{form_selector} textarea", "initial obs")
             |> has_element?()

      # send change event to form
      view
      |> element(form_selector)
      |> render_change(%{
        "assessment_point_entry" => %{
          "score" => "6",
          "observation" => "updated observation"
        }
      })

      # validate if score and observation fields rendered with updated values
      assert view
             |> element("#{form_selector} input[type=number][value='6.0']")
             |> has_element?()

      assert view
             |> element("#{form_selector} textarea", "updated observation")
             |> has_element?()

      # assert updated entry in DB
      assert updated_entry = Lanttern.Assessments.get_assessment_point_entry!(entry.id)
      assert updated_entry.score == 6
      assert updated_entry.observation == "updated observation"
    end

    test "update assessment point entries with invalid data when scale is numeric flashes an error message",
         %{conn: conn} do
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()
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
          score: 5,
          scale_id: scale.id,
          scale_type: scale.type
        })

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/#{assessment_point.id}")

      # send change event to form
      view
      |> element("#entry-#{entry.id}-marking-form")
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
