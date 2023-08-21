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

    test "get_assessment_point!/2 returns the assessment point with given id" do
      assessment_point = assessment_point_fixture()
      assert Assessments.get_assessment_point!(assessment_point.id) == assessment_point
    end

    test "get_assessment_point!/2 with preloads returns the assessment point with given id and preloaded data" do
      scale = Lanttern.GradingFixtures.scale_fixture()

      assessment_point =
        assessment_point_fixture(%{scale_id: scale.id})
        |> Map.put(:scale, scale)

      assert Assessments.get_assessment_point!(assessment_point.id, :scale) == assessment_point
    end

    test "create_assessment_point/1 with valid data creates a assessment point" do
      curriculum_item = Lanttern.CurriculaFixtures.item_fixture()
      scale = Lanttern.GradingFixtures.scale_fixture()

      valid_attrs = %{
        name: "some name",
        datetime: ~U[2023-08-02 15:30:00Z],
        description: "some description",
        curriculum_item_id: curriculum_item.id,
        scale_id: scale.id
      }

      assert {:ok, %AssessmentPoint{} = assessment_point} =
               Assessments.create_assessment_point(valid_attrs)

      assert assessment_point.name == "some name"
      assert assessment_point.datetime == ~U[2023-08-02 15:30:00Z]
      assert assessment_point.description == "some description"
      assert assessment_point.curriculum_item_id == curriculum_item.id
      assert assessment_point.scale_id == scale.id
    end

    test "create_assessment_point/1 with valid data containing classes creates an assessment point with linked classes" do
      curriculum_item = Lanttern.CurriculaFixtures.item_fixture()
      scale = Lanttern.GradingFixtures.scale_fixture()

      class_1 = Lanttern.SchoolsFixtures.class_fixture()
      class_2 = Lanttern.SchoolsFixtures.class_fixture()
      class_3 = Lanttern.SchoolsFixtures.class_fixture()

      valid_attrs = %{
        name: "some name",
        datetime: ~U[2023-08-02 15:30:00Z],
        description: "some description",
        curriculum_item_id: curriculum_item.id,
        scale_id: scale.id,
        classes_ids: [
          class_1.id,
          class_2.id,
          class_3.id
        ]
      }

      assert {:ok, %AssessmentPoint{} = assessment_point} =
               Assessments.create_assessment_point(valid_attrs)

      assert assessment_point.name == "some name"
      assert Enum.find(assessment_point.classes, fn c -> c.id == class_1.id end)
      assert Enum.find(assessment_point.classes, fn c -> c.id == class_2.id end)
      assert Enum.find(assessment_point.classes, fn c -> c.id == class_3.id end)
    end

    test "create_assessment_point/1 with students creates an assessment point with linked assessment point entries for each student" do
      curriculum_item = Lanttern.CurriculaFixtures.item_fixture()
      scale = Lanttern.GradingFixtures.scale_fixture()

      student_1 = Lanttern.SchoolsFixtures.student_fixture()
      student_2 = Lanttern.SchoolsFixtures.student_fixture()
      student_3 = Lanttern.SchoolsFixtures.student_fixture()

      valid_attrs = %{
        name: "some name",
        datetime: ~U[2023-08-02 15:30:00Z],
        description: "some description",
        curriculum_item_id: curriculum_item.id,
        scale_id: scale.id,
        students_ids: [
          student_1.id,
          student_2.id,
          student_3.id
        ]
      }

      assert {:ok, %AssessmentPoint{} = assessment_point} =
               Assessments.create_assessment_point(valid_attrs)

      assert assessment_point.name == "some name"
      assert Enum.find(assessment_point.entries, fn e -> e.student_id == student_1.id end)
      assert Enum.find(assessment_point.entries, fn e -> e.student_id == student_2.id end)
      assert Enum.find(assessment_point.entries, fn e -> e.student_id == student_3.id end)
    end

    test "create_assessment_point/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Assessments.create_assessment_point(@invalid_attrs)
    end

    test "update_assessment_point/2 with valid data updates the assessment" do
      assessment_point = assessment_point_fixture()

      update_attrs = %{
        name: "some updated name",
        datetime: ~U[2023-08-03 15:30:00Z],
        description: "some updated description"
      }

      assert {:ok, %AssessmentPoint{} = assessment_point} =
               Assessments.update_assessment_point(assessment_point, update_attrs)

      assert assessment_point.name == "some updated name"
      assert assessment_point.datetime == ~U[2023-08-03 15:30:00Z]
      assert assessment_point.description == "some updated description"
    end

    test "update_assessment_point/2 with valid data containing classes updates the assessment point" do
      class_1 = Lanttern.SchoolsFixtures.class_fixture()
      class_2 = Lanttern.SchoolsFixtures.class_fixture()
      class_3 = Lanttern.SchoolsFixtures.class_fixture()
      assessment_point = assessment_point_fixture(%{classes_ids: [class_1.id, class_2.id]})

      update_attrs = %{
        name: "some updated name",
        classes_ids: [class_1.id, class_3.id]
      }

      assert {:ok, %AssessmentPoint{} = assessment_point} =
               Assessments.update_assessment_point(assessment_point, update_attrs)

      assert assessment_point.name == "some updated name"
      assert length(assessment_point.classes) == 2
      assert Enum.find(assessment_point.classes, fn c -> c.id == class_1.id end)
      assert Enum.find(assessment_point.classes, fn c -> c.id == class_3.id end)
    end

    test "update_assessment_point/2 with invalid data returns error changeset" do
      assessment = assessment_point_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Assessments.update_assessment_point(assessment, @invalid_attrs)

      assert assessment == Assessments.get_assessment_point!(assessment.id)
    end

    test "delete_assessment_point/1 deletes the assessment point" do
      assessment_point = assessment_point_fixture()
      assert {:ok, %AssessmentPoint{}} = Assessments.delete_assessment_point(assessment_point)

      assert_raise Ecto.NoResultsError, fn ->
        Assessments.get_assessment_point!(assessment_point.id)
      end
    end

    test "change_assessment_point/1 returns an assessment point changeset with datetime related virtual fields" do
      local_datetime = Timex.local(~N[2020-10-01 12:34:56])
      assessment_point = assessment_point_fixture(%{datetime: local_datetime})
      changeset = Assessments.change_assessment_point(assessment_point)
      assert %Ecto.Changeset{} = changeset
      assert get_field(changeset, :date) == ~D[2020-10-01]
      assert get_field(changeset, :hour) == 12
      assert get_field(changeset, :minute) == 34
    end
  end

  describe "assessment_point_entries" do
    alias Lanttern.Assessments.AssessmentPointEntry

    import Lanttern.AssessmentsFixtures

    @invalid_attrs %{student_id: nil, score: nil}

    test "list_assessment_point_entries/1 returns all assessment_point_entries" do
      assessment_point_entry = assessment_point_entry_fixture()
      assert Assessments.list_assessment_point_entries() == [assessment_point_entry]
    end

    test "list_assessment_point_entries/1 with opts returns entries as expected" do
      assessment_point = assessment_point_fixture()
      student_1 = Lanttern.SchoolsFixtures.student_fixture()

      entry_1 =
        assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: student_1.id
        })

      student_2 = Lanttern.SchoolsFixtures.student_fixture()

      entry_2 =
        assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: student_2.id
        })

      # extra entry for filtering validation
      assessment_point_entry_fixture()

      entries =
        Assessments.list_assessment_point_entries(
          preloads: :student,
          assessment_point_id: assessment_point.id
        )

      # assert length to check filtering
      assert length(entries) == 2

      # assert students are preloaded
      expected_entry_1 = Enum.find(entries, fn e -> e.id == entry_1.id end)
      assert expected_entry_1.student == student_1

      expected_entry_2 = Enum.find(entries, fn e -> e.id == entry_2.id end)
      assert expected_entry_2.student == student_2
    end

    test "get_assessment_point_entry!/1 returns the assessment_point_entry with given id" do
      assessment_point_entry = assessment_point_entry_fixture()

      assert Assessments.get_assessment_point_entry!(assessment_point_entry.id) ==
               assessment_point_entry
    end

    test "create_assessment_point_entry/1 with valid data creates a assessment_point_entry" do
      assessment_point = assessment_point_fixture()
      student = Lanttern.SchoolsFixtures.student_fixture()

      valid_attrs = %{
        assessment_point_id: assessment_point.id,
        student_id: student.id,
        observation: "some observation"
      }

      assert {:ok, %AssessmentPointEntry{} = assessment_point_entry} =
               Assessments.create_assessment_point_entry(valid_attrs)

      assert assessment_point_entry.assessment_point_id == assessment_point.id
      assert assessment_point_entry.student_id == student.id
      assert assessment_point_entry.observation == "some observation"
    end

    test "create_assessment_point_entry/1 of type numeric with valid data creates a assessment_point_entry" do
      scale = Lanttern.GradingFixtures.scale_fixture(%{type: "numeric", start: 0, stop: 1})
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})
      student = Lanttern.SchoolsFixtures.student_fixture()

      valid_attrs = %{
        assessment_point_id: assessment_point.id,
        student_id: student.id,
        observation: "some observation",
        score: 0.5
      }

      assert {:ok, %AssessmentPointEntry{} = assessment_point_entry} =
               Assessments.create_assessment_point_entry(valid_attrs)

      assert assessment_point_entry.assessment_point_id == assessment_point.id
      assert assessment_point_entry.score == 0.5
    end

    test "create_assessment_point_entry/1 of type ordinal with valid data creates a assessment_point_entry" do
      scale = Lanttern.GradingFixtures.scale_fixture(%{type: "ordinal"})
      ordinal_value = Lanttern.GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id})
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})
      student = Lanttern.SchoolsFixtures.student_fixture()

      valid_attrs = %{
        assessment_point_id: assessment_point.id,
        student_id: student.id,
        observation: "some observation",
        ordinal_value_id: ordinal_value.id
      }

      assert {:ok, %AssessmentPointEntry{} = assessment_point_entry} =
               Assessments.create_assessment_point_entry(valid_attrs)

      assert assessment_point_entry.assessment_point_id == assessment_point.id
      assert assessment_point_entry.ordinal_value_id == ordinal_value.id
    end

    test "create_assessment_point_entry/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Assessments.create_assessment_point_entry(@invalid_attrs)
    end

    test "create_assessment_point_entry/1 with score out of scale returns error changeset" do
      scale = Lanttern.GradingFixtures.scale_fixture(%{type: "numeric", start: 0, stop: 10})
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})
      student = Lanttern.SchoolsFixtures.student_fixture()

      attrs = %{
        assessment_point_id: assessment_point.id,
        student_id: student.id,
        score: 11
      }

      assert {:error, %Ecto.Changeset{}} =
               Assessments.create_assessment_point_entry(attrs)
    end

    test "create_assestudent = Lanttern.SchoolsFixtures.student_fixture()ssment_point_entry/1 with ordinal_value out of scale returns error changeset" do
      scale = Lanttern.GradingFixtures.scale_fixture(%{type: "ordinal"})
      _ordinal_value = Lanttern.GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id})
      other_ordinal_value = Lanttern.GradingFixtures.ordinal_value_fixture()
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})
      student = Lanttern.SchoolsFixtures.student_fixture()

      attrs = %{
        assessment_point_id: assessment_point.id,
        student_id: student.id,
        ordinal_value_id: other_ordinal_value.id
      }

      assert {:error, %Ecto.Changeset{}} =
               Assessments.create_assessment_point_entry(attrs)
    end

    test "update_assessment_point_entry/3 with valid data updates the assessment_point_entry" do
      assessment_point_entry = assessment_point_entry_fixture()
      update_attrs = %{observation: "some updated observation"}

      assert {:ok, %AssessmentPointEntry{} = assessment_point_entry} =
               Assessments.update_assessment_point_entry(assessment_point_entry, update_attrs)

      assert assessment_point_entry.observation == "some updated observation"
    end

    test "update_assessment_point_entry/3 with valid data and preloads updates the assessment_point_entry and return it with preloaded data" do
      student = Lanttern.SchoolsFixtures.student_fixture()
      assessment_point_entry = assessment_point_entry_fixture(%{student_id: student.id})
      update_attrs = %{observation: "some updated observation"}

      assert {:ok, %AssessmentPointEntry{} = assessment_point_entry} =
               Assessments.update_assessment_point_entry(assessment_point_entry, update_attrs,
                 preloads: :student
               )

      assert assessment_point_entry.student == student
    end

    test "update_assessment_point_entry/3 with invalid data returns error changeset" do
      assessment_point_entry = assessment_point_entry_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Assessments.update_assessment_point_entry(assessment_point_entry, @invalid_attrs)

      assert assessment_point_entry ==
               Assessments.get_assessment_point_entry!(assessment_point_entry.id)
    end

    test "delete_assessment_point_entry/1 deletes the assessment_point_entry" do
      assessment_point_entry = assessment_point_entry_fixture()

      assert {:ok, %AssessmentPointEntry{}} =
               Assessments.delete_assessment_point_entry(assessment_point_entry)

      assert_raise Ecto.NoResultsError, fn ->
        Assessments.get_assessment_point_entry!(assessment_point_entry.id)
      end
    end

    test "change_assessment_point_entry/1 returns a assessment_point_entry changeset" do
      assessment_point_entry = assessment_point_entry_fixture()
      assert %Ecto.Changeset{} = Assessments.change_assessment_point_entry(assessment_point_entry)
    end
  end
end
