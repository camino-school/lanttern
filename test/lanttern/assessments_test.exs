defmodule Lanttern.AssessmentsTest do
  use Lanttern.DataCase

  alias Lanttern.Assessments

  describe "assessment_points" do
    alias Lanttern.Assessments.AssessmentPoint

    import Lanttern.AssessmentsFixtures

    @invalid_attrs %{name: nil, date: nil, description: nil}

    test "list_assessment_points/0 returns all assessments" do
      assessment_point = assessment_point_fixture()
      assert Assessments.list_assessment_points() == [assessment_point]
    end

    test "get_assessment_point!/1 returns the assessment point with given id" do
      assessment_point = assessment_point_fixture()
      assert Assessments.get_assessment_point!(assessment_point.id) == assessment_point
    end

    test "create_assessment_point/1 with valid data creates a assessment point" do
      curriculum_item = Lanttern.CurriculaFixtures.item_fixture()
      scale = Lanttern.GradingFixtures.scale_fixture()

      valid_attrs = %{
        name: "some name",
        date: ~U[2023-08-02 15:30:00Z],
        description: "some description",
        curriculum_item_id: curriculum_item.id,
        scale_id: scale.id
      }

      assert {:ok, %AssessmentPoint{} = assessment_point} =
               Assessments.create_assessment_point(valid_attrs)

      assert assessment_point.name == "some name"
      assert assessment_point.date == ~U[2023-08-02 15:30:00Z]
      assert assessment_point.description == "some description"
      assert assessment_point.curriculum_item_id == curriculum_item.id
      assert assessment_point.scale_id == scale.id
    end

    test "create_assessment_point/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Assessments.create_assessment_point(@invalid_attrs)
    end

    test "update_assessment_point/2 with valid data updates the assessment" do
      assessment_point = assessment_point_fixture()

      update_attrs = %{
        name: "some updated name",
        date: ~U[2023-08-03 15:30:00Z],
        description: "some updated description"
      }

      assert {:ok, %AssessmentPoint{} = assessment_point} =
               Assessments.update_assessment_point(assessment_point, update_attrs)

      assert assessment_point.name == "some updated name"
      assert assessment_point.date == ~U[2023-08-03 15:30:00Z]
      assert assessment_point.description == "some updated description"
    end

    test "update_assessment_point/2 with invalid data returns error changeset" do
      assessment = assessment_point_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Assessments.update_assessment_point(assessment, @invalid_attrs)

      assert assessment == Assessments.get_assessment_point!(assessment.id)
    end

    test "delete_assessment_point/1 deletes the assessment" do
      assessment_point = assessment_point_fixture()
      assert {:ok, %AssessmentPoint{}} = Assessments.delete_assessment_point(assessment_point)

      assert_raise Ecto.NoResultsError, fn ->
        Assessments.get_assessment_point!(assessment_point.id)
      end
    end

    test "change_assessment_point/1 returns a assessment changeset" do
      assessment_point = assessment_point_fixture()
      assert %Ecto.Changeset{} = Assessments.change_assessment_point(assessment_point)
    end
  end
end
