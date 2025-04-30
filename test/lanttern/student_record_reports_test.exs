defmodule Lanttern.StudentRecordReportsTest do
  use Lanttern.DataCase

  alias Lanttern.StudentRecordReports

  describe "student_record_report_ai_config" do
    alias Lanttern.StudentRecordReports.StudentRecordReportAIConfig

    import Lanttern.StudentRecordReportsFixtures
    import Lanttern.SchoolsFixtures

    @invalid_attrs %{
      summary_instructions: nil,
      update_instructions: nil,
      model: nil,
      cooldown_minutes: nil,
      school_id: nil
    }

    test "list_student_record_report_ai_config/0 returns all student_record_report_ai_config" do
      student_record_report_ai_config = student_record_report_ai_config_fixture()

      assert StudentRecordReports.list_student_record_report_ai_config() == [
               student_record_report_ai_config
             ]
    end

    test "get_student_record_report_ai_config!/1 returns the student_record_report_ai_config with given id" do
      student_record_report_ai_config = student_record_report_ai_config_fixture()

      assert StudentRecordReports.get_student_record_report_ai_config!(
               student_record_report_ai_config.id
             ) == student_record_report_ai_config
    end

    test "create_student_record_report_ai_config/1 with valid data creates a student_record_report_ai_config" do
      school = school_fixture()

      valid_attrs = %{
        summary_instructions: "some summary_instructions",
        update_instructions: "some update_instructions",
        model: "some model",
        cooldown_minutes: 42,
        school_id: school.id
      }

      assert {:ok, %StudentRecordReportAIConfig{} = student_record_report_ai_config} =
               StudentRecordReports.create_student_record_report_ai_config(valid_attrs)

      assert student_record_report_ai_config.summary_instructions == "some summary_instructions"
      assert student_record_report_ai_config.update_instructions == "some update_instructions"
      assert student_record_report_ai_config.model == "some model"
      assert student_record_report_ai_config.cooldown_minutes == 42
      assert student_record_report_ai_config.school_id == school.id
    end

    test "create_student_record_report_ai_config/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               StudentRecordReports.create_student_record_report_ai_config(@invalid_attrs)
    end

    test "update_student_record_report_ai_config/2 with valid data updates the student_record_report_ai_config" do
      student_record_report_ai_config = student_record_report_ai_config_fixture()

      update_attrs = %{
        summary_instructions: "some updated summary_instructions",
        update_instructions: "some updated update_instructions",
        model: "some updated model",
        cooldown_minutes: 43
      }

      assert {:ok, %StudentRecordReportAIConfig{} = student_record_report_ai_config} =
               StudentRecordReports.update_student_record_report_ai_config(
                 student_record_report_ai_config,
                 update_attrs
               )

      assert student_record_report_ai_config.summary_instructions ==
               "some updated summary_instructions"

      assert student_record_report_ai_config.update_instructions ==
               "some updated update_instructions"

      assert student_record_report_ai_config.model == "some updated model"
      assert student_record_report_ai_config.cooldown_minutes == 43
    end

    test "update_student_record_report_ai_config/2 with invalid data returns error changeset" do
      student_record_report_ai_config = student_record_report_ai_config_fixture()

      assert {:error, %Ecto.Changeset{}} =
               StudentRecordReports.update_student_record_report_ai_config(
                 student_record_report_ai_config,
                 @invalid_attrs
               )

      assert student_record_report_ai_config ==
               StudentRecordReports.get_student_record_report_ai_config!(
                 student_record_report_ai_config.id
               )
    end

    test "delete_student_record_report_ai_config/1 deletes the student_record_report_ai_config" do
      student_record_report_ai_config = student_record_report_ai_config_fixture()

      assert {:ok, %StudentRecordReportAIConfig{}} =
               StudentRecordReports.delete_student_record_report_ai_config(
                 student_record_report_ai_config
               )

      assert_raise Ecto.NoResultsError, fn ->
        StudentRecordReports.get_student_record_report_ai_config!(
          student_record_report_ai_config.id
        )
      end
    end

    test "change_student_record_report_ai_config/1 returns a student_record_report_ai_config changeset" do
      student_record_report_ai_config = student_record_report_ai_config_fixture()

      assert %Ecto.Changeset{} =
               StudentRecordReports.change_student_record_report_ai_config(
                 student_record_report_ai_config
               )
    end
  end
end
