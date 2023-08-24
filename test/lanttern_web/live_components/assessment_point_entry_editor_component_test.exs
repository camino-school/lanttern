defmodule LantternWeb.AssessmentPointEntryEditorComponentTest do
  use LantternWeb.ConnCase

  alias Lanttern.AssessmentsFixtures
  alias Lanttern.CurriculaFixtures
  alias Lanttern.GradingFixtures
  alias Lanttern.SchoolsFixtures

  @live_view_path_base "/assessment_points"

  describe "Edit assessment point entries in assessment points explorer live view" do
    test "update assessment points", %{conn: conn} do
      curriculum_item = CurriculaFixtures.item_fixture()
      numeric_scale = GradingFixtures.scale_fixture(%{type: "numeric", start: 0.0, stop: 1.0})
      ordinal_scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ordinal_value_1 = GradingFixtures.ordinal_value_fixture(%{scale_id: ordinal_scale.id})
      ordinal_value_2 = GradingFixtures.ordinal_value_fixture(%{scale_id: ordinal_scale.id})
      ordinal_value_3 = GradingFixtures.ordinal_value_fixture(%{scale_id: ordinal_scale.id})
      std_1 = SchoolsFixtures.student_fixture()
      std_2 = SchoolsFixtures.student_fixture()
      std_3 = SchoolsFixtures.student_fixture()

      assessment_point_ordinal =
        AssessmentsFixtures.assessment_point_fixture(%{
          curriculum_item_id: curriculum_item.id,
          scale_id: ordinal_scale.id
        })

      assessment_point_numeric =
        AssessmentsFixtures.assessment_point_fixture(%{
          curriculum_item_id: curriculum_item.id,
          scale_id: numeric_scale.id
        })

      entry_ordinal_1 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point_ordinal.id,
          ordinal_value_id: ordinal_value_1.id,
          student_id: std_1.id
        })

      entry_ordinal_3 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point_ordinal.id,
          ordinal_value_id: ordinal_value_3.id,
          student_id: std_3.id
        })

      entry_numeric_2 =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point_numeric.id,
          score: 0.5,
          student_id: std_2.id
        })

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/explorer")

      # validate if live components rendered with initial values
      view
      |> element("select option[selected][value=#{ordinal_value_1.id}]")
      |> has_element?()

      view
      |> element("select option[selected][value=#{ordinal_value_3.id}]")
      |> has_element?()

      view
      |> element("input", "0.5")
      |> has_element?()

      # send change event to form ordinal 1, validate view update, and validate entry in db
      view
      |> element("#entry-#{entry_ordinal_1.id}-marking-form")
      |> render_change(%{
        "assessment_point_entry" => %{
          "ordinal_value_id" => ordinal_value_2.id,
          "observation" => "updated observation"
        }
      })

      view
      |> element(
        "#entry-#{entry_ordinal_1.id}-marking-form select option[selected][value=#{ordinal_value_2.id}]"
      )
      |> has_element?()

      assert updated_entry_ordinal_1 =
               Lanttern.Assessments.get_assessment_point_entry!(entry_ordinal_1.id)

      assert updated_entry_ordinal_1.ordinal_value_id == ordinal_value_2.id

      # send change event to form ordinal 3, validate view update, and validate entry in db
      view
      |> element("#entry-#{entry_ordinal_3.id}-marking-form")
      |> render_change(%{
        "assessment_point_entry" => %{
          "ordinal_value_id" => ordinal_value_2.id,
          "observation" => "updated observation"
        }
      })

      view
      |> element(
        "#entry-#{entry_ordinal_3.id}-marking-form select option[selected][value=#{ordinal_value_2.id}]"
      )
      |> has_element?()

      assert updated_entry_ordinal_3 =
               Lanttern.Assessments.get_assessment_point_entry!(entry_ordinal_3.id)

      assert updated_entry_ordinal_3.ordinal_value_id == ordinal_value_2.id

      # send change event to form numeric 2, validate view update, and validate entry in db
      view
      |> element("#entry-#{entry_numeric_2.id}-marking-form")
      |> render_change(%{
        "assessment_point_entry" => %{
          "score" => "1",
          "observation" => "updated observation"
        }
      })

      view
      |> element("#entry-#{entry_numeric_2.id}-marking-form input", "1.0")
      |> has_element?()

      assert updated_entry_numeric_2 =
               Lanttern.Assessments.get_assessment_point_entry!(entry_numeric_2.id)

      assert updated_entry_numeric_2.score == 1.0
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
          score: 5
        })

      {:ok, view, _html} = live(conn, "#{@live_view_path_base}/explorer")

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
