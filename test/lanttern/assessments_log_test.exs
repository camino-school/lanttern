defmodule Lanttern.AssessmentsLogTest do
  use Lanttern.DataCase

  alias Lanttern.AssessmentsLog

  describe "assessment_point_entries" do
    alias Lanttern.AssessmentsLog.AssessmentPointEntryLog

    import Lanttern.AssessmentsLogFixtures

    @invalid_attrs %{
      assessment_point_entry_id: nil,
      profile_id: nil,
      operation: nil,
      observation: nil,
      score: nil,
      assessment_point_id: nil,
      student_id: nil,
      ordinal_value_id: nil,
      scale_id: nil,
      scale_type: nil,
      differentiation_rubric_id: nil,
      report_note: nil
    }

    test "list_assessment_point_entries_logs/0 returns all assessment_point_entries" do
      assessment_point_entry_log = assessment_point_entry_log_fixture()
      assert AssessmentsLog.list_assessment_point_entries_logs() == [assessment_point_entry_log]
    end

    test "get_assessment_point_entry_log!/1 returns the assessment_point_entry with given id" do
      assessment_point_entry_log = assessment_point_entry_log_fixture()

      assert AssessmentsLog.get_assessment_point_entry_log!(assessment_point_entry_log.id) ==
               assessment_point_entry_log
    end

    test "create_assessment_point_entry_log/1 with valid data creates a assessment_point_entry" do
      valid_attrs = %{
        assessment_point_entry_id: 42,
        profile_id: 42,
        operation: "UPDATE",
        observation: "some observation",
        score: 120.5,
        assessment_point_id: 42,
        student_id: 42,
        ordinal_value_id: 42,
        scale_id: 42,
        scale_type: "some scale_type",
        differentiation_rubric_id: 42,
        report_note: "some report_note"
      }

      assert {:ok, %AssessmentPointEntryLog{} = assessment_point_entry_log} =
               AssessmentsLog.create_assessment_point_entry_log(valid_attrs)

      assert assessment_point_entry_log.assessment_point_entry_id == 42
      assert assessment_point_entry_log.profile_id == 42
      assert assessment_point_entry_log.operation == "UPDATE"
      assert assessment_point_entry_log.observation == "some observation"
      assert assessment_point_entry_log.score == 120.5
      assert assessment_point_entry_log.assessment_point_id == 42
      assert assessment_point_entry_log.student_id == 42
      assert assessment_point_entry_log.ordinal_value_id == 42
      assert assessment_point_entry_log.scale_id == 42
      assert assessment_point_entry_log.scale_type == "some scale_type"
      assert assessment_point_entry_log.differentiation_rubric_id == 42
      assert assessment_point_entry_log.report_note == "some report_note"
    end

    test "create_assessment_point_entry_log/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               AssessmentsLog.create_assessment_point_entry_log(@invalid_attrs)
    end
  end
end
