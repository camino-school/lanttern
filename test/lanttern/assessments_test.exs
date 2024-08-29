defmodule Lanttern.AssessmentsTest do
  use Lanttern.DataCase

  alias Lanttern.Repo
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

      # assert log
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

    test "check name constraint when creating assessment points" do
      curriculum_item = Lanttern.CurriculaFixtures.curriculum_item_fixture()
      scale = Lanttern.GradingFixtures.scale_fixture()
      strand = Lanttern.LearningContextFixtures.strand_fixture()
      moment = Lanttern.LearningContextFixtures.moment_fixture()

      attrs = %{
        curriculum_item_id: curriculum_item.id,
        scale_id: scale.id,
        name: nil,
        strand_id: nil,
        moment_id: nil
      }

      # assessment point in strand context should be ok without name
      assert {:ok, %AssessmentPoint{}} =
               Assessments.create_assessment_point(%{attrs | strand_id: strand.id})

      # assessment point in moment should return error without name
      assert {:error, %Ecto.Changeset{}} =
               Assessments.create_assessment_point(%{attrs | moment_id: moment.id})

      # assessment point in moment should be ok with name
      assert {:ok, %AssessmentPoint{}} =
               Assessments.create_assessment_point(%{
                 attrs
                 | moment_id: moment.id,
                   name: "some name"
               })
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

  describe "moment assessment points" do
    alias Lanttern.Assessments.AssessmentPoint

    import Lanttern.AssessmentsFixtures
    alias Lanttern.LearningContextFixtures
    alias Lanttern.CurriculaFixtures
    alias Lanttern.GradingFixtures
    alias Lanttern.IdentityFixtures
    alias Lanttern.SchoolsFixtures

    test "create_assessment_point/2 with valid data creates an assessment point linked to a moment" do
      moment = LearningContextFixtures.moment_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()
      scale = GradingFixtures.scale_fixture()

      valid_attrs = %{
        moment_id: moment.id,
        name: "some assessment point name abc",
        curriculum_item_id: curriculum_item.id,
        scale_id: scale.id
      }

      assert {:ok, %AssessmentPoint{} = assessment_point} =
               Assessments.create_assessment_point(valid_attrs)

      assert assessment_point.name == "some assessment point name abc"
      assert assessment_point.curriculum_item_id == curriculum_item.id
      assert assessment_point.scale_id == scale.id

      [expected] =
        Assessments.list_assessment_points(moments_ids: [moment.id])

      assert expected.id == assessment_point.id
    end

    test "list_assessment_points/1 with moments filter returns all assessment points in a given moment" do
      moment = LearningContextFixtures.moment_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()
      scale = GradingFixtures.scale_fixture()

      valid_attrs = %{
        moment_id: moment.id,
        name: "some assessment point name abc",
        curriculum_item_id: curriculum_item.id,
        scale_id: scale.id
      }

      assessment_point_1 = assessment_point_fixture(valid_attrs)
      assessment_point_2 = assessment_point_fixture(valid_attrs)
      assessment_point_3 = assessment_point_fixture(valid_attrs)

      # extra assessment points for "filter" assertion
      other_moment = LearningContextFixtures.moment_fixture()
      assessment_point_fixture(%{valid_attrs | moment_id: other_moment.id})
      assessment_point_fixture()

      assert [expected_1, expected_2, expected_3] =
               Assessments.list_assessment_points(moments_ids: [moment.id])

      assert expected_1.id == assessment_point_1.id
      assert expected_2.id == assessment_point_2.id
      assert expected_3.id == assessment_point_3.id
    end

    test "update_assessment_points_positions/1 update assessment points position based on list order" do
      moment = LearningContextFixtures.moment_fixture()
      assessment_point_1 = assessment_point_fixture(%{moment_id: moment.id})
      assessment_point_2 = assessment_point_fixture(%{moment_id: moment.id})
      assessment_point_3 = assessment_point_fixture(%{moment_id: moment.id})
      assessment_point_4 = assessment_point_fixture(%{moment_id: moment.id})

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
               Assessments.update_assessment_points_positions(sorted_assessment_points_ids)

      assert expected_ap_1.id == assessment_point_1.id
      assert expected_ap_2.id == assessment_point_2.id
      assert expected_ap_3.id == assessment_point_3.id
      assert expected_ap_4.id == assessment_point_4.id
    end
  end

  describe "assessment_point_entries" do
    alias Lanttern.Assessments.AssessmentPointEntry
    alias Lanttern.AssessmentsLog.AssessmentPointEntryLog

    import Lanttern.AssessmentsFixtures

    alias Lanttern.Attachments
    alias Lanttern.IdentityFixtures

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

    test "get_assessment_point_student_entry/3 returns the assessment_point_entry for the given assessment point and student" do
      student = Lanttern.SchoolsFixtures.student_fixture()

      entry =
        assessment_point_entry_fixture(%{student_id: student.id})

      entry_id = entry.id
      student_id = student.id

      assert %{id: ^entry_id, student: %{id: ^student_id}} =
               Assessments.get_assessment_point_student_entry(
                 entry.assessment_point_id,
                 entry.student_id,
                 preloads: :student
               )
    end

    test "create_assessment_point_entry/1 with valid data creates a assessment_point_entry" do
      scale = Lanttern.GradingFixtures.scale_fixture()
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})
      student = Lanttern.SchoolsFixtures.student_fixture()

      # profile to test log
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      valid_attrs = %{
        assessment_point_id: assessment_point.id,
        student_id: student.id,
        observation: "some observation",
        scale_id: scale.id,
        scale_type: scale.type
      }

      assert {:ok, %AssessmentPointEntry{} = assessment_point_entry} =
               Assessments.create_assessment_point_entry(valid_attrs, log_profile_id: profile.id)

      assert assessment_point_entry.assessment_point_id == assessment_point.id
      assert assessment_point_entry.student_id == student.id
      assert assessment_point_entry.observation == "some observation"

      on_exit(fn ->
        assert_supervised_tasks_are_down()

        assessment_point_entry_log =
          Repo.get_by!(AssessmentPointEntryLog,
            assessment_point_entry_id: assessment_point_entry.id
          )

        assert assessment_point_entry_log.assessment_point_entry_id == assessment_point_entry.id
        assert assessment_point_entry_log.profile_id == profile.id
        assert assessment_point_entry_log.operation == "CREATE"
        assert assessment_point_entry_log.assessment_point_id == assessment_point.id
        assert assessment_point_entry_log.student_id == student.id
        assert assessment_point_entry_log.observation == "some observation"
      end)
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

      # profile to test log
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      assert {:ok, %AssessmentPointEntry{} = assessment_point_entry} =
               Assessments.update_assessment_point_entry(assessment_point_entry, update_attrs,
                 log_profile_id: profile.id
               )

      assert assessment_point_entry.observation == "some updated observation"

      on_exit(fn ->
        assert_supervised_tasks_are_down()

        assessment_point_entry_log =
          Repo.get_by!(AssessmentPointEntryLog,
            assessment_point_entry_id: assessment_point_entry.id
          )

        assert assessment_point_entry_log.assessment_point_entry_id == assessment_point_entry.id
        assert assessment_point_entry_log.profile_id == profile.id
        assert assessment_point_entry_log.operation == "UPDATE"
        assert assessment_point_entry_log.observation == "some updated observation"
      end)
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

    test "delete_assessment_point_entry/2 deletes the assessment_point_entry" do
      assessment_point_entry = assessment_point_entry_fixture()

      # profile to test log
      profile = Lanttern.IdentityFixtures.teacher_profile_fixture()

      assert {:ok, %AssessmentPointEntry{}} =
               Assessments.delete_assessment_point_entry(assessment_point_entry,
                 log_profile_id: profile.id
               )

      assert_raise Ecto.NoResultsError, fn ->
        Assessments.get_assessment_point_entry!(assessment_point_entry.id)
      end

      on_exit(fn ->
        assert_supervised_tasks_are_down()

        assessment_point_entry_log =
          Repo.get_by!(AssessmentPointEntryLog,
            assessment_point_entry_id: assessment_point_entry.id
          )

        assert assessment_point_entry_log.assessment_point_entry_id == assessment_point_entry.id
        assert assessment_point_entry_log.profile_id == profile.id
        assert assessment_point_entry_log.operation == "DELETE"
      end)
    end

    test "delete_assessment_point_entry/2 deletes the note and its linked attachments" do
      profile = IdentityFixtures.teacher_profile_fixture()
      assessment_point_entry = assessment_point_entry_fixture()

      {:ok, attachment_1} =
        Assessments.create_assessment_point_entry_evidence(
          %{current_profile: profile},
          assessment_point_entry.id,
          %{"name" => "attachment 1", "link" => "https://somevaliduri.com"}
        )

      {:ok, attachment_2} =
        Assessments.create_assessment_point_entry_evidence(
          %{current_profile: profile},
          assessment_point_entry.id,
          %{"name" => "attachment 2", "link" => "https://somevaliduri.com", "is_external" => true}
        )

      {:ok, attachment_3} =
        Assessments.create_assessment_point_entry_evidence(
          %{current_profile: profile},
          assessment_point_entry.id,
          %{"name" => "attachment 3", "link" => "https://somevaliduri.com", "is_external" => true}
        )

      assert {:ok, %AssessmentPointEntry{}} =
               Assessments.delete_assessment_point_entry(assessment_point_entry)

      assert_raise Ecto.NoResultsError, fn ->
        Assessments.get_assessment_point_entry!(assessment_point_entry.id)
      end

      assert_raise Ecto.NoResultsError, fn -> Attachments.get_attachment!(attachment_1.id) end
      assert_raise Ecto.NoResultsError, fn -> Attachments.get_attachment!(attachment_2.id) end
      assert_raise Ecto.NoResultsError, fn -> Attachments.get_attachment!(attachment_3.id) end

      on_exit(fn ->
        assert_supervised_tasks_are_down()
      end)
    end

    test "change_assessment_point_entry/1 returns a assessment_point_entry changeset" do
      assessment_point_entry = assessment_point_entry_fixture()
      assert %Ecto.Changeset{} = Assessments.change_assessment_point_entry(assessment_point_entry)
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

  describe "assessment point rubrics" do
    alias Lanttern.Rubrics.Rubric
    import Lanttern.AssessmentsFixtures

    test "create_assessment_point_rubric/3 with valid data creates a rubric linked to the given assessment point" do
      assessment_point = assessment_point_fixture()

      valid_attrs = %{
        criteria: "some criteria",
        scale_id: assessment_point.scale_id
      }

      assert {:ok, %Rubric{} = rubric} =
               Assessments.create_assessment_point_rubric(assessment_point.id, valid_attrs,
                 preloads: :scale
               )

      assert rubric.criteria == "some criteria"
      assert rubric.scale.id == assessment_point.scale_id

      # get updated assessment point
      assessment_point = Assessments.get_assessment_point(assessment_point.id)
      assert assessment_point.rubric_id == rubric.id
    end
  end

  describe "student strand report assessments" do
    import Lanttern.AssessmentsFixtures
    alias Lanttern.CurriculaFixtures
    alias Lanttern.GradingFixtures
    alias Lanttern.LearningContextFixtures
    alias Lanttern.RubricsFixtures
    alias Lanttern.SchoolsFixtures

    test "list_strand_goals_student_entries/2 returns the list of strand goals with student assessments" do
      #      | moment_1 | moment_2 | moment_3 |
      # ---------------------------------------
      # ci_1 |    2*    |    1     |    1     | (* no entry in m1 pos 2 and m3)
      # ci_2 |    -     |    1     |    -     |
      # ci_3 |    -     |    -     |    -     |

      strand = LearningContextFixtures.strand_fixture()

      moment_1 = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})
      moment_2 = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})
      moment_3 = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      curriculum_component_1 = CurriculaFixtures.curriculum_component_fixture()
      curriculum_component_2 = CurriculaFixtures.curriculum_component_fixture()
      curriculum_component_3 = CurriculaFixtures.curriculum_component_fixture()

      curriculum_item_1 =
        CurriculaFixtures.curriculum_item_fixture(%{
          curriculum_component_id: curriculum_component_1.id
        })

      curriculum_item_2 =
        CurriculaFixtures.curriculum_item_fixture(%{
          curriculum_component_id: curriculum_component_2.id
        })

      curriculum_item_3 =
        CurriculaFixtures.curriculum_item_fixture(%{
          curriculum_component_id: curriculum_component_3.id
        })

      ordinal_scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ordinal_value = GradingFixtures.ordinal_value_fixture(%{scale_id: ordinal_scale.id})
      numeric_scale = GradingFixtures.scale_fixture(%{type: "numeric"})

      rubric_1 = RubricsFixtures.rubric_fixture(%{scale_id: ordinal_scale.id})
      rubric_3 = RubricsFixtures.rubric_fixture(%{scale_id: ordinal_scale.id})

      # create diff rubric to test query consistency
      # (only diff rubrics of the student should be loaded)
      diff_rubric_3 =
        RubricsFixtures.rubric_fixture(%{
          scale_id: ordinal_scale.id,
          diff_for_rubric_id: rubric_3.id
        })

      student = SchoolsFixtures.student_fixture()

      Lanttern.Repo.insert_all(
        "differentiation_rubrics_students",
        [[rubric_id: diff_rubric_3.id, student_id: student.id]]
      )

      assessment_point_1 =
        assessment_point_fixture(%{
          position: 1,
          curriculum_item_id: curriculum_item_1.id,
          scale_id: ordinal_scale.id,
          strand_id: strand.id,
          rubric_id: rubric_1.id
        })

      assessment_point_2 =
        assessment_point_fixture(%{
          position: 2,
          curriculum_item_id: curriculum_item_2.id,
          scale_id: numeric_scale.id,
          strand_id: strand.id
        })

      assessment_point_3 =
        assessment_point_fixture(%{
          position: 3,
          curriculum_item_id: curriculum_item_3.id,
          scale_id: ordinal_scale.id,
          strand_id: strand.id,
          rubric_id: rubric_3.id
        })

      entry_1 =
        assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point_1.id,
          student_id: student.id,
          scale_id: ordinal_scale.id,
          scale_type: ordinal_scale.type,
          ordinal_value_id: ordinal_value.id
        })

      entry_2 =
        assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point_2.id,
          student_id: student.id,
          scale_id: numeric_scale.id,
          scale_type: numeric_scale.type,
          score: 5.0
        })

      entry_3 =
        assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point_3.id,
          student_id: student.id,
          scale_id: ordinal_scale.id,
          scale_type: ordinal_scale.type,
          ordinal_value_id: ordinal_value.id
        })

      ci_1_m_1_1 =
        assessment_point_fixture(%{
          curriculum_item_id: curriculum_item_1.id,
          scale_id: ordinal_scale.id,
          moment_id: moment_1.id
        })

      _ci_1_m_1_2 =
        assessment_point_fixture(%{
          curriculum_item_id: curriculum_item_1.id,
          scale_id: ordinal_scale.id,
          moment_id: moment_1.id
        })

      ci_1_m_2 =
        assessment_point_fixture(%{
          curriculum_item_id: curriculum_item_1.id,
          scale_id: ordinal_scale.id,
          moment_id: moment_2.id
        })

      _ci_1_m_3 =
        assessment_point_fixture(%{
          curriculum_item_id: curriculum_item_1.id,
          scale_id: ordinal_scale.id,
          moment_id: moment_3.id
        })

      ci_2_m_2 =
        assessment_point_fixture(%{
          curriculum_item_id: curriculum_item_2.id,
          scale_id: ordinal_scale.id,
          moment_id: moment_2.id
        })

      entry_ci_1_m_1_1 =
        assessment_point_entry_fixture(%{
          assessment_point_id: ci_1_m_1_1.id,
          student_id: student.id,
          scale_id: ordinal_scale.id,
          scale_type: ordinal_scale.type,
          ordinal_value_id: ordinal_value.id
        })

      entry_ci_1_m_2 =
        assessment_point_entry_fixture(%{
          assessment_point_id: ci_1_m_2.id,
          student_id: student.id,
          scale_id: ordinal_scale.id,
          scale_type: ordinal_scale.type,
          ordinal_value_id: ordinal_value.id
        })

      entry_ci_2_m_2 =
        assessment_point_entry_fixture(%{
          assessment_point_id: ci_2_m_2.id,
          student_id: student.id,
          scale_id: ordinal_scale.id,
          scale_type: ordinal_scale.type,
          ordinal_value_id: ordinal_value.id
        })

      # extra entry for different student (test student join)
      _other_entry =
        assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point_3.id,
          scale_id: ordinal_scale.id,
          scale_type: ordinal_scale.type
        })

      assert [
               {expected_ap_1, expected_entry_1,
                [expected_ci_1_m_1_1, nil, expected_ci_1_m_2, nil]},
               {expected_ap_2, expected_entry_2, [expected_ci_2_m_2]},
               {expected_ap_3, expected_entry_3, []}
             ] = Assessments.list_strand_goals_student_entries(student.id, strand.id)

      assert expected_ap_1.id == assessment_point_1.id
      assert expected_ap_1.scale_id == ordinal_scale.id
      assert expected_ap_1.rubric_id == rubric_1.id
      refute expected_ap_1.has_diff_rubric_for_student
      assert expected_ap_1.curriculum_item.id == curriculum_item_1.id
      assert expected_ap_1.curriculum_item.curriculum_component.id == curriculum_component_1.id
      assert expected_ap_1.curriculum_item.id == curriculum_item_1.id
      assert expected_entry_1.id == entry_1.id
      assert expected_entry_1.ordinal_value.id == ordinal_value.id

      assert expected_ci_1_m_1_1.id == entry_ci_1_m_1_1.id
      assert expected_ci_1_m_1_1.ordinal_value.id == ordinal_value.id
      assert expected_ci_1_m_2.id == entry_ci_1_m_2.id
      assert expected_ci_1_m_2.ordinal_value.id == ordinal_value.id

      assert expected_ap_2.id == assessment_point_2.id
      assert expected_ap_2.scale_id == numeric_scale.id
      assert expected_ap_2.curriculum_item.id == curriculum_item_2.id
      assert expected_ap_2.curriculum_item.curriculum_component.id == curriculum_component_2.id
      assert expected_entry_2.id == entry_2.id
      assert expected_entry_2.score == 5.0

      assert expected_ci_2_m_2.id == entry_ci_2_m_2.id
      assert expected_ci_2_m_2.ordinal_value.id == ordinal_value.id

      assert expected_ap_3.id == assessment_point_3.id
      assert expected_ap_3.scale_id == ordinal_scale.id
      assert expected_ap_3.rubric_id == rubric_3.id
      assert expected_ap_3.has_diff_rubric_for_student
      assert expected_ap_3.curriculum_item.id == curriculum_item_3.id
      assert expected_ap_3.curriculum_item.curriculum_component.id == curriculum_component_3.id
      assert expected_ap_3.curriculum_item.id == curriculum_item_3.id
      assert expected_entry_3.id == entry_3.id
      assert expected_entry_3.ordinal_value.id == ordinal_value.id
    end
  end

  describe "strand assessment points" do
    alias Lanttern.Assessments.AssessmentPoint

    # import Lanttern.AssessmentsFixtures
    # alias Lanttern.IdentityFixtures
    alias Lanttern.CurriculaFixtures
    alias Lanttern.GradingFixtures
    alias Lanttern.LearningContextFixtures
    # alias Lanttern.SchoolsFixtures

    setup :strand_assessment_points_setup

    test "list_strand_assessment_points/2 returns assessment points as expected", %{
      strand: strand,
      cc: cc,
      ci_1: ci_1,
      ci_2: ci_2,
      ci_3: ci_3,
      s_ap_1_ci_1: s_ap_1_ci_1,
      s_ap_2_ci_2: s_ap_2_ci_2,
      s_ap_3_ci_3: s_ap_3_ci_3
    } do
      assert {[{^strand, 3}], [expected_s_ap_1_ci_1, expected_s_ap_2_ci_2, expected_s_ap_3_ci_3]} =
               Assessments.list_strand_assessment_points(strand.id)

      assert expected_s_ap_1_ci_1.id == s_ap_1_ci_1.id
      assert expected_s_ap_1_ci_1.curriculum_item.id == ci_1.id
      assert expected_s_ap_1_ci_1.curriculum_item.curriculum_component.id == cc.id

      assert expected_s_ap_2_ci_2.id == s_ap_2_ci_2.id
      assert expected_s_ap_2_ci_2.curriculum_item.id == ci_2.id
      assert expected_s_ap_2_ci_2.curriculum_item.curriculum_component.id == cc.id

      assert expected_s_ap_3_ci_3.id == s_ap_3_ci_3.id
      assert expected_s_ap_3_ci_3.curriculum_item.id == ci_3.id
      assert expected_s_ap_3_ci_3.curriculum_item.curriculum_component.id == cc.id
    end

    test "list_strand_assessment_points/2 grouped by curriculum returns assessment points as expected",
         %{
           strand: strand,
           m_1: m_1,
           m_2: m_2,
           cc: cc,
           ci_1: ci_1,
           ci_2: ci_2,
           ci_3: ci_3,
           s_ap_1_ci_1: s_ap_1_ci_1,
           s_ap_2_ci_2: s_ap_2_ci_2,
           s_ap_3_ci_3: s_ap_3_ci_3,
           m_1_ap_1_ci_1: m_1_ap_1_ci_1,
           m_1_ap_2_ci_2: m_1_ap_2_ci_2,
           m_2_ap_1_ci_2: m_2_ap_1_ci_2
         } do
      assert {
               [{expected_ci_1, 2}, {expected_ci_2, 3}, {expected_ci_3, 1}],
               [
                 expected_m_1_ap_1_ci_1,
                 expected_s_ap_1_ci_1,
                 expected_m_1_ap_2_ci_2,
                 expected_m_2_ap_1_ci_2,
                 expected_s_ap_2_ci_2,
                 expected_s_ap_3_ci_3
               ]
             } =
               Assessments.list_strand_assessment_points(strand.id, "curriculum")

      assert expected_ci_1.id == ci_1.id
      assert expected_ci_1.curriculum_component.id == cc.id
      assert expected_m_1_ap_1_ci_1.id == m_1_ap_1_ci_1.id
      assert expected_m_1_ap_1_ci_1.moment.id == m_1.id
      assert expected_s_ap_1_ci_1.id == s_ap_1_ci_1.id

      assert expected_ci_2.id == ci_2.id
      assert expected_ci_2.curriculum_component.id == cc.id
      assert expected_m_1_ap_2_ci_2.id == m_1_ap_2_ci_2.id
      assert expected_m_1_ap_2_ci_2.moment.id == m_1.id
      assert expected_m_2_ap_1_ci_2.id == m_2_ap_1_ci_2.id
      assert expected_m_2_ap_1_ci_2.moment.id == m_2.id
      assert expected_s_ap_2_ci_2.id == s_ap_2_ci_2.id

      assert expected_ci_3.id == ci_3.id
      # the is_differentiation is a virtual field
      # that should be set based on assessment point context
      assert expected_ci_3.is_differentiation
      assert expected_ci_3.curriculum_component.id == cc.id
      assert expected_s_ap_3_ci_3.id == s_ap_3_ci_3.id
    end

    test "list_strand_assessment_points/2 grouped by moments returns assessment points as expected",
         %{
           strand: strand,
           m_1: m_1,
           m_2: m_2,
           cc: cc,
           ci_1: ci_1,
           ci_2: ci_2,
           ci_3: ci_3,
           s_ap_1_ci_1: s_ap_1_ci_1,
           s_ap_2_ci_2: s_ap_2_ci_2,
           s_ap_3_ci_3: s_ap_3_ci_3,
           m_1_ap_1_ci_1: m_1_ap_1_ci_1,
           m_1_ap_2_ci_2: m_1_ap_2_ci_2,
           m_2_ap_1_ci_2: m_2_ap_1_ci_2
         } do
      assert {
               [{^m_1, 2}, {^m_2, 1}, {^strand, 3}],
               [
                 expected_m_1_ap_1_ci_1,
                 expected_m_1_ap_2_ci_2,
                 expected_m_2_ap_1_ci_2,
                 expected_s_ap_1_ci_1,
                 expected_s_ap_2_ci_2,
                 expected_s_ap_3_ci_3
               ]
             } =
               Assessments.list_strand_assessment_points(strand.id, "moment")

      assert expected_m_1_ap_1_ci_1.id == m_1_ap_1_ci_1.id
      assert expected_m_1_ap_1_ci_1.curriculum_item.id == ci_1.id
      assert expected_m_1_ap_1_ci_1.curriculum_item.curriculum_component.id == cc.id

      assert expected_m_1_ap_2_ci_2.id == m_1_ap_2_ci_2.id
      assert expected_m_1_ap_2_ci_2.curriculum_item.id == ci_2.id
      assert expected_m_1_ap_2_ci_2.curriculum_item.curriculum_component.id == cc.id

      assert expected_m_2_ap_1_ci_2.id == m_2_ap_1_ci_2.id
      assert expected_m_2_ap_1_ci_2.curriculum_item.id == ci_2.id
      assert expected_m_2_ap_1_ci_2.curriculum_item.curriculum_component.id == cc.id

      assert expected_s_ap_1_ci_1.id == s_ap_1_ci_1.id
      assert expected_s_ap_1_ci_1.curriculum_item.id == ci_1.id
      assert expected_s_ap_1_ci_1.curriculum_item.curriculum_component.id == cc.id

      assert expected_s_ap_2_ci_2.id == s_ap_2_ci_2.id
      assert expected_s_ap_2_ci_2.curriculum_item.id == ci_2.id
      assert expected_s_ap_2_ci_2.curriculum_item.curriculum_component.id == cc.id

      assert expected_s_ap_3_ci_3.id == s_ap_3_ci_3.id
      assert expected_s_ap_3_ci_3.curriculum_item.id == ci_3.id
      assert expected_s_ap_3_ci_3.curriculum_item.curriculum_component.id == cc.id
    end

    test "create_assessment_point/2 with valid data creates an assessment point linked to a strand" do
      strand = LearningContextFixtures.strand_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()
      scale = GradingFixtures.scale_fixture()

      valid_attrs = %{
        strand_id: strand.id,
        name: "some assessment point name abc",
        curriculum_item_id: curriculum_item.id,
        scale_id: scale.id
      }

      assert {:ok, %AssessmentPoint{} = assessment_point} =
               Assessments.create_assessment_point(valid_attrs)

      assert assessment_point.name == "some assessment point name abc"
      assert assessment_point.curriculum_item_id == curriculum_item.id
      assert assessment_point.scale_id == scale.id

      [expected] =
        Assessments.list_assessment_points(strand_id: strand.id)

      assert expected.id == assessment_point.id
    end
  end

  describe "strand assessments students entries" do
    alias Lanttern.Assessments.AssessmentPointEntry

    setup [
      :strand_assessment_points_setup,
      :strand_assessment_points_entries_setup
    ]

    test "list_strand_students_entries/2 returns entries as expected", %{
      strand: strand,
      s_ap_1_ci_1: s_ap_1_ci_1,
      s_ap_2_ci_2: s_ap_2_ci_2,
      s_ap_3_ci_3: s_ap_3_ci_3,
      scale: scale,
      ov_a: ov_a,
      ov_b: ov_b,
      ov_c: ov_c,
      class_a: class_a,
      class_b: class_b,
      student_1: student_1,
      student_2: student_2,
      student_3: student_3,
      std_1_s_ap_1_ci_1: std_1_s_ap_1_ci_1,
      std_1_s_ap_2_ci_2: std_1_s_ap_2_ci_2,
      std_2_s_ap_2_ci_2: std_2_s_ap_2_ci_2,
      std_3_s_ap_3_ci_3: std_3_s_ap_3_ci_3
    } do
      # test case grid
      # |     | goal assessments        |
      # | std | s ap 1 | s ap 2 | s ap 3 |
      # ----------------------------------
      # | 1   | ov a   | ov b   | ---    |
      # | 2   | ---    | ov c   | ---    |
      # | 3   | ---    | ---    | ov a   |

      # extract values to allow pattern match with pin
      s_ap_1_id = s_ap_1_ci_1.id
      s_ap_1_scale_id = s_ap_1_ci_1.scale_id
      s_ap_1_scale_type = scale.type

      s_ap_2_id = s_ap_2_ci_2.id
      s_ap_2_scale_id = s_ap_2_ci_2.scale_id
      s_ap_2_scale_type = scale.type

      s_ap_3_id = s_ap_3_ci_3.id
      s_ap_3_scale_id = s_ap_3_ci_3.scale_id
      s_ap_3_scale_type = scale.type

      student_1_id = student_1.id
      student_2_id = student_2.id
      student_3_id = student_3.id

      assert [
               {expected_student_1,
                [
                  expected_std_1_s_ap_1_ci_1,
                  expected_std_1_s_ap_2_ci_2,
                  expected_std_1_s_ap_3_ci_3
                ]},
               {expected_student_2,
                [
                  expected_std_2_s_ap_1_ci_1,
                  expected_std_2_s_ap_2_ci_2,
                  expected_std_2_s_ap_3_ci_3
                ]},
               {expected_student_3,
                [
                  expected_std_3_s_ap_1_ci_1,
                  expected_std_3_s_ap_2_ci_2,
                  expected_std_3_s_ap_3_ci_3
                ]}
             ] =
               Assessments.list_strand_students_entries(strand.id, nil,
                 classes_ids: [class_a.id, class_b.id]
               )

      assert expected_student_1.id == student_1.id
      assert expected_std_1_s_ap_1_ci_1.id == std_1_s_ap_1_ci_1.id
      assert expected_std_1_s_ap_1_ci_1.ordinal_value_id == ov_a.id
      assert expected_std_1_s_ap_1_ci_1.is_strand_entry
      assert expected_std_1_s_ap_2_ci_2.id == std_1_s_ap_2_ci_2.id
      assert expected_std_1_s_ap_2_ci_2.ordinal_value_id == ov_b.id
      assert expected_std_1_s_ap_2_ci_2.is_strand_entry

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_1_id,
               assessment_point_id: ^s_ap_3_id,
               scale_id: ^s_ap_3_scale_id,
               scale_type: ^s_ap_3_scale_type,
               is_strand_entry: true
             } = expected_std_1_s_ap_3_ci_3

      assert expected_student_2.id == student_2.id

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_2_id,
               assessment_point_id: ^s_ap_1_id,
               scale_id: ^s_ap_1_scale_id,
               scale_type: ^s_ap_1_scale_type,
               is_strand_entry: true
             } = expected_std_2_s_ap_1_ci_1

      assert expected_std_2_s_ap_2_ci_2.id == std_2_s_ap_2_ci_2.id
      assert expected_std_2_s_ap_2_ci_2.ordinal_value_id == ov_c.id
      assert expected_std_2_s_ap_2_ci_2.is_strand_entry

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_2_id,
               assessment_point_id: ^s_ap_3_id,
               scale_id: ^s_ap_3_scale_id,
               scale_type: ^s_ap_3_scale_type,
               is_strand_entry: true
             } = expected_std_2_s_ap_3_ci_3

      assert expected_student_3.id == student_3.id

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_3_id,
               assessment_point_id: ^s_ap_1_id,
               scale_id: ^s_ap_1_scale_id,
               scale_type: ^s_ap_1_scale_type,
               is_strand_entry: true
             } = expected_std_3_s_ap_1_ci_1

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_3_id,
               assessment_point_id: ^s_ap_2_id,
               scale_id: ^s_ap_2_scale_id,
               scale_type: ^s_ap_2_scale_type,
               is_strand_entry: true
             } = expected_std_3_s_ap_2_ci_2

      assert expected_std_3_s_ap_3_ci_3.id == std_3_s_ap_3_ci_3.id
      assert expected_std_3_s_ap_3_ci_3.ordinal_value_id == ov_a.id
      assert expected_std_3_s_ap_3_ci_3.is_strand_entry
    end

    test "list_strand_students_entries/2 grouped by curriculum returns entries as expected", %{
      strand: strand,
      s_ap_1_ci_1: s_ap_1_ci_1,
      s_ap_2_ci_2: s_ap_2_ci_2,
      s_ap_3_ci_3: s_ap_3_ci_3,
      m_1_ap_1_ci_1: m_1_ap_1_ci_1,
      m_1_ap_2_ci_2: m_1_ap_2_ci_2,
      m_2_ap_1_ci_2: m_2_ap_1_ci_2,
      scale: scale,
      ov_a: ov_a,
      ov_b: ov_b,
      ov_c: ov_c,
      class_a: class_a,
      student_1: student_1,
      student_2: student_2,
      student_3: student_3,
      std_1_m_1_ap_1_ci_1: std_1_m_1_ap_1_ci_1,
      std_1_m_1_ap_2_ci_2: std_1_m_1_ap_2_ci_2,
      std_1_m_2_ap_1_ci_2: std_1_m_2_ap_1_ci_2,
      std_1_s_ap_1_ci_1: std_1_s_ap_1_ci_1,
      std_1_s_ap_2_ci_2: std_1_s_ap_2_ci_2,
      std_2_m_1_ap_2_ci_2: std_2_m_1_ap_2_ci_2,
      std_2_s_ap_2_ci_2: std_2_s_ap_2_ci_2,
      std_3_s_ap_3_ci_3: std_3_s_ap_3_ci_3
    } do
      # test case grid
      # |     | ci 1             | ci 2                       | ci 3   |
      # | std | m1 ap 1 | s ap 1 | m1 ap 2 | m2 ap 1 | s ap 2 | s ap 3 |
      # ----------------------------------------------------------------
      # | 1   | ov a    | ov a   | ov b    | ov b    | ov b   | ---    |
      # | 2   | ---     | ---    | ov c    | ---     | ov c   | ---    |
      # | 3   | ---     | ---    | ---     | ---     | ---    | ov a   |

      # extract values to allow pattern match with pin
      m_1_ap_1_id = m_1_ap_1_ci_1.id
      m_1_ap_1_scale_id = m_1_ap_1_ci_1.scale_id
      m_1_ap_1_scale_type = scale.type

      s_ap_1_id = s_ap_1_ci_1.id
      s_ap_1_scale_id = s_ap_1_ci_1.scale_id
      s_ap_1_scale_type = scale.type

      m_1_ap_2_id = m_1_ap_2_ci_2.id
      m_1_ap_2_scale_id = m_1_ap_2_ci_2.scale_id
      m_1_ap_2_scale_type = scale.type

      m_2_ap_1_id = m_2_ap_1_ci_2.id
      m_2_ap_1_scale_id = m_2_ap_1_ci_2.scale_id
      m_2_ap_1_scale_type = scale.type

      s_ap_2_id = s_ap_2_ci_2.id
      s_ap_2_scale_id = s_ap_2_ci_2.scale_id
      s_ap_2_scale_type = scale.type

      s_ap_3_id = s_ap_3_ci_3.id
      s_ap_3_scale_id = s_ap_3_ci_3.scale_id
      s_ap_3_scale_type = scale.type

      student_1_id = student_1.id
      student_2_id = student_2.id
      student_3_id = student_3.id

      assert [
               {expected_student_1,
                [
                  expected_std_1_m_1_ap_1_ci_1,
                  expected_std_1_s_ap_1_ci_1,
                  expected_std_1_m_1_ap_2_ci_2,
                  expected_std_1_m_2_ap_1_ci_2,
                  expected_std_1_s_ap_2_ci_2,
                  expected_std_1_s_ap_3_ci_3
                ]},
               {expected_student_2,
                [
                  expected_std_2_m_1_ap_1_ci_1,
                  expected_std_2_s_ap_1_ci_1,
                  expected_std_2_m_1_ap_2_ci_2,
                  expected_std_2_m_2_ap_1_ci_2,
                  expected_std_2_s_ap_2_ci_2,
                  expected_std_2_s_ap_3_ci_3
                ]},
               {expected_student_3,
                [
                  expected_std_3_m_1_ap_1_ci_1,
                  expected_std_3_s_ap_1_ci_1,
                  expected_std_3_m_1_ap_2_ci_2,
                  expected_std_3_m_2_ap_1_ci_2,
                  expected_std_3_s_ap_2_ci_2,
                  expected_std_3_s_ap_3_ci_3
                ]}
             ] =
               Assessments.list_strand_students_entries(strand.id, "curriculum",
                 classes_ids: [class_a.id]
               )

      assert expected_student_1.id == student_1.id
      assert expected_std_1_m_1_ap_1_ci_1.id == std_1_m_1_ap_1_ci_1.id
      assert expected_std_1_m_1_ap_1_ci_1.ordinal_value_id == ov_a.id
      refute expected_std_1_m_1_ap_1_ci_1.is_strand_entry
      assert expected_std_1_s_ap_1_ci_1.id == std_1_s_ap_1_ci_1.id
      assert expected_std_1_s_ap_1_ci_1.ordinal_value_id == ov_a.id
      assert expected_std_1_s_ap_1_ci_1.is_strand_entry
      assert expected_std_1_m_1_ap_2_ci_2.id == std_1_m_1_ap_2_ci_2.id
      assert expected_std_1_m_1_ap_2_ci_2.ordinal_value_id == ov_b.id
      refute expected_std_1_m_1_ap_2_ci_2.is_strand_entry
      assert expected_std_1_m_2_ap_1_ci_2.id == std_1_m_2_ap_1_ci_2.id
      assert expected_std_1_m_2_ap_1_ci_2.ordinal_value_id == ov_b.id
      refute expected_std_1_m_2_ap_1_ci_2.is_strand_entry
      assert expected_std_1_s_ap_2_ci_2.id == std_1_s_ap_2_ci_2.id
      assert expected_std_1_s_ap_2_ci_2.ordinal_value_id == ov_b.id
      assert expected_std_1_s_ap_2_ci_2.is_strand_entry

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_1_id,
               assessment_point_id: ^s_ap_3_id,
               scale_id: ^s_ap_3_scale_id,
               scale_type: ^s_ap_3_scale_type,
               is_strand_entry: true
             } = expected_std_1_s_ap_3_ci_3

      assert expected_student_2.id == student_2.id

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_2_id,
               assessment_point_id: ^m_1_ap_1_id,
               scale_id: ^m_1_ap_1_scale_id,
               scale_type: ^m_1_ap_1_scale_type,
               is_strand_entry: false
             } = expected_std_2_m_1_ap_1_ci_1

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_2_id,
               assessment_point_id: ^s_ap_1_id,
               scale_id: ^s_ap_1_scale_id,
               scale_type: ^s_ap_1_scale_type,
               is_strand_entry: true
             } = expected_std_2_s_ap_1_ci_1

      assert expected_std_2_m_1_ap_2_ci_2.id == std_2_m_1_ap_2_ci_2.id
      assert expected_std_2_m_1_ap_2_ci_2.ordinal_value_id == ov_c.id
      refute expected_std_2_m_1_ap_2_ci_2.is_strand_entry

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_2_id,
               assessment_point_id: ^m_2_ap_1_id,
               scale_id: ^m_2_ap_1_scale_id,
               scale_type: ^m_2_ap_1_scale_type,
               is_strand_entry: false
             } = expected_std_2_m_2_ap_1_ci_2

      assert expected_std_2_s_ap_2_ci_2.id == std_2_s_ap_2_ci_2.id
      assert expected_std_2_s_ap_2_ci_2.ordinal_value_id == ov_c.id
      assert expected_std_2_s_ap_2_ci_2.is_strand_entry

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_2_id,
               assessment_point_id: ^s_ap_3_id,
               scale_id: ^s_ap_3_scale_id,
               scale_type: ^s_ap_3_scale_type,
               is_strand_entry: true
             } = expected_std_2_s_ap_3_ci_3

      assert expected_student_3.id == student_3.id

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_3_id,
               assessment_point_id: ^m_1_ap_1_id,
               scale_id: ^m_1_ap_1_scale_id,
               scale_type: ^m_1_ap_1_scale_type,
               is_strand_entry: false
             } = expected_std_3_m_1_ap_1_ci_1

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_3_id,
               assessment_point_id: ^s_ap_1_id,
               scale_id: ^s_ap_1_scale_id,
               scale_type: ^s_ap_1_scale_type,
               is_strand_entry: true
             } = expected_std_3_s_ap_1_ci_1

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_3_id,
               assessment_point_id: ^m_1_ap_2_id,
               scale_id: ^m_1_ap_2_scale_id,
               scale_type: ^m_1_ap_2_scale_type,
               is_strand_entry: false
             } = expected_std_3_m_1_ap_2_ci_2

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_3_id,
               assessment_point_id: ^m_2_ap_1_id,
               scale_id: ^m_2_ap_1_scale_id,
               scale_type: ^m_2_ap_1_scale_type,
               is_strand_entry: false
             } = expected_std_3_m_2_ap_1_ci_2

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_3_id,
               assessment_point_id: ^s_ap_2_id,
               scale_id: ^s_ap_2_scale_id,
               scale_type: ^s_ap_2_scale_type,
               is_strand_entry: true
             } = expected_std_3_s_ap_2_ci_2

      assert expected_std_3_s_ap_3_ci_3.id == std_3_s_ap_3_ci_3.id
      assert expected_std_3_s_ap_3_ci_3.ordinal_value_id == ov_a.id
      assert expected_std_3_s_ap_3_ci_3.is_strand_entry
    end

    test "list_strand_students_entries/2 grouped by moment returns entries as expected", %{
      strand: strand,
      s_ap_1_ci_1: s_ap_1_ci_1,
      s_ap_2_ci_2: s_ap_2_ci_2,
      s_ap_3_ci_3: s_ap_3_ci_3,
      m_1_ap_1_ci_1: m_1_ap_1_ci_1,
      m_1_ap_2_ci_2: m_1_ap_2_ci_2,
      m_2_ap_1_ci_2: m_2_ap_1_ci_2,
      scale: scale,
      ov_a: ov_a,
      ov_b: ov_b,
      ov_c: ov_c,
      class_a: class_a,
      student_1: student_1,
      student_2: student_2,
      student_3: student_3,
      std_1_m_1_ap_1_ci_1: std_1_m_1_ap_1_ci_1,
      std_1_m_1_ap_2_ci_2: std_1_m_1_ap_2_ci_2,
      std_1_m_2_ap_1_ci_2: std_1_m_2_ap_1_ci_2,
      std_1_s_ap_1_ci_1: std_1_s_ap_1_ci_1,
      std_1_s_ap_2_ci_2: std_1_s_ap_2_ci_2,
      std_2_m_1_ap_2_ci_2: std_2_m_1_ap_2_ci_2,
      std_2_s_ap_2_ci_2: std_2_s_ap_2_ci_2,
      std_3_s_ap_3_ci_3: std_3_s_ap_3_ci_3
    } do
      # test case grid
      # |     | m 1         | m 2  | final (strand)     |
      # | std | ap 1 | ap 2 | ap 1 | ap 1 | ap 2 | ap 3 |
      # -------------------------------------------------
      # | 1   | ov a | ov b | ov b | ov a | ov b | ---  |
      # | 2   | ---  | ov c | ---  | ---  | ov c | ---  |
      # | 3   | ---  | ---  | ---  | ---  | ---  | ov a |

      # extract values to allow pattern match with pin
      m_1_ap_1_id = m_1_ap_1_ci_1.id
      m_1_ap_1_scale_id = m_1_ap_1_ci_1.scale_id
      m_1_ap_1_scale_type = scale.type

      s_ap_1_id = s_ap_1_ci_1.id
      s_ap_1_scale_id = s_ap_1_ci_1.scale_id
      s_ap_1_scale_type = scale.type

      m_1_ap_2_id = m_1_ap_2_ci_2.id
      m_1_ap_2_scale_id = m_1_ap_2_ci_2.scale_id
      m_1_ap_2_scale_type = scale.type

      m_2_ap_1_id = m_2_ap_1_ci_2.id
      m_2_ap_1_scale_id = m_2_ap_1_ci_2.scale_id
      m_2_ap_1_scale_type = scale.type

      s_ap_2_id = s_ap_2_ci_2.id
      s_ap_2_scale_id = s_ap_2_ci_2.scale_id
      s_ap_2_scale_type = scale.type

      s_ap_3_id = s_ap_3_ci_3.id
      s_ap_3_scale_id = s_ap_3_ci_3.scale_id
      s_ap_3_scale_type = scale.type

      student_1_id = student_1.id
      student_2_id = student_2.id
      student_3_id = student_3.id

      assert [
               {expected_student_1,
                [
                  expected_std_1_m_1_ap_1_ci_1,
                  expected_std_1_m_1_ap_2_ci_2,
                  expected_std_1_m_2_ap_1_ci_2,
                  expected_std_1_s_ap_1_ci_1,
                  expected_std_1_s_ap_2_ci_2,
                  expected_std_1_s_ap_3_ci_3
                ]},
               {expected_student_2,
                [
                  expected_std_2_m_1_ap_1_ci_1,
                  expected_std_2_m_1_ap_2_ci_2,
                  expected_std_2_m_2_ap_1_ci_2,
                  expected_std_2_s_ap_1_ci_1,
                  expected_std_2_s_ap_2_ci_2,
                  expected_std_2_s_ap_3_ci_3
                ]},
               {expected_student_3,
                [
                  expected_std_3_m_1_ap_1_ci_1,
                  expected_std_3_m_1_ap_2_ci_2,
                  expected_std_3_m_2_ap_1_ci_2,
                  expected_std_3_s_ap_1_ci_1,
                  expected_std_3_s_ap_2_ci_2,
                  expected_std_3_s_ap_3_ci_3
                ]}
             ] =
               Assessments.list_strand_students_entries(strand.id, "moment",
                 classes_ids: [class_a.id]
               )

      assert expected_student_1.id == student_1.id
      assert expected_std_1_m_1_ap_1_ci_1.id == std_1_m_1_ap_1_ci_1.id
      assert expected_std_1_m_1_ap_1_ci_1.ordinal_value_id == ov_a.id
      refute expected_std_1_m_1_ap_1_ci_1.is_strand_entry
      assert expected_std_1_m_1_ap_2_ci_2.id == std_1_m_1_ap_2_ci_2.id
      assert expected_std_1_m_1_ap_2_ci_2.ordinal_value_id == ov_b.id
      refute expected_std_1_m_1_ap_2_ci_2.is_strand_entry
      assert expected_std_1_m_2_ap_1_ci_2.id == std_1_m_2_ap_1_ci_2.id
      assert expected_std_1_m_2_ap_1_ci_2.ordinal_value_id == ov_b.id
      refute expected_std_1_m_2_ap_1_ci_2.is_strand_entry
      assert expected_std_1_s_ap_1_ci_1.id == std_1_s_ap_1_ci_1.id
      assert expected_std_1_s_ap_1_ci_1.ordinal_value_id == ov_a.id
      assert expected_std_1_s_ap_1_ci_1.is_strand_entry
      assert expected_std_1_s_ap_2_ci_2.id == std_1_s_ap_2_ci_2.id
      assert expected_std_1_s_ap_2_ci_2.ordinal_value_id == ov_b.id
      assert expected_std_1_s_ap_2_ci_2.is_strand_entry

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_1_id,
               assessment_point_id: ^s_ap_3_id,
               scale_id: ^s_ap_3_scale_id,
               scale_type: ^s_ap_3_scale_type,
               is_strand_entry: true
             } = expected_std_1_s_ap_3_ci_3

      assert expected_student_2.id == student_2.id

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_2_id,
               assessment_point_id: ^m_1_ap_1_id,
               scale_id: ^m_1_ap_1_scale_id,
               scale_type: ^m_1_ap_1_scale_type,
               is_strand_entry: false
             } = expected_std_2_m_1_ap_1_ci_1

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_2_id,
               assessment_point_id: ^s_ap_1_id,
               scale_id: ^s_ap_1_scale_id,
               scale_type: ^s_ap_1_scale_type,
               is_strand_entry: true
             } = expected_std_2_s_ap_1_ci_1

      assert expected_std_2_m_1_ap_2_ci_2.id == std_2_m_1_ap_2_ci_2.id
      assert expected_std_2_m_1_ap_2_ci_2.ordinal_value_id == ov_c.id
      refute expected_std_2_m_1_ap_2_ci_2.is_strand_entry

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_2_id,
               assessment_point_id: ^m_2_ap_1_id,
               scale_id: ^m_2_ap_1_scale_id,
               scale_type: ^m_2_ap_1_scale_type,
               is_strand_entry: false
             } = expected_std_2_m_2_ap_1_ci_2

      assert expected_std_2_s_ap_2_ci_2.id == std_2_s_ap_2_ci_2.id
      assert expected_std_2_s_ap_2_ci_2.ordinal_value_id == ov_c.id
      assert expected_std_2_s_ap_2_ci_2.is_strand_entry

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_2_id,
               assessment_point_id: ^s_ap_3_id,
               scale_id: ^s_ap_3_scale_id,
               scale_type: ^s_ap_3_scale_type,
               is_strand_entry: true
             } = expected_std_2_s_ap_3_ci_3

      assert expected_student_3.id == student_3.id

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_3_id,
               assessment_point_id: ^m_1_ap_1_id,
               scale_id: ^m_1_ap_1_scale_id,
               scale_type: ^m_1_ap_1_scale_type,
               is_strand_entry: false
             } = expected_std_3_m_1_ap_1_ci_1

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_3_id,
               assessment_point_id: ^s_ap_1_id,
               scale_id: ^s_ap_1_scale_id,
               scale_type: ^s_ap_1_scale_type,
               is_strand_entry: true
             } = expected_std_3_s_ap_1_ci_1

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_3_id,
               assessment_point_id: ^m_1_ap_2_id,
               scale_id: ^m_1_ap_2_scale_id,
               scale_type: ^m_1_ap_2_scale_type,
               is_strand_entry: false
             } = expected_std_3_m_1_ap_2_ci_2

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_3_id,
               assessment_point_id: ^m_2_ap_1_id,
               scale_id: ^m_2_ap_1_scale_id,
               scale_type: ^m_2_ap_1_scale_type,
               is_strand_entry: false
             } = expected_std_3_m_2_ap_1_ci_2

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_3_id,
               assessment_point_id: ^s_ap_2_id,
               scale_id: ^s_ap_2_scale_id,
               scale_type: ^s_ap_2_scale_type,
               is_strand_entry: true
             } = expected_std_3_s_ap_2_ci_2

      assert expected_std_3_s_ap_3_ci_3.id == std_3_s_ap_3_ci_3.id
      assert expected_std_3_s_ap_3_ci_3.ordinal_value_id == ov_a.id
      assert expected_std_3_s_ap_3_ci_3.is_strand_entry
    end
  end

  describe "moment assessments students entries" do
    alias Lanttern.Assessments.AssessmentPointEntry

    setup [
      :strand_assessment_points_setup,
      :strand_assessment_points_entries_setup
    ]

    test "list_moment_students_entries/2 returns entries as expected", %{
      m_1: moment,
      m_1_ap_1_ci_1: m_1_ap_1_ci_1,
      m_1_ap_2_ci_2: m_1_ap_2_ci_2,
      scale: scale,
      ov_a: ov_a,
      ov_b: ov_b,
      ov_c: ov_c,
      class_a: class_a,
      class_b: class_b,
      student_1: student_1,
      student_2: student_2,
      student_3: student_3,
      std_1_m_1_ap_1_ci_1: std_1_m_1_ap_1_ci_1,
      std_1_m_1_ap_2_ci_2: std_1_m_1_ap_2_ci_2,
      std_2_m_1_ap_2_ci_2: std_2_m_1_ap_2_ci_2
    } do
      # test case grid
      # | std | ap 1 | ap 2 |
      # ---------------------
      # | 1   | ov a | ov b |
      # | 2   | ---  | ov c |
      # | 3   | ---  | ---  |

      # extract values to allow pattern match with pin
      m_1_ap_1_id = m_1_ap_1_ci_1.id
      m_1_ap_1_scale_id = m_1_ap_1_ci_1.scale_id
      m_1_ap_1_scale_type = scale.type

      m_1_ap_2_id = m_1_ap_2_ci_2.id
      m_1_ap_2_scale_id = m_1_ap_2_ci_2.scale_id
      m_1_ap_2_scale_type = scale.type

      student_2_id = student_2.id
      student_3_id = student_3.id

      assert [
               {expected_student_1,
                [
                  expected_std_1_m_1_ap_1_ci_1,
                  expected_std_1_m_1_ap_2_ci_2
                ]},
               {expected_student_2,
                [
                  expected_std_2_m_1_ap_1_ci_1,
                  expected_std_2_m_1_ap_2_ci_2
                ]},
               {expected_student_3,
                [
                  expected_std_3_m_1_ap_1_ci_1,
                  expected_std_3_m_1_ap_2_ci_2
                ]}
             ] =
               Assessments.list_moment_students_entries(moment.id,
                 classes_ids: [class_a.id, class_b.id]
               )

      assert expected_student_1.id == student_1.id
      assert expected_std_1_m_1_ap_1_ci_1.id == std_1_m_1_ap_1_ci_1.id
      assert expected_std_1_m_1_ap_1_ci_1.ordinal_value_id == ov_a.id
      assert expected_std_1_m_1_ap_2_ci_2.id == std_1_m_1_ap_2_ci_2.id
      assert expected_std_1_m_1_ap_2_ci_2.ordinal_value_id == ov_b.id

      assert expected_student_2.id == student_2.id

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_2_id,
               assessment_point_id: ^m_1_ap_1_id,
               scale_id: ^m_1_ap_1_scale_id,
               scale_type: ^m_1_ap_1_scale_type
             } = expected_std_2_m_1_ap_1_ci_1

      assert expected_std_2_m_1_ap_2_ci_2.id == std_2_m_1_ap_2_ci_2.id
      assert expected_std_2_m_1_ap_2_ci_2.ordinal_value_id == ov_c.id

      assert expected_student_3.id == student_3.id

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_3_id,
               assessment_point_id: ^m_1_ap_1_id,
               scale_id: ^m_1_ap_1_scale_id,
               scale_type: ^m_1_ap_1_scale_type
             } = expected_std_3_m_1_ap_1_ci_1

      assert %AssessmentPointEntry{
               id: nil,
               student_id: ^student_3_id,
               assessment_point_id: ^m_1_ap_2_id,
               scale_id: ^m_1_ap_2_scale_id,
               scale_type: ^m_1_ap_2_scale_type
             } = expected_std_3_m_1_ap_2_ci_2
    end
  end

  defp strand_assessment_points_setup(_context) do
    strand = Lanttern.LearningContextFixtures.strand_fixture()

    m_1 = Lanttern.LearningContextFixtures.moment_fixture(%{strand_id: strand.id})
    m_2 = Lanttern.LearningContextFixtures.moment_fixture(%{strand_id: strand.id})
    m_3 = Lanttern.LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

    cc = Lanttern.CurriculaFixtures.curriculum_component_fixture()
    ci_1 = Lanttern.CurriculaFixtures.curriculum_item_fixture(%{curriculum_component_id: cc.id})
    ci_2 = Lanttern.CurriculaFixtures.curriculum_item_fixture(%{curriculum_component_id: cc.id})
    ci_3 = Lanttern.CurriculaFixtures.curriculum_item_fixture(%{curriculum_component_id: cc.id})

    scale = Lanttern.GradingFixtures.scale_fixture(%{type: "ordinal"})
    ov_a = Lanttern.GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id})
    ov_b = Lanttern.GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id})
    ov_c = Lanttern.GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id})

    s_ap_1_ci_1 =
      Lanttern.AssessmentsFixtures.assessment_point_fixture(%{
        strand_id: strand.id,
        curriculum_item_id: ci_1.id,
        scale_id: scale.id
      })

    s_ap_2_ci_2 =
      Lanttern.AssessmentsFixtures.assessment_point_fixture(%{
        strand_id: strand.id,
        curriculum_item_id: ci_2.id,
        scale_id: scale.id
      })

    s_ap_3_ci_3 =
      Lanttern.AssessmentsFixtures.assessment_point_fixture(%{
        strand_id: strand.id,
        curriculum_item_id: ci_3.id,
        scale_id: scale.id,
        is_differentiation: true
      })

    m_1_ap_1_ci_1 =
      Lanttern.AssessmentsFixtures.assessment_point_fixture(%{
        moment_id: m_1.id,
        curriculum_item_id: ci_1.id,
        scale_id: scale.id
      })

    m_1_ap_2_ci_2 =
      Lanttern.AssessmentsFixtures.assessment_point_fixture(%{
        moment_id: m_1.id,
        curriculum_item_id: ci_2.id,
        scale_id: scale.id
      })

    m_2_ap_1_ci_2 =
      Lanttern.AssessmentsFixtures.assessment_point_fixture(%{
        moment_id: m_2.id,
        curriculum_item_id: ci_2.id,
        scale_id: scale.id
      })

    # extra assessment point for filtering validation
    Lanttern.AssessmentsFixtures.assessment_point_fixture()

    %{
      strand: strand,
      m_1: m_1,
      m_2: m_2,
      m_3: m_3,
      cc: cc,
      ci_1: ci_1,
      ci_2: ci_2,
      ci_3: ci_3,
      s_ap_1_ci_1: s_ap_1_ci_1,
      s_ap_2_ci_2: s_ap_2_ci_2,
      s_ap_3_ci_3: s_ap_3_ci_3,
      m_1_ap_1_ci_1: m_1_ap_1_ci_1,
      m_1_ap_2_ci_2: m_1_ap_2_ci_2,
      m_2_ap_1_ci_2: m_2_ap_1_ci_2,
      scale: scale,
      ov_a: ov_a,
      ov_b: ov_b,
      ov_c: ov_c
    }
  end

  defp strand_assessment_points_entries_setup(%{
         s_ap_1_ci_1: s_ap_1_ci_1,
         s_ap_2_ci_2: s_ap_2_ci_2,
         s_ap_3_ci_3: s_ap_3_ci_3,
         m_1_ap_1_ci_1: m_1_ap_1_ci_1,
         m_1_ap_2_ci_2: m_1_ap_2_ci_2,
         m_2_ap_1_ci_2: m_2_ap_1_ci_2,
         scale: scale,
         ov_a: ov_a,
         ov_b: ov_b,
         ov_c: ov_c
       }) do
    school = Lanttern.SchoolsFixtures.school_fixture()
    class_a = Lanttern.SchoolsFixtures.class_fixture(%{school_id: school.id})
    class_b = Lanttern.SchoolsFixtures.class_fixture(%{school_id: school.id})

    student_1 =
      Lanttern.SchoolsFixtures.student_fixture(%{
        name: "AAA",
        classes_ids: [class_a.id, class_b.id]
      })

    student_2 =
      Lanttern.SchoolsFixtures.student_fixture(%{name: "BBB", classes_ids: [class_a.id]})

    student_3 =
      Lanttern.SchoolsFixtures.student_fixture(%{name: "CCC", classes_ids: [class_a.id]})

    # student 1 entries
    # ci_1 m1 / s - ov_a
    # ci_2 m1 / m2 / s - ov_b

    std_1_m_1_ap_1_ci_1 =
      Lanttern.AssessmentsFixtures.assessment_point_entry_fixture(%{
        student_id: student_1.id,
        scale_id: scale.id,
        scale_type: scale.type,
        assessment_point_id: m_1_ap_1_ci_1.id,
        ordinal_value_id: ov_a.id
      })

    std_1_m_1_ap_2_ci_2 =
      Lanttern.AssessmentsFixtures.assessment_point_entry_fixture(%{
        student_id: student_1.id,
        scale_id: scale.id,
        scale_type: scale.type,
        assessment_point_id: m_1_ap_2_ci_2.id,
        ordinal_value_id: ov_b.id
      })

    std_1_m_2_ap_1_ci_2 =
      Lanttern.AssessmentsFixtures.assessment_point_entry_fixture(%{
        student_id: student_1.id,
        scale_id: scale.id,
        scale_type: scale.type,
        assessment_point_id: m_2_ap_1_ci_2.id,
        ordinal_value_id: ov_b.id
      })

    std_1_s_ap_1_ci_1 =
      Lanttern.AssessmentsFixtures.assessment_point_entry_fixture(%{
        student_id: student_1.id,
        scale_id: scale.id,
        scale_type: scale.type,
        assessment_point_id: s_ap_1_ci_1.id,
        ordinal_value_id: ov_a.id
      })

    std_1_s_ap_2_ci_2 =
      Lanttern.AssessmentsFixtures.assessment_point_entry_fixture(%{
        student_id: student_1.id,
        scale_id: scale.id,
        scale_type: scale.type,
        assessment_point_id: s_ap_2_ci_2.id,
        ordinal_value_id: ov_b.id
      })

    # student 2 entries
    # ci_2 m1 / s - ov_c

    std_2_m_1_ap_2_ci_2 =
      Lanttern.AssessmentsFixtures.assessment_point_entry_fixture(%{
        student_id: student_2.id,
        scale_id: scale.id,
        scale_type: scale.type,
        assessment_point_id: m_1_ap_2_ci_2.id,
        ordinal_value_id: ov_c.id
      })

    std_2_s_ap_2_ci_2 =
      Lanttern.AssessmentsFixtures.assessment_point_entry_fixture(%{
        student_id: student_2.id,
        scale_id: scale.id,
        scale_type: scale.type,
        assessment_point_id: s_ap_2_ci_2.id,
        ordinal_value_id: ov_c.id
      })

    # student 3 entries
    # ci_3 s - ov_a

    std_3_s_ap_3_ci_3 =
      Lanttern.AssessmentsFixtures.assessment_point_entry_fixture(%{
        student_id: student_3.id,
        scale_id: scale.id,
        scale_type: scale.type,
        assessment_point_id: s_ap_3_ci_3.id,
        ordinal_value_id: ov_a.id
      })

    # extra assessment point entries for filtering validation
    Lanttern.AssessmentsFixtures.assessment_point_entry_fixture()

    Lanttern.AssessmentsFixtures.assessment_point_entry_fixture(%{
      assessment_point_id: m_1_ap_2_ci_2.id,
      scale_id: scale.id,
      scale_type: scale.type
    })

    Lanttern.AssessmentsFixtures.assessment_point_entry_fixture(%{
      assessment_point_id: s_ap_3_ci_3.id,
      scale_id: scale.id,
      scale_type: scale.type
    })

    %{
      class_a: class_a,
      class_b: class_b,
      student_1: student_1,
      student_2: student_2,
      student_3: student_3,
      std_1_m_1_ap_1_ci_1: std_1_m_1_ap_1_ci_1,
      std_1_m_1_ap_2_ci_2: std_1_m_1_ap_2_ci_2,
      std_1_m_2_ap_1_ci_2: std_1_m_2_ap_1_ci_2,
      std_1_s_ap_1_ci_1: std_1_s_ap_1_ci_1,
      std_1_s_ap_2_ci_2: std_1_s_ap_2_ci_2,
      std_2_m_1_ap_2_ci_2: std_2_m_1_ap_2_ci_2,
      std_2_s_ap_2_ci_2: std_2_s_ap_2_ci_2,
      std_3_s_ap_3_ci_3: std_3_s_ap_3_ci_3
    }
  end
end
