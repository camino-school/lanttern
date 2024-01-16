defmodule Lanttern.AssessmentsTest do
  use Lanttern.DataCase

  alias Lanttern.Assessments

  describe "assessment_points" do
    alias Lanttern.Assessments.AssessmentPoint

    import Lanttern.AssessmentsFixtures

    @invalid_attrs %{name: nil, date: nil, description: nil}

    test "list_assessment_points/1 returns all assessments" do
      assessment_point = assessment_point_fixture()
      assert Assessments.list_assessment_points() == [assessment_point]
    end

    test "list_assessment_points/1 with opts returns assessments as expected" do
      scale = Lanttern.GradingFixtures.scale_fixture(%{type: "ordinal"})
      ordinal_value = Lanttern.GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id})
      assessment_point_1 = assessment_point_fixture(%{scale_id: scale.id})
      assessment_point_2 = assessment_point_fixture(%{scale_id: scale.id})

      # extra assessment point for filtering validation
      assessment_point_fixture()

      assessments =
        Assessments.list_assessment_points(
          preloads: [scale: :ordinal_values],
          assessment_points_ids: [assessment_point_1.id, assessment_point_2.id]
        )

      # assert length to check filtering
      assert length(assessments) == 2

      # assert scales and ordinal values are preloaded
      expected_assessment_1 = Enum.find(assessments, fn a -> a.id == assessment_point_1.id end)
      assert expected_assessment_1.scale_id == scale.id
      assert expected_assessment_1.scale.ordinal_values == [ordinal_value]

      expected_assessment_2 = Enum.find(assessments, fn a -> a.id == assessment_point_2.id end)
      assert expected_assessment_2.scale_id == scale.id
      assert expected_assessment_2.scale.ordinal_values == [ordinal_value]
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

      assert Assessments.get_assessment_point!(assessment_point.id, preloads: :scale) ==
               assessment_point
    end

    test "create_assessment_point/1 with valid data creates a assessment point" do
      curriculum_item = Lanttern.CurriculaFixtures.curriculum_item_fixture()
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
      curriculum_item = Lanttern.CurriculaFixtures.curriculum_item_fixture()
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
      curriculum_item = Lanttern.CurriculaFixtures.curriculum_item_fixture()
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

    test "delete_assessment_point_and_entries/1 deletes the assessment point and all related entries" do
      assessment_point = assessment_point_fixture()

      _entry =
        assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          scale_id: assessment_point.scale_id
        })

      assert {:ok, %{delete_assessment_point: %AssessmentPoint{}}} =
               Assessments.delete_assessment_point_and_entries(assessment_point)

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

  describe "strand assessment points" do
    alias Lanttern.Assessments.AssessmentPoint

    import Lanttern.AssessmentsFixtures
    alias Lanttern.LearningContextFixtures
    alias Lanttern.CurriculaFixtures
    alias Lanttern.GradingFixtures
    alias Lanttern.SchoolsFixtures

    test "list_assessment_points/1 returns all assessment points for activities in a given strand" do
      strand = LearningContextFixtures.strand_fixture()
      activity_1 = LearningContextFixtures.activity_fixture(%{strand_id: strand.id, position: 1})
      activity_2 = LearningContextFixtures.activity_fixture(%{strand_id: strand.id, position: 2})
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()
      scale = GradingFixtures.scale_fixture()

      valid_attrs = %{
        name: "some assessment point name abc",
        curriculum_item_id: curriculum_item.id,
        scale_id: scale.id
      }

      assessment_point_1_1 = assessment_point_fixture(valid_attrs, activity_id: activity_1.id)
      assessment_point_1_2 = assessment_point_fixture(valid_attrs, activity_id: activity_1.id)
      assessment_point_2_1 = assessment_point_fixture(valid_attrs, activity_id: activity_2.id)
      assessment_point_2_2 = assessment_point_fixture(valid_attrs, activity_id: activity_2.id)

      # extra assessment points for "filter" assertion
      other_activity = LearningContextFixtures.activity_fixture()
      assessment_point_fixture(valid_attrs, activity_id: other_activity.id)
      assessment_point_fixture()

      assert [expected_1, expected_2, expected_3, expected_4] =
               Assessments.list_assessment_points(activities_from_strand_id: strand.id)

      assert expected_1.id == assessment_point_1_1.id
      assert expected_2.id == assessment_point_1_2.id
      assert expected_3.id == assessment_point_2_1.id
      assert expected_4.id == assessment_point_2_2.id
    end

    test "list_strand_students_entries/1 returns students and their assessment point entries for the given strand" do
      strand = LearningContextFixtures.strand_fixture()
      activity_1 = LearningContextFixtures.activity_fixture(%{strand_id: strand.id, position: 1})
      activity_2 = LearningContextFixtures.activity_fixture(%{strand_id: strand.id, position: 2})
      curriculum_item_1 = CurriculaFixtures.curriculum_item_fixture()
      curriculum_item_2 = CurriculaFixtures.curriculum_item_fixture()
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})

      assessment_point_1_1 =
        assessment_point_fixture(
          %{
            name: "some assessment point name abc",
            curriculum_item_id: curriculum_item_1.id,
            scale_id: scale.id
          },
          activity_id: activity_1.id
        )

      assessment_point_2_1 =
        assessment_point_fixture(
          %{
            name: "some assessment point name hij",
            curriculum_item_id: curriculum_item_1.id,
            scale_id: scale.id
          },
          activity_id: activity_2.id
        )

      assessment_point_2_2 =
        assessment_point_fixture(
          %{
            name: "some assessment point name xyz",
            curriculum_item_id: curriculum_item_2.id,
            scale_id: scale.id
          },
          activity_id: activity_2.id
        )

      class = SchoolsFixtures.class_fixture()
      student_a = SchoolsFixtures.student_fixture(%{name: "AAA", classes_ids: [class.id]})
      student_b = SchoolsFixtures.student_fixture(%{name: "BBB", classes_ids: [class.id]})
      student_c = SchoolsFixtures.student_fixture(%{name: "CCC", classes_ids: [class.id]})
      student_d = SchoolsFixtures.student_fixture(%{name: "DDD"})

      entry_1_1_a =
        assessment_point_entry_fixture(%{
          student_id: student_a.id,
          assessment_point_id: assessment_point_1_1.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      entry_2_1_b =
        assessment_point_entry_fixture(%{
          student_id: student_b.id,
          assessment_point_id: assessment_point_2_1.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      entry_2_2_c =
        assessment_point_entry_fixture(%{
          student_id: student_c.id,
          assessment_point_id: assessment_point_2_2.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      _entry_2_2_d =
        assessment_point_entry_fixture(%{
          student_id: student_d.id,
          assessment_point_id: assessment_point_2_2.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      assert [
               {expected_std_a, [^entry_1_1_a, nil, nil]},
               {expected_std_b, [nil, ^entry_2_1_b, nil]},
               {expected_std_c, [nil, nil, ^entry_2_2_c]}
             ] = Assessments.list_strand_students_entries(strand.id, classes_ids: [class.id])

      assert expected_std_a.id == student_a.id
      assert expected_std_b.id == student_b.id
      assert expected_std_c.id == student_c.id
    end

    test "create_assessment_point/2 with valid data creates an assessment point linked to a strand" do
      strand = LearningContextFixtures.strand_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()
      scale = GradingFixtures.scale_fixture()

      valid_attrs = %{
        name: "some assessment point name abc",
        curriculum_item_id: curriculum_item.id,
        scale_id: scale.id
      }

      assert {:ok, %AssessmentPoint{} = assessment_point} =
               Assessments.create_assessment_point(valid_attrs, strand_id: strand.id)

      assert assessment_point.name == "some assessment point name abc"
      assert assessment_point.curriculum_item_id == curriculum_item.id
      assert assessment_point.scale_id == scale.id

      [expected] =
        Assessments.list_assessment_points(strands_ids: [strand.id])

      assert expected.id == assessment_point.id
    end
  end

  describe "activity assessment points" do
    alias Lanttern.Assessments.AssessmentPoint

    import Lanttern.AssessmentsFixtures
    alias Lanttern.LearningContextFixtures
    alias Lanttern.CurriculaFixtures
    alias Lanttern.GradingFixtures
    alias Lanttern.SchoolsFixtures

    test "create_assessment_point/2 with valid data creates an assessment point linked to a activity" do
      activity = LearningContextFixtures.activity_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()
      scale = GradingFixtures.scale_fixture()

      valid_attrs = %{
        name: "some assessment point name abc",
        curriculum_item_id: curriculum_item.id,
        scale_id: scale.id
      }

      assert {:ok, %AssessmentPoint{} = assessment_point} =
               Assessments.create_assessment_point(valid_attrs, activity_id: activity.id)

      assert assessment_point.name == "some assessment point name abc"
      assert assessment_point.curriculum_item_id == curriculum_item.id
      assert assessment_point.scale_id == scale.id

      [expected] =
        Assessments.list_assessment_points(activities_ids: [activity.id])

      assert expected.id == assessment_point.id
    end

    test "list_assessment_points/1 with activities filter returns all assessment points in a given activity" do
      activity = LearningContextFixtures.activity_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()
      scale = GradingFixtures.scale_fixture()

      valid_attrs = %{
        name: "some assessment point name abc",
        curriculum_item_id: curriculum_item.id,
        scale_id: scale.id
      }

      assessment_point_1 = assessment_point_fixture(valid_attrs, activity_id: activity.id)
      assessment_point_2 = assessment_point_fixture(valid_attrs, activity_id: activity.id)
      assessment_point_3 = assessment_point_fixture(valid_attrs, activity_id: activity.id)

      # extra assessment points for "filter" assertion
      other_activity = LearningContextFixtures.activity_fixture()
      assessment_point_fixture(valid_attrs, activity_id: other_activity.id)
      assessment_point_fixture()

      assert [expected_1, expected_2, expected_3] =
               Assessments.list_assessment_points(activities_ids: [activity.id])

      assert expected_1.id == assessment_point_1.id
      assert expected_2.id == assessment_point_2.id
      assert expected_3.id == assessment_point_3.id
    end

    test "list_activity_students_entries/1 returns students and their assessment point entries for the given activty" do
      activity = LearningContextFixtures.activity_fixture()
      curriculum_item_1 = CurriculaFixtures.curriculum_item_fixture()
      curriculum_item_2 = CurriculaFixtures.curriculum_item_fixture()
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})

      assessment_point_1 =
        assessment_point_fixture(
          %{
            name: "some assessment point name abc",
            curriculum_item_id: curriculum_item_1.id,
            scale_id: scale.id
          },
          activity_id: activity.id
        )

      assessment_point_2 =
        assessment_point_fixture(
          %{
            name: "some assessment point name xyz",
            curriculum_item_id: curriculum_item_2.id,
            scale_id: scale.id
          },
          activity_id: activity.id
        )

      class = SchoolsFixtures.class_fixture()
      student_a = SchoolsFixtures.student_fixture(%{name: "AAA", classes_ids: [class.id]})
      student_b = SchoolsFixtures.student_fixture(%{name: "BBB", classes_ids: [class.id]})
      student_c = SchoolsFixtures.student_fixture(%{name: "CCC"})

      entry_1_a =
        assessment_point_entry_fixture(%{
          student_id: student_a.id,
          assessment_point_id: assessment_point_1.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      entry_2_b =
        assessment_point_entry_fixture(%{
          student_id: student_b.id,
          assessment_point_id: assessment_point_2.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      _entry_2_c =
        assessment_point_entry_fixture(%{
          student_id: student_c.id,
          assessment_point_id: assessment_point_2.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      assert [
               {expected_std_a, [^entry_1_a, nil]},
               {expected_std_b, [nil, ^entry_2_b]}
             ] = Assessments.list_activity_students_entries(activity.id, classes_ids: [class.id])

      assert expected_std_a.id == student_a.id
      assert expected_std_b.id == student_b.id
    end

    test "update_activity_assessment_points_positions/2 update activity assessment points position based on list order" do
      activity = LearningContextFixtures.activity_fixture()
      assessment_point_1 = assessment_point_fixture(%{}, activity_id: activity.id)
      assessment_point_2 = assessment_point_fixture(%{}, activity_id: activity.id)
      assessment_point_3 = assessment_point_fixture(%{}, activity_id: activity.id)
      assessment_point_4 = assessment_point_fixture(%{}, activity_id: activity.id)

      sorted_assessment_points_ids =
        [
          assessment_point_2.id,
          assessment_point_3.id,
          assessment_point_1.id,
          assessment_point_4.id
        ]

      assert {:ok,
              [
                expected_ap_2,
                expected_ap_3,
                expected_ap_1,
                expected_ap_4
              ]} =
               Assessments.update_activity_assessment_points_positions(
                 activity.id,
                 sorted_assessment_points_ids
               )

      assert expected_ap_1.id == assessment_point_1.id
      assert expected_ap_2.id == assessment_point_2.id
      assert expected_ap_3.id == assessment_point_3.id
      assert expected_ap_4.id == assessment_point_4.id
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
      scale = Lanttern.GradingFixtures.scale_fixture()
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})
      student_1 = Lanttern.SchoolsFixtures.student_fixture()

      entry_1 =
        assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: student_1.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      student_2 = Lanttern.SchoolsFixtures.student_fixture()

      entry_2 =
        assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: student_2.id,
          scale_id: scale.id,
          scale_type: scale.type
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

    test "list_assessment_point_entries/1 with load_feedback returns entries with related feedback (+completion comment)" do
      scale = Lanttern.GradingFixtures.scale_fixture()
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})
      student = Lanttern.SchoolsFixtures.student_fixture()

      comment =
        Lanttern.ConversationFixtures.comment_fixture(%{assessment_point_id: assessment_point.id})

      feedback =
        feedback_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: student.id,
          completion_comment_id: comment.id
        })

      entry =
        assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      [expected] = Assessments.list_assessment_point_entries(load_feedback: true)

      assert expected.id == entry.id
      assert expected.feedback.id == feedback.id
      assert expected.feedback.completion_comment.id == comment.id
    end

    test "get_assessment_point_entry!/1 returns the assessment_point_entry with given id" do
      assessment_point_entry = assessment_point_entry_fixture()

      assert Assessments.get_assessment_point_entry!(assessment_point_entry.id) ==
               assessment_point_entry
    end

    test "create_assessment_point_entry/1 with valid data creates a assessment_point_entry" do
      scale = Lanttern.GradingFixtures.scale_fixture()
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})
      student = Lanttern.SchoolsFixtures.student_fixture()

      valid_attrs = %{
        assessment_point_id: assessment_point.id,
        student_id: student.id,
        observation: "some observation",
        scale_id: scale.id,
        scale_type: scale.type
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
        score: 0.5,
        scale_id: scale.id,
        scale_type: scale.type
      }

      assert {:ok, %AssessmentPointEntry{} = assessment_point_entry} =
               Assessments.create_assessment_point_entry(valid_attrs)

      assert assessment_point_entry.assessment_point_id == assessment_point.id
      assert assessment_point_entry.score == 0.5
    end

    test "create_assessment_point_entry/1 of type ordinal with valid data and preloads creates a assessment_point_entry and return it with preloaded data" do
      scale = Lanttern.GradingFixtures.scale_fixture(%{type: "ordinal"})
      ordinal_value = Lanttern.GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id})
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})
      student = Lanttern.SchoolsFixtures.student_fixture()

      valid_attrs = %{
        assessment_point_id: assessment_point.id,
        student_id: student.id,
        observation: "some observation",
        ordinal_value_id: ordinal_value.id,
        scale_id: scale.id,
        scale_type: scale.type
      }

      assert {:ok, %AssessmentPointEntry{} = assessment_point_entry} =
               Assessments.create_assessment_point_entry(valid_attrs, preloads: :ordinal_value)

      assert assessment_point_entry.assessment_point_id == assessment_point.id
      assert assessment_point_entry.ordinal_value.id == ordinal_value.id
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

  describe "assessment points explorer" do
    import Lanttern.AssessmentsFixtures
    import Lanttern.SchoolsFixtures
    import Lanttern.TaxonomyFixtures
    import Lanttern.CurriculaFixtures

    test "list_students_assessment_points_grid/1 returns a list of students with assessment point entries" do
      # list is sorted by student name
      std_1 = student_fixture(%{name: "AAA"})
      std_2 = student_fixture(%{name: "BBB"})
      std_3 = student_fixture(%{name: "CCC"})

      scale = Lanttern.GradingFixtures.scale_fixture()

      # and by assessment point datetime
      ast_1 = assessment_point_fixture(%{scale_id: scale.id, datetime: ~U[2023-08-01 15:30:00Z]})
      ast_2 = assessment_point_fixture(%{scale_id: scale.id, datetime: ~U[2023-08-02 15:30:00Z]})
      ast_3 = assessment_point_fixture(%{scale_id: scale.id, datetime: ~U[2023-08-03 15:30:00Z]})

      #       ast_1 ast_2 ast_3
      # std_1  [x]   [ ]   [x]
      # std_2  [ ]   [x]   [x]
      # std_3  [x]   [ ]   [x]

      std_1_ast_1 =
        assessment_point_entry_fixture(%{
          student_id: std_1.id,
          assessment_point_id: ast_1.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      std_1_ast_3 =
        assessment_point_entry_fixture(%{
          student_id: std_1.id,
          assessment_point_id: ast_3.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      std_2_ast_2 =
        assessment_point_entry_fixture(%{
          student_id: std_2.id,
          assessment_point_id: ast_2.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      std_2_ast_3 =
        assessment_point_entry_fixture(%{
          student_id: std_2.id,
          assessment_point_id: ast_3.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      std_3_ast_1 =
        assessment_point_entry_fixture(%{
          student_id: std_3.id,
          assessment_point_id: ast_1.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      std_3_ast_3 =
        assessment_point_entry_fixture(%{
          student_id: std_3.id,
          assessment_point_id: ast_3.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      %{
        assessment_points: assessment_points,
        students_and_entries: students_and_entries
      } =
        Assessments.list_students_assessment_points_grid()

      assert assessment_points == [ast_1, ast_2, ast_3]

      assert students_and_entries == [
               {std_1, [std_1_ast_1, nil, std_1_ast_3]},
               {std_2, [nil, std_2_ast_2, std_2_ast_3]},
               {std_3, [std_3_ast_1, nil, std_3_ast_3]}
             ]
    end

    test "list_students_assessment_points_grid/1 with class filters returns a filtered list of students with assessment point entries" do
      # expected grid:
      #       ast_1 ast_2 ast_3
      # std_1  [x]   [x]   [x]
      # std_2  [x]   [x]   [ ] -> std was in class during ast 1 and 2, but left (not currently in class)
      # std_3  [ ]   [ ]   [x] -> std was in a different class and moved in before ast 3

      class = class_fixture()
      std_1 = student_fixture(%{name: "AAA", classes_ids: [class.id]})
      std_2 = student_fixture(%{name: "BBB"})
      std_3 = student_fixture(%{name: "CCC", classes_ids: [class.id]})

      scale = Lanttern.GradingFixtures.scale_fixture()

      ast_1 =
        assessment_point_fixture(%{
          scale_id: scale.id,
          datetime: ~U[2023-08-01 15:30:00Z],
          classes_ids: [class.id]
        })

      ast_2 =
        assessment_point_fixture(%{
          scale_id: scale.id,
          datetime: ~U[2023-08-02 15:30:00Z],
          classes_ids: [class.id]
        })

      ast_3 =
        assessment_point_fixture(%{
          scale_id: scale.id,
          datetime: ~U[2023-08-03 15:30:00Z],
          classes_ids: [class.id]
        })

      std_1_ast_1 =
        assessment_point_entry_fixture(%{
          student_id: std_1.id,
          assessment_point_id: ast_1.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      std_1_ast_2 =
        assessment_point_entry_fixture(%{
          student_id: std_1.id,
          assessment_point_id: ast_2.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      std_1_ast_3 =
        assessment_point_entry_fixture(%{
          student_id: std_1.id,
          assessment_point_id: ast_3.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      std_2_ast_1 =
        assessment_point_entry_fixture(%{
          student_id: std_2.id,
          assessment_point_id: ast_1.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      std_2_ast_2 =
        assessment_point_entry_fixture(%{
          student_id: std_2.id,
          assessment_point_id: ast_2.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      std_3_ast_3 =
        assessment_point_entry_fixture(%{
          student_id: std_3.id,
          assessment_point_id: ast_3.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      # extra student and assessment points for filter test
      not_std = student_fixture(%{name: "ZZZ"})

      not_ast =
        assessment_point_fixture(%{scale_id: scale.id, datetime: ~U[2023-08-04 15:30:00Z]})

      assessment_point_entry_fixture(%{
        student_id: not_std.id,
        assessment_point_id: not_ast.id,
        scale_id: scale.id,
        scale_type: scale.type
      })

      assessment_point_entry_fixture(%{
        student_id: std_3.id,
        assessment_point_id: not_ast.id,
        scale_id: scale.id,
        scale_type: scale.type
      })

      %{
        assessment_points: assessment_points,
        students_and_entries: students_and_entries
      } =
        Assessments.list_students_assessment_points_grid(classes_ids: [class.id])

      assert [expected_ast_1, expected_ast_2, expected_ast_3] = assessment_points
      assert expected_ast_1.id == ast_1.id
      assert expected_ast_2.id == ast_2.id
      assert expected_ast_3.id == ast_3.id

      assert [
               {expected_std_1, [expected_s1a1, expected_s1a2, expected_s1a3]},
               {expected_std_2, [expected_s2a1, expected_s2a2, nil]},
               {expected_std_3, [nil, nil, expected_s3a3]}
             ] = students_and_entries

      assert expected_std_1.id == std_1.id
      assert expected_std_2.id == std_2.id
      assert expected_std_3.id == std_3.id

      assert expected_s1a1.id == std_1_ast_1.id
      assert expected_s1a2.id == std_1_ast_2.id
      assert expected_s1a3.id == std_1_ast_3.id
      assert expected_s2a1.id == std_2_ast_1.id
      assert expected_s2a2.id == std_2_ast_2.id
      assert expected_s3a3.id == std_3_ast_3.id
    end

    test "list_students_assessment_points_grid/1 with subject filters returns a filtered list of students with assessment point entries" do
      # expected grid:
      #       ast_1 ast_2
      # std_1  [x]   [ ]
      # std_2  [ ]   [x]

      subject = subject_fixture()
      curriculum_item = curriculum_item_fixture(%{subjects_ids: [subject.id]})

      std_1 = student_fixture(%{name: "AAA"})
      std_2 = student_fixture(%{name: "BBB"})

      scale = Lanttern.GradingFixtures.scale_fixture()

      ast_1 =
        assessment_point_fixture(%{
          datetime: ~U[2023-08-01 15:30:00Z],
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id
        })

      ast_2 =
        assessment_point_fixture(%{
          datetime: ~U[2023-08-02 15:30:00Z],
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id
        })

      std_1_ast_1 =
        assessment_point_entry_fixture(%{
          student_id: std_1.id,
          assessment_point_id: ast_1.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      std_2_ast_2 =
        assessment_point_entry_fixture(%{
          student_id: std_2.id,
          assessment_point_id: ast_2.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      # extra student and assessment points for filter test
      not_std = student_fixture(%{name: "ZZZ"})

      not_ast =
        assessment_point_fixture(%{datetime: ~U[2023-08-04 15:30:00Z], scale_id: scale.id})

      assessment_point_entry_fixture(%{
        student_id: not_std.id,
        assessment_point_id: not_ast.id,
        scale_id: scale.id,
        scale_type: scale.type
      })

      assessment_point_entry_fixture(%{
        student_id: std_2.id,
        assessment_point_id: not_ast.id,
        scale_id: scale.id,
        scale_type: scale.type
      })

      %{
        assessment_points: assessment_points,
        students_and_entries: students_and_entries
      } =
        Assessments.list_students_assessment_points_grid(subjects_ids: [subject.id])

      assert [expected_ast_1, expected_ast_2] = assessment_points
      assert expected_ast_1.id == ast_1.id
      assert expected_ast_2.id == ast_2.id

      assert [
               {expected_std_1, [expected_s1a1, nil]},
               {expected_std_2, [nil, expected_s2a2]}
             ] = students_and_entries

      assert expected_std_1.id == std_1.id
      assert expected_std_2.id == std_2.id

      assert expected_s1a1.id == std_1_ast_1.id
      assert expected_s2a2.id == std_2_ast_2.id
    end
  end

  describe "feedback" do
    alias Lanttern.Assessments.Feedback

    import Lanttern.AssessmentsFixtures

    @invalid_attrs %{comment: nil}

    test "list_feedback/1 returns all feedback" do
      feedback = feedback_fixture()
      assert Assessments.list_feedback() == [feedback]
    end

    test "list_feedback/1 with preloads returns feedback with preloaded data" do
      student = Lanttern.SchoolsFixtures.student_fixture()
      feedback = feedback_fixture(%{student_id: student.id})

      [expected] = Assessments.list_feedback(preloads: :student)

      # assert student is preloaded
      assert expected.id == feedback.id
      assert expected.student.id == student.id
    end

    test "get_feedback!/2 returns the feedback with given id" do
      feedback = feedback_fixture()
      assert Assessments.get_feedback!(feedback.id) == feedback
    end

    test "get_feedback!/2 with preloads returns feedback with preloaded data" do
      student = Lanttern.SchoolsFixtures.student_fixture()
      feedback = feedback_fixture(%{student_id: student.id})

      expected = Assessments.get_feedback!(feedback.id, preloads: :student)

      # assert student is preloaded
      assert expected.id == feedback.id
      assert expected.student.id == student.id
    end

    test "create_feedback/2 with valid data creates a feedback" do
      assessment_point = assessment_point_fixture()
      student = Lanttern.SchoolsFixtures.student_fixture()
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      valid_attrs = %{
        assessment_point_id: assessment_point.id,
        student_id: student.id,
        profile_id: profile.id,
        comment: "some comment"
      }

      assert {:ok, %Feedback{} = feedback} = Assessments.create_feedback(valid_attrs)
      assert feedback.comment == "some comment"
    end

    test "create_feedback/2 with preloads returns created feedback with preloaded data" do
      assessment_point = assessment_point_fixture()
      student = Lanttern.SchoolsFixtures.student_fixture()
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      valid_attrs = %{
        assessment_point_id: assessment_point.id,
        student_id: student.id,
        profile_id: profile.id,
        comment: "some comment"
      }

      assert {:ok, %Feedback{} = feedback} =
               Assessments.create_feedback(valid_attrs, preloads: :profile)

      assert feedback.profile.id == profile.id
    end

    test "create_feedback/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Assessments.create_feedback(@invalid_attrs)
    end

    test "update_feedback/3 with valid data updates the feedback" do
      feedback = feedback_fixture()
      update_attrs = %{comment: "some updated comment"}

      assert {:ok, %Feedback{} = feedback} = Assessments.update_feedback(feedback, update_attrs)
      assert feedback.comment == "some updated comment"
    end

    test "update_feedback/3 with preloads returns updated feedback with preloaded data" do
      assessment_point = assessment_point_fixture()

      feedback = feedback_fixture(%{assessment_point_id: assessment_point.id})
      update_attrs = %{comment: "some updated comment with preload"}

      assert {:ok, %Feedback{} = feedback} =
               Assessments.update_feedback(feedback, update_attrs, preloads: :assessment_point)

      assert feedback.comment == "some updated comment with preload"
      assert feedback.assessment_point.id == assessment_point.id
    end

    test "update_feedback/3 with invalid data returns error changeset" do
      feedback = feedback_fixture()
      assert {:error, %Ecto.Changeset{}} = Assessments.update_feedback(feedback, @invalid_attrs)
      assert feedback == Assessments.get_feedback!(feedback.id)
    end

    test "delete_feedback/1 deletes the feedback" do
      feedback = feedback_fixture()
      assert {:ok, %Feedback{}} = Assessments.delete_feedback(feedback)
      assert_raise Ecto.NoResultsError, fn -> Assessments.get_feedback!(feedback.id) end
    end

    test "change_feedback/1 returns a feedback changeset" do
      feedback = feedback_fixture()
      assert %Ecto.Changeset{} = Assessments.change_feedback(feedback)
    end
  end
end
