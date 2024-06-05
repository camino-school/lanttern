defmodule LantternWeb.AssessmentsHelpersTest do
  use Lanttern.DataCase

  alias LantternWeb.AssessmentsHelpers

  describe "save entry editor component changes" do
    import Lanttern.AssessmentsFixtures
    alias Lanttern.GradingFixtures
    alias Lanttern.SchoolsFixtures

    test "save_entry_editor_component_changes/2 handles all mapped changes correctly" do
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ov_1 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0})
      ov_2 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 1})

      student = SchoolsFixtures.student_fixture()

      assessment_point_1 = assessment_point_fixture(%{scale_id: scale.id})
      assessment_point_2 = assessment_point_fixture(%{scale_id: scale.id})
      assessment_point_3 = assessment_point_fixture(%{scale_id: scale.id})

      entry_2 =
        assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point_2.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_1.id
        })

      entry_3 =
        assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point_3.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_1.id
        })

      params_1 = %{
        "student_id" => student.id,
        "scale_id" => scale.id,
        "scale_type" => scale.type,
        "assessment_point_id" => assessment_point_1.id,
        "ordinal_value_id" => ov_1.id
      }

      params_2 = %{"ordinal_value_id" => ov_2.id}
      params_3 = %{}

      changes_map = %{
        "1" => {:new, nil, params_1},
        "2" => {:edit, entry_2.id, params_2},
        "3" => {:delete, entry_3.id, params_3}
      }

      assert {:ok, results_message} =
               AssessmentsHelpers.save_entry_editor_component_changes(changes_map)

      assert String.contains?(results_message, "1 entry created")
      assert String.contains?(results_message, "1 entry updated")
      assert String.contains?(results_message, "1 entry removed")
    end
  end
end
