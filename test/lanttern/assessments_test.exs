defmodule Lanttern.AssessmentsTest do
  use Lanttern.DataCase
  use Oban.Testing, repo: Lanttern.Repo

  alias Lanttern.Repo

  alias Lanttern.Assessments
  import Lanttern.Factory

  describe "assessment_points" do
    alias Lanttern.Assessments.AssessmentPoint
    alias Lanttern.Assessments.AssessmentPointLog

    import Lanttern.AssessmentsFixtures

    alias Lanttern.IdentityFixtures
    alias Lanttern.RubricsFixtures

    @invalid_attrs %{name: nil, date: nil, description: nil}

    test "list_assessment_points/1 returns all assessments" do
      assessment_point = assessment_point_fixture()
      assert Assessments.list_assessment_points() == [assessment_point]
    end

    test "list_assessment_points/1 with opts returns assessments as expected" do
      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ordinal_value = insert(:ordinal_value, scale_id: scale.id)
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
      scale = insert(:scale)
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})

      result = Assessments.get_assessment_point!(assessment_point.id, preloads: :scale)
      assert result.id == assessment_point.id
      assert result.scale.id == scale.id
    end

    test "get_assessment_point!/2 with preload_full_rubrics opt returns the assessment point with given id and preloaded rubrics" do
      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov_1 = insert(:ordinal_value, scale_id: scale.id, normalized_value: 0.1)
      ov_2 = insert(:ordinal_value, scale_id: scale.id, normalized_value: 0.2)

      rubric = RubricsFixtures.rubric_fixture(%{scale_id: scale.id})

      descriptor_2 =
        RubricsFixtures.rubric_descriptor_fixture(%{
          rubric_id: rubric.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_2.id
        })

      descriptor_1 =
        RubricsFixtures.rubric_descriptor_fixture(%{
          rubric_id: rubric.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_1.id
        })

      assessment_point =
        assessment_point_fixture(%{scale_id: scale.id, rubric_id: rubric.id})

      expected =
        Assessments.get_assessment_point!(assessment_point.id, preload_full_rubrics: true)

      assert expected.id == assessment_point.id
      assert expected.rubric.id == rubric.id
      [expected_descriptor_1, expected_descriptor_2] = expected.rubric.descriptors
      assert expected_descriptor_1.id == descriptor_1.id
      assert expected_descriptor_2.id == descriptor_2.id
    end

    test "create_assessment_point/1 with valid data creates a assessment point" do
      scope = IdentityFixtures.scope_fixture()
      curriculum_item = insert(:curriculum_item)
      scale = insert(:scale)

      valid_attrs = %{
        name: "some name",
        datetime: ~U[2023-08-02 15:30:00Z],
        description: "some description",
        curriculum_item_id: curriculum_item.id,
        scale_id: scale.id
      }

      assert {:ok, %AssessmentPoint{} = assessment_point} =
               Assessments.create_assessment_point(scope, valid_attrs)

      assert assessment_point.name == "some name"
      assert assessment_point.datetime == ~U[2023-08-02 15:30:00Z]
      assert assessment_point.description == "some description"
      assert assessment_point.curriculum_item_id == curriculum_item.id
      assert assessment_point.scale_id == scale.id

      assert [%AssessmentPointLog{} = log] = Repo.all(AssessmentPointLog)
      assert log.assessment_point_id == assessment_point.id
      assert log.profile_id == scope.profile_id
      assert log.operation == "CREATE"
    end

    test "create_assessment_point/1 with valid data containing classes creates an assessment point with linked classes" do
      curriculum_item = insert(:curriculum_item)
      scale = insert(:scale)

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
               Assessments.create_assessment_point(%Lanttern.Identity.Scope{}, valid_attrs)

      assert assessment_point.name == "some name"
      assert Enum.find(assessment_point.classes, fn c -> c.id == class_1.id end)
      assert Enum.find(assessment_point.classes, fn c -> c.id == class_2.id end)
      assert Enum.find(assessment_point.classes, fn c -> c.id == class_3.id end)
    end

    test "create_assessment_point/1 with students creates an assessment point with linked assessment point entries for each student" do
      curriculum_item = insert(:curriculum_item)
      scale = insert(:scale)

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
               Assessments.create_assessment_point(%Lanttern.Identity.Scope{}, valid_attrs)

      assert assessment_point.name == "some name"
      assert Enum.find(assessment_point.entries, fn e -> e.student_id == student_1.id end)
      assert Enum.find(assessment_point.entries, fn e -> e.student_id == student_2.id end)
      assert Enum.find(assessment_point.entries, fn e -> e.student_id == student_3.id end)
    end

    test "check name constraint when creating assessment points" do
      curriculum_item = insert(:curriculum_item)
      scale = insert(:scale)
      strand = Lanttern.LearningContextFixtures.strand_fixture()
      moment = Lanttern.LearningContextFixtures.moment_fixture()

      attrs = %{
        curriculum_item_id: curriculum_item.id,
        scale_id: scale.id,
        name: nil,
        strand_id: nil,
        moment_id: nil
      }

      scope = %Lanttern.Identity.Scope{}

      # assessment point in strand context should be ok without name
      assert {:ok, %AssessmentPoint{}} =
               Assessments.create_assessment_point(scope, %{attrs | strand_id: strand.id})

      # assessment point in moment should return error without name
      assert {:error, %Ecto.Changeset{}} =
               Assessments.create_assessment_point(scope, %{attrs | moment_id: moment.id})

      # assessment point in moment should be ok with name
      assert {:ok, %AssessmentPoint{}} =
               Assessments.create_assessment_point(scope, %{
                 attrs
                 | moment_id: moment.id,
                   name: "some name"
               })
    end

    test "create_assessment_point/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Assessments.create_assessment_point(%Lanttern.Identity.Scope{}, @invalid_attrs)
    end

    test "update_assessment_point/2 with valid data updates the assessment" do
      scope = IdentityFixtures.scope_fixture()
      assessment_point = assessment_point_fixture()

      update_attrs = %{
        name: "some updated name",
        datetime: ~U[2023-08-03 15:30:00Z],
        description: "some updated description"
      }

      assert {:ok, %AssessmentPoint{} = assessment_point} =
               Assessments.update_assessment_point(scope, assessment_point, update_attrs)

      assert assessment_point.name == "some updated name"
      assert assessment_point.datetime == ~U[2023-08-03 15:30:00Z]
      assert assessment_point.description == "some updated description"

      assert [%AssessmentPointLog{} = log] = Repo.all(AssessmentPointLog)
      assert log.assessment_point_id == assessment_point.id
      assert log.profile_id == scope.profile_id
      assert log.operation == "UPDATE"
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
               Assessments.update_assessment_point(
                 %Lanttern.Identity.Scope{},
                 assessment_point,
                 update_attrs
               )

      assert assessment_point.name == "some updated name"
      assert length(assessment_point.classes) == 2
      assert Enum.find(assessment_point.classes, fn c -> c.id == class_1.id end)
      assert Enum.find(assessment_point.classes, fn c -> c.id == class_3.id end)
    end

    test "update_assessment_point/2 with invalid data returns error changeset" do
      assessment = assessment_point_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Assessments.update_assessment_point(
                 %Lanttern.Identity.Scope{},
                 assessment,
                 @invalid_attrs
               )

      assert assessment == Assessments.get_assessment_point!(assessment.id)
    end

    test "update_assessment_point/2 cannot enable composition on an assessment point that is already a component" do
      component_ap = insert(:assessment_point)
      parent_ap = insert(:assessment_point, uses_composition: true)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap)

      assert {:error, %Ecto.Changeset{} = changeset} =
               Assessments.update_assessment_point(
                 %Lanttern.Identity.Scope{},
                 component_ap,
                 %{uses_composition: true}
               )

      assert %{uses_composition: [_]} = errors_on(changeset)
    end

    test "delete_assessment_point/1 deletes the assessment point" do
      scope = IdentityFixtures.scope_fixture()
      assessment_point = assessment_point_fixture()

      assert {:ok, %AssessmentPoint{}} =
               Assessments.delete_assessment_point(scope, assessment_point)

      assert_raise Ecto.NoResultsError, fn ->
        Assessments.get_assessment_point!(assessment_point.id)
      end

      assert [%AssessmentPointLog{} = log] = Repo.all(AssessmentPointLog)
      assert log.assessment_point_id == assessment_point.id
      assert log.profile_id == scope.profile_id
      assert log.operation == "DELETE"
    end

    test "delete_assessment_point_and_entries/1 deletes the assessment point and all related entries" do
      scope = IdentityFixtures.scope_fixture()
      assessment_point = assessment_point_fixture()

      _entry =
        assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          scale_id: assessment_point.scale_id
        })

      assert {:ok, %{delete_assessment_point: %AssessmentPoint{}}} =
               Assessments.delete_assessment_point_and_entries(scope, assessment_point)

      assert_raise Ecto.NoResultsError, fn ->
        Assessments.get_assessment_point!(assessment_point.id)
      end

      assert [%AssessmentPointLog{} = log] = Repo.all(AssessmentPointLog)
      assert log.assessment_point_id == assessment_point.id
      assert log.profile_id == scope.profile_id
      assert log.operation == "DELETE"
    end

    test "delete_assessment_point_and_entries/2 recalculates composition parents when a component is deleted" do
      scope = IdentityFixtures.scope_fixture()
      parent_ap = insert(:assessment_point, uses_composition: true)
      component_ap = insert(:assessment_point)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap)

      assert {:ok, _} =
               Assessments.delete_assessment_point_and_entries(scope, component_ap)

      assert_enqueued(
        worker: Lanttern.Workers.CompositionRecalcWorker,
        args: %{parent_id: parent_ap.id, profile_id: scope.profile_id}
      )
    end

    test "delete_assessment_point_and_entries/2 does not recalculate when the deleted AP is not a component" do
      scope = IdentityFixtures.scope_fixture()
      assessment_point = assessment_point_fixture()

      assert {:ok, _} =
               Assessments.delete_assessment_point_and_entries(scope, assessment_point)

      refute_enqueued(worker: Lanttern.Workers.CompositionRecalcWorker)
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

    alias Lanttern.IdentityFixtures
    alias Lanttern.LearningContextFixtures
    alias Lanttern.SchoolsFixtures

    test "create_assessment_point/2 with valid data creates an assessment point linked to a moment" do
      moment = LearningContextFixtures.moment_fixture()
      curriculum_item = insert(:curriculum_item)
      scale = insert(:scale)

      valid_attrs = %{
        moment_id: moment.id,
        name: "some assessment point name abc",
        curriculum_item_id: curriculum_item.id,
        scale_id: scale.id
      }

      assert {:ok, %AssessmentPoint{} = assessment_point} =
               Assessments.create_assessment_point(%Lanttern.Identity.Scope{}, valid_attrs)

      assert assessment_point.name == "some assessment point name abc"
      assert assessment_point.curriculum_item_id == curriculum_item.id
      assert assessment_point.scale_id == scale.id

      [expected] =
        Assessments.list_assessment_points(moments_ids: [moment.id])

      assert expected.id == assessment_point.id
    end

    test "list_assessment_points/1 with moments filter returns all assessment points in a given moment" do
      moment = LearningContextFixtures.moment_fixture()
      curriculum_item = insert(:curriculum_item)
      scale = insert(:scale)

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
    alias Lanttern.SchoolsFixtures

    @invalid_attrs %{student_id: nil, score: nil}

    test "list_assessment_point_entries/1 returns all assessment_point_entries" do
      assessment_point_entry = assessment_point_entry_fixture()
      assert Assessments.list_assessment_point_entries() == [assessment_point_entry]
    end

    test "list_assessment_point_entries/1 with opts returns entries as expected" do
      scale = insert(:scale)
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})
      student_1 = SchoolsFixtures.student_fixture()

      entry_1 =
        assessment_point_entry_fixture(%{
          assessment_point_id: assessment_point.id,
          student_id: student_1.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      student_2 = SchoolsFixtures.student_fixture()

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

    test "get_assessment_point_entry!/1 returns the assessment_point_entry with given id" do
      assessment_point_entry = assessment_point_entry_fixture()

      assert Assessments.get_assessment_point_entry!(assessment_point_entry.id) ==
               assessment_point_entry
    end

    test "get_assessment_point_student_entry/3 returns the assessment_point_entry for the given assessment point and student" do
      student = SchoolsFixtures.student_fixture()
      student_id = student.id

      # entries without marking should return nil
      no_marking_entry =
        assessment_point_entry_fixture(%{student_id: student.id})

      _no_marking_entry_id = no_marking_entry.id

      assert Assessments.get_assessment_point_student_entry(
               no_marking_entry.assessment_point_id,
               no_marking_entry.student_id
             )
             |> is_nil()

      entry =
        assessment_point_entry_fixture(%{student_id: student.id, score: 10})

      entry_id = entry.id

      assert %{id: ^entry_id, student: %{id: ^student_id}} =
               Assessments.get_assessment_point_student_entry(
                 entry.assessment_point_id,
                 entry.student_id,
                 preloads: :student
               )
    end

    test "create_assessment_point_entry/1 with valid data creates a assessment_point_entry" do
      scale = insert(:scale)
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})
      student = SchoolsFixtures.student_fixture()

      # profile to test log
      profile = Lanttern.IdentityFixtures.staff_member_profile_fixture()

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
      scale = insert(:scale, type: "numeric", max_score: 1)
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})
      student = SchoolsFixtures.student_fixture()

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
      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ordinal_value = insert(:ordinal_value, scale_id: scale.id)
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})
      student = SchoolsFixtures.student_fixture()

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
      scale = insert(:scale, type: "numeric", max_score: 10)
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})
      student = SchoolsFixtures.student_fixture()

      attrs = %{
        assessment_point_id: assessment_point.id,
        student_id: student.id,
        score: 11
      }

      assert {:error, %Ecto.Changeset{}} =
               Assessments.create_assessment_point_entry(attrs)
    end

    test "create_assestudent = SchoolsFixtures.student_fixture()ssment_point_entry/1 with ordinal_value out of scale returns error changeset" do
      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      _ordinal_value = insert(:ordinal_value, scale_id: scale.id)
      other_ordinal_value = insert(:ordinal_value)
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})
      student = SchoolsFixtures.student_fixture()

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

      update_attrs = %{
        observation: "some updated observation",
        is_missing: true,
        use_manual_input: true
      }

      # profile to test log
      profile = Lanttern.IdentityFixtures.staff_member_profile_fixture()

      assert {:ok, %AssessmentPointEntry{} = assessment_point_entry} =
               Assessments.update_assessment_point_entry(assessment_point_entry, update_attrs,
                 log_profile_id: profile.id
               )

      assert assessment_point_entry.observation == "some updated observation"
      assert assessment_point_entry.is_missing == true
      assert assessment_point_entry.use_manual_input == true

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
        assert assessment_point_entry_log.is_missing == true
        assert assessment_point_entry_log.use_manual_input == true
      end)
    end

    test "update_assessment_point_entry/3 with valid data and preloads updates the assessment_point_entry and return it with preloaded data" do
      student = SchoolsFixtures.student_fixture()
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

    test "update_assessment_point_entry/3 clears is_missing when ordinal_value_id is set" do
      scale = insert(:scale, type: "ordinal")
      ov = insert(:ordinal_value, scale_id: scale.id)
      student = SchoolsFixtures.student_fixture()
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})

      entry =
        assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point.id,
          scale_id: scale.id,
          scale_type: "ordinal",
          is_missing: true
        })

      assert {:ok, %AssessmentPointEntry{is_missing: false}} =
               Assessments.update_assessment_point_entry(entry, %{ordinal_value_id: ov.id})
    end

    test "update_assessment_point_entry/3 clears is_missing when score is set" do
      scale = insert(:scale, type: "numeric")
      student = SchoolsFixtures.student_fixture()
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})

      entry =
        assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point.id,
          scale_id: scale.id,
          scale_type: "numeric",
          is_missing: true
        })

      assert {:ok, %AssessmentPointEntry{is_missing: false}} =
               Assessments.update_assessment_point_entry(entry, %{score: 7.0})
    end

    test "update_assessment_point_entry/3 setting is_missing flips has_marking to true" do
      scale = insert(:scale, type: "numeric")
      student = SchoolsFixtures.student_fixture()
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})

      entry =
        assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point.id,
          scale_id: scale.id,
          scale_type: "numeric"
        })

      assert entry.has_marking == false

      assert {:ok, %AssessmentPointEntry{is_missing: true, has_marking: true}} =
               Assessments.update_assessment_point_entry(entry, %{is_missing: true})
    end

    test "save_assessment_point_entries/2 handles all mapped changes correctly" do
      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov_1 = insert(:ordinal_value, scale_id: scale.id, normalized_value: 0)
      ov_2 = insert(:ordinal_value, scale_id: scale.id, normalized_value: 1)

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

      base_params = %{
        "student_id" => student.id,
        "scale_id" => scale.id,
        "scale_type" => scale.type
      }

      params_1 =
        base_params
        |> Map.put("assessment_point_id", assessment_point_1.id)
        |> Map.put("ordinal_value_id", ov_1.id)

      params_2 =
        base_params
        |> Map.put("assessment_point_id", assessment_point_2.id)
        |> Map.put("ordinal_value_id", ov_2.id)

      params_3 =
        base_params
        |> Map.put("assessment_point_id", assessment_point_3.id)
        |> Map.put("ordinal_value_id", "")

      # profile to test log
      profile = Lanttern.IdentityFixtures.staff_member_profile_fixture()

      # wait 1 second before saving to allow inserted and updated at are
      # different in updated entries
      Process.sleep(1000)

      assert {:ok, 3} =
               Assessments.save_assessment_point_entries([params_1, params_2, params_3],
                 log_profile_id: profile.id
               )

      expected_entry_1 =
        Repo.get_by(AssessmentPointEntry,
          assessment_point_id: assessment_point_1.id,
          student_id: student.id
        )

      assert expected_entry_1.ordinal_value_id == ov_1.id

      expected_entry_2 = Repo.get(AssessmentPointEntry, entry_2.id)
      assert expected_entry_2.ordinal_value_id == ov_2.id

      expected_entry_3 = Repo.get(AssessmentPointEntry, entry_3.id)
      assert is_nil(expected_entry_3.ordinal_value_id)

      on_exit(fn ->
        assert_supervised_tasks_are_down()

        entry_1_log =
          Repo.get_by!(AssessmentPointEntryLog,
            assessment_point_id: assessment_point_1.id,
            student_id: student.id
          )

        assert entry_1_log.ordinal_value_id == ov_1.id
        assert entry_1_log.profile_id == profile.id
        assert entry_1_log.operation == "CREATE"

        entry_2_log =
          Repo.get_by!(AssessmentPointEntryLog,
            assessment_point_entry_id: entry_2.id
          )

        assert entry_2_log.ordinal_value_id == ov_2.id
        assert entry_2_log.profile_id == profile.id
        assert entry_2_log.operation == "UPDATE"

        entry_3_log =
          Repo.get_by!(AssessmentPointEntryLog,
            assessment_point_entry_id: entry_3.id
          )

        assert entry_3_log.ordinal_value_id == nil
        assert entry_3_log.profile_id == profile.id
        assert entry_3_log.operation == "UPDATE"
      end)
    end

    test "save_assessment_point_entries/2 updates student_ordinal_value_id on existing entries" do
      scale = insert(:scale, type: "ordinal")
      ov_1 = insert(:ordinal_value, scale_id: scale.id)
      ov_2 = insert(:ordinal_value, scale_id: scale.id)

      student = SchoolsFixtures.student_fixture()
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})

      # existing entry with an initial student ordinal value, so the save hits the
      # upsert conflict (update) path rather than a plain insert
      entry =
        assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point.id,
          scale_id: scale.id,
          scale_type: scale.type,
          student_ordinal_value_id: ov_1.id
        })

      base_params = %{
        "student_id" => student.id,
        "assessment_point_id" => assessment_point.id,
        "scale_id" => scale.id,
        "scale_type" => scale.type
      }

      assert {:ok, 1} =
               Assessments.save_assessment_point_entries([
                 Map.put(base_params, "student_ordinal_value_id", ov_2.id)
               ])

      assert Repo.get(AssessmentPointEntry, entry.id).student_ordinal_value_id == ov_2.id

      # clearing the value should null the column
      assert {:ok, 1} =
               Assessments.save_assessment_point_entries([
                 Map.put(base_params, "student_ordinal_value_id", "")
               ])

      assert is_nil(Repo.get(AssessmentPointEntry, entry.id).student_ordinal_value_id)
    end

    test "save_assessment_point_entries/2 clears is_missing when ordinal_value_id is set" do
      scale = insert(:scale, type: "ordinal")
      ov = insert(:ordinal_value, scale_id: scale.id)
      student = SchoolsFixtures.student_fixture()
      assessment_point = assessment_point_fixture(%{scale_id: scale.id})

      entry =
        assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: assessment_point.id,
          scale_id: scale.id,
          scale_type: "ordinal",
          is_missing: true
        })

      params = %{
        "student_id" => student.id,
        "assessment_point_id" => assessment_point.id,
        "scale_id" => scale.id,
        "scale_type" => "ordinal",
        "ordinal_value_id" => ov.id
      }

      assert {:ok, 1} = Assessments.save_assessment_point_entries([params])

      assert %AssessmentPointEntry{is_missing: false} = Repo.get!(AssessmentPointEntry, entry.id)
    end

    test "save_assessment_point_entries/2 enqueues composed entry recalc when saved entry is a component" do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      parent_ap = insert(:assessment_point, uses_composition: true, scale: scale)
      component_ap = insert(:assessment_point, scale: scale)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap)

      student = insert(:student)
      profile = Lanttern.IdentityFixtures.staff_member_profile_fixture()

      params = %{
        "student_id" => student.id,
        "assessment_point_id" => component_ap.id,
        "scale_id" => scale.id,
        "scale_type" => "numeric",
        "score" => 50.0
      }

      assert {:ok, 1} =
               Assessments.save_assessment_point_entries([params], log_profile_id: profile.id)

      assert_enqueued(
        worker: Lanttern.Workers.ComposedEntryRecalcWorker,
        args: %{
          "pairs" => [[parent_ap.id, student.id]],
          "domain" => "teacher_entry",
          "profile_id" => profile.id
        }
      )
    end

    test "save_assessment_point_entries/2 does not enqueue recalc when no composed parent is affected" do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      assessment_point = insert(:assessment_point, scale: scale)
      student = insert(:student)

      params = %{
        "student_id" => student.id,
        "assessment_point_id" => assessment_point.id,
        "scale_id" => scale.id,
        "scale_type" => "numeric",
        "score" => 10.0
      }

      assert {:ok, 1} = Assessments.save_assessment_point_entries([params])

      refute_enqueued(worker: Lanttern.Workers.ComposedEntryRecalcWorker)
    end

    test "save_assessment_point_entries/2 passes student_score field when only student_score is edited" do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      parent_ap = insert(:assessment_point, uses_composition: true, scale: scale)
      component_ap = insert(:assessment_point, scale: scale)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap)

      student = insert(:student)

      params = %{
        "student_id" => student.id,
        "assessment_point_id" => component_ap.id,
        "scale_id" => scale.id,
        "scale_type" => "numeric",
        "student_score" => 25.0
      }

      assert {:ok, 1} = Assessments.save_assessment_point_entries([params])

      assert_enqueued(
        worker: Lanttern.Workers.ComposedEntryRecalcWorker,
        args: %{
          "pairs" => [[parent_ap.id, student.id]],
          "domain" => "student_entry",
          "profile_id" => nil
        }
      )
    end

    test "save_assessment_point_entries/2 enqueues student recalc when only student_ordinal_value_id is edited" do
      scale = insert(:scale, type: "ordinal")
      ordinal_value = insert(:ordinal_value, scale: scale)
      parent_ap = insert(:assessment_point, uses_composition: true, scale: scale)
      component_ap = insert(:assessment_point, scale: scale)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap)

      student = insert(:student)

      params = %{
        "student_id" => student.id,
        "assessment_point_id" => component_ap.id,
        "scale_id" => scale.id,
        "scale_type" => "ordinal",
        "student_ordinal_value_id" => ordinal_value.id
      }

      assert {:ok, 1} = Assessments.save_assessment_point_entries([params])

      assert_enqueued(
        worker: Lanttern.Workers.ComposedEntryRecalcWorker,
        args: %{
          "pairs" => [[parent_ap.id, student.id]],
          "domain" => "student_entry",
          "profile_id" => nil
        }
      )
    end

    test "save_assessment_point_entries/2 enqueues recalc for both domains when only is_missing is edited" do
      scale = insert(:scale, type: "ordinal")
      parent_ap = insert(:assessment_point, uses_composition: true, scale: scale)
      component_ap = insert(:assessment_point, scale: scale)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap)

      student = insert(:student)

      params = %{
        "student_id" => student.id,
        "assessment_point_id" => component_ap.id,
        "scale_id" => scale.id,
        "scale_type" => "ordinal",
        "is_missing" => true
      }

      assert {:ok, 1} = Assessments.save_assessment_point_entries([params])

      # is_missing feeds both the teacher and student average, so both domains
      # must be recomputed
      assert_enqueued(
        worker: Lanttern.Workers.ComposedEntryRecalcWorker,
        args: %{"pairs" => [[parent_ap.id, student.id]], "domain" => "teacher_entry"}
      )

      assert_enqueued(
        worker: Lanttern.Workers.ComposedEntryRecalcWorker,
        args: %{"pairs" => [[parent_ap.id, student.id]], "domain" => "student_entry"}
      )
    end

    test "update_assessment_point_entry/3 enqueues composed recalc for the changed teacher domain" do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      parent_ap = insert(:assessment_point, uses_composition: true, scale: scale)
      component_ap = insert(:assessment_point, scale: scale)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap)

      student = insert(:student)
      profile = Lanttern.IdentityFixtures.staff_member_profile_fixture()

      entry =
        insert(:assessment_point_entry,
          assessment_point: component_ap,
          student: student,
          scale: scale,
          scale_type: "numeric",
          score: 10.0
        )

      assert {:ok, _entry} =
               Assessments.update_assessment_point_entry(entry, %{score: 50.0},
                 log_profile_id: profile.id
               )

      assert_enqueued(
        worker: Lanttern.Workers.ComposedEntryRecalcWorker,
        args: %{
          "pairs" => [[parent_ap.id, student.id]],
          "domain" => "teacher_entry",
          "profile_id" => profile.id
        }
      )
    end

    test "update_assessment_point_entry/3 enqueues both domains when is_missing changes" do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      parent_ap = insert(:assessment_point, uses_composition: true, scale: scale)
      component_ap = insert(:assessment_point, scale: scale)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap)

      student = insert(:student)

      entry =
        insert(:assessment_point_entry,
          assessment_point: component_ap,
          student: student,
          scale: scale,
          scale_type: "numeric"
        )

      assert {:ok, _entry} = Assessments.update_assessment_point_entry(entry, %{is_missing: true})

      assert_enqueued(
        worker: Lanttern.Workers.ComposedEntryRecalcWorker,
        args: %{"pairs" => [[parent_ap.id, student.id]], "domain" => "teacher_entry"}
      )

      assert_enqueued(
        worker: Lanttern.Workers.ComposedEntryRecalcWorker,
        args: %{"pairs" => [[parent_ap.id, student.id]], "domain" => "student_entry"}
      )
    end

    test "update_assessment_point_entry/3 does not enqueue when the AP is not a component" do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      assessment_point = insert(:assessment_point, scale: scale)
      student = insert(:student)

      entry =
        insert(:assessment_point_entry,
          assessment_point: assessment_point,
          student: student,
          scale: scale,
          scale_type: "numeric",
          score: 10.0
        )

      assert {:ok, _entry} = Assessments.update_assessment_point_entry(entry, %{score: 20.0})

      refute_enqueued(worker: Lanttern.Workers.ComposedEntryRecalcWorker)
    end

    test "update_assessment_point_entry/3 does not enqueue when no marking domain changes" do
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      parent_ap = insert(:assessment_point, uses_composition: true, scale: scale)
      component_ap = insert(:assessment_point, scale: scale)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap)

      student = insert(:student)

      entry =
        insert(:assessment_point_entry,
          assessment_point: component_ap,
          student: student,
          scale: scale,
          scale_type: "numeric",
          score: 10.0
        )

      # only a comment changes — no composition input is touched
      assert {:ok, _entry} =
               Assessments.update_assessment_point_entry(entry, %{report_note: "a comment"})

      refute_enqueued(worker: Lanttern.Workers.ComposedEntryRecalcWorker)
    end

    test "save_assessment_point_entries/2 is not deduped for identical rapid re-saves" do
      # regression: `unique: true` used to silently drop a recalc whose args
      # matched one enqueued (incl. already completed) in the last 60s, leaving
      # the composed entry stale. Each enqueue must produce its own job.
      scale = insert(:scale, type: "numeric", max_score: 100.0)
      parent_ap = insert(:assessment_point, uses_composition: true, scale: scale)
      component_ap = insert(:assessment_point, scale: scale)
      insert(:assessment_point_component, parent: parent_ap, component: component_ap)

      student = insert(:student)

      params = %{
        "student_id" => student.id,
        "assessment_point_id" => component_ap.id,
        "scale_id" => scale.id,
        "scale_type" => "numeric",
        "score" => 50.0
      }

      assert {:ok, 1} = Assessments.save_assessment_point_entries([params])
      assert {:ok, 1} = Assessments.save_assessment_point_entries([params])

      # under the old `unique: true` the second insert was a silent conflict and
      # produced no second row; without it each enqueue creates its own job.
      assert [_first, _second] =
               all_enqueued(
                 worker: Lanttern.Workers.ComposedEntryRecalcWorker,
                 args: %{"pairs" => [[parent_ap.id, student.id]], "domain" => "teacher_entry"}
               )
    end

    test "delete_assessment_point_entry/2 deletes the assessment_point_entry" do
      assessment_point_entry = assessment_point_entry_fixture()

      # profile to test log
      profile = Lanttern.IdentityFixtures.staff_member_profile_fixture()

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
      profile = IdentityFixtures.staff_member_profile_fixture()
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

  describe "assessment point rubrics" do
    alias Lanttern.Rubrics.Rubric
    import Lanttern.AssessmentsFixtures
    alias Lanttern.LearningContextFixtures

    test "create_assessment_point_rubric/3 with valid data creates a rubric linked to the given assessment point" do
      strand = LearningContextFixtures.strand_fixture()
      assessment_point = assessment_point_fixture(%{strand_id: strand.id})

      valid_attrs = %{
        criteria: "some criteria",
        scale_id: assessment_point.scale_id,
        strand_id: strand.id,
        curriculum_item_id: assessment_point.curriculum_item_id
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

    alias Lanttern.IdentityFixtures
    alias Lanttern.LearningContextFixtures
    alias Lanttern.RubricsFixtures
    alias Lanttern.SchoolsFixtures

    test "list_strand_goals_for_student/2 returns the list of strand goals with student assessments" do
      #      | moment_1 | moment_2 | moment_3 |
      # ---------------------------------------
      # ci_1 |    2     |    1     |    1     | (no entry in m1 pos 2 and m3)
      # ci_2 |    -     |    1     |    -     |
      # ci_3 |    -     |    -     |    -     | (no entry for goal)
      # ci_4 |    1     |    -     |    -     | (no entry for goal)

      strand = LearningContextFixtures.strand_fixture()

      moment_1 = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})
      moment_2 = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})
      moment_3 = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      curriculum_component_1 = insert(:curriculum_component)
      curriculum_component_2 = insert(:curriculum_component)
      curriculum_component_3_4 = insert(:curriculum_component)

      curriculum_item_1 =
        insert(:curriculum_item, %{
          curriculum_component_id: curriculum_component_1.id
        })

      curriculum_item_2 =
        insert(:curriculum_item, %{
          curriculum_component_id: curriculum_component_2.id
        })

      curriculum_item_3 =
        insert(:curriculum_item, %{
          curriculum_component_id: curriculum_component_3_4.id
        })

      curriculum_item_4 =
        insert(:curriculum_item, %{
          curriculum_component_id: curriculum_component_3_4.id
        })

      ordinal_scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ordinal_value = insert(:ordinal_value, scale_id: ordinal_scale.id)
      numeric_scale = insert(:scale, type: "numeric", max_score: 100.0)

      rubric_1 = RubricsFixtures.rubric_fixture(%{scale_id: ordinal_scale.id})
      rubric_3 = RubricsFixtures.rubric_fixture(%{scale_id: ordinal_scale.id})

      # create diff rubric to test query consistency
      # (only diff rubrics of the student should be loaded)
      diff_rubric_3 =
        RubricsFixtures.rubric_fixture(%{
          scale_id: ordinal_scale.id,
          is_differentiation: true
        })

      other_diff_rubric_3 =
        RubricsFixtures.rubric_fixture(%{
          scale_id: ordinal_scale.id,
          is_differentiation: true
        })

      student = SchoolsFixtures.student_fixture()

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

      assessment_point_4 =
        assessment_point_fixture(%{
          position: 4,
          curriculum_item_id: curriculum_item_4.id,
          scale_id: ordinal_scale.id,
          strand_id: strand.id
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
          ordinal_value_id: ordinal_value.id,
          differentiation_rubric_id: diff_rubric_3.id
        })

      ci_1_m_1_1 =
        assessment_point_fixture(%{
          curriculum_item_id: curriculum_item_1.id,
          scale_id: ordinal_scale.id,
          moment_id: moment_1.id
        })

      ci_1_m_1_2 =
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

      _empty_ci_1_m_3 =
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

      _empty_entry_ci_1_m_1_2 =
        assessment_point_entry_fixture(%{
          assessment_point_id: ci_1_m_1_2.id,
          student_id: student.id,
          scale_id: ordinal_scale.id,
          scale_type: ordinal_scale.type
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

      ci_4_m_1 =
        assessment_point_fixture(%{
          curriculum_item_id: curriculum_item_4.id,
          scale_id: ordinal_scale.id,
          moment_id: moment_1.id
        })

      entry_ci_4_m_1 =
        assessment_point_entry_fixture(%{
          assessment_point_id: ci_4_m_1.id,
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
          scale_type: ordinal_scale.type,
          ordinal_value_id: ordinal_value.id,
          differentiation_rubric_id: other_diff_rubric_3.id
        })

      assert [
               {expected_ap_1, expected_entry_1, [expected_ci_1_m_1_1, expected_ci_1_m_2]},
               {expected_ap_2, expected_entry_2, [expected_ci_2_m_2]},
               {expected_ap_3, expected_entry_3, []},
               {expected_ap_4, nil, [expected_ci_4_m_1]}
             ] = Assessments.list_strand_goals_for_student(student.id, strand.id)

      assert expected_ap_1.id == assessment_point_1.id
      assert expected_ap_1.scale_id == ordinal_scale.id
      assert expected_ap_1.rubric_id == rubric_1.id
      refute expected_ap_1.has_diff_rubric_for_student
      assert expected_ap_1.curriculum_item.id == curriculum_item_1.id
      assert expected_ap_1.curriculum_item.curriculum_component.id == curriculum_component_1.id
      assert expected_ap_1.curriculum_item.id == curriculum_item_1.id
      assert expected_entry_1.id == entry_1.id
      assert expected_entry_1.ordinal_value_id == ordinal_value.id

      assert expected_ci_1_m_1_1.id == entry_ci_1_m_1_1.id
      assert expected_ci_1_m_1_1.ordinal_value_id == ordinal_value.id
      assert expected_ci_1_m_2.id == entry_ci_1_m_2.id
      assert expected_ci_1_m_2.ordinal_value_id == ordinal_value.id

      assert expected_ap_2.id == assessment_point_2.id
      assert expected_ap_2.scale_id == numeric_scale.id
      assert expected_ap_2.curriculum_item.id == curriculum_item_2.id
      assert expected_ap_2.curriculum_item.curriculum_component.id == curriculum_component_2.id
      assert expected_entry_2.id == entry_2.id
      assert expected_entry_2.score == 5.0

      assert expected_ci_2_m_2.id == entry_ci_2_m_2.id
      assert expected_ci_2_m_2.ordinal_value_id == ordinal_value.id

      assert expected_ap_3.id == assessment_point_3.id
      assert expected_ap_3.scale_id == ordinal_scale.id
      assert expected_ap_3.rubric_id == rubric_3.id
      assert expected_ap_3.has_diff_rubric_for_student
      assert expected_ap_3.curriculum_item.id == curriculum_item_3.id
      assert expected_ap_3.curriculum_item.curriculum_component.id == curriculum_component_3_4.id
      assert expected_entry_3.id == entry_3.id
      assert expected_entry_3.ordinal_value_id == ordinal_value.id

      assert expected_ap_4.id == assessment_point_4.id
      assert expected_ap_4.scale_id == ordinal_scale.id
      assert expected_ap_4.curriculum_item.id == curriculum_item_4.id
      assert expected_ap_4.curriculum_item.curriculum_component.id == curriculum_component_3_4.id

      assert expected_ci_4_m_1.id == entry_ci_4_m_1.id
      assert expected_ci_4_m_1.ordinal_value_id == ordinal_value.id
    end
  end

  describe "strand assessment points" do
    alias Lanttern.Assessments.AssessmentPoint

    # import Lanttern.AssessmentsFixtures
    # alias Lanttern.IdentityFixtures

    alias Lanttern.LearningContextFixtures
    # alias Lanttern.SchoolsFixtures

    setup :strand_assessment_points_setup

    test "list_strand_assessment_points/1 returns assessment points grouped by moment as expected",
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
               Assessments.list_strand_assessment_points(strand.id)

      assert expected_m_1_ap_1_ci_1.id == m_1_ap_1_ci_1.id
      assert expected_m_1_ap_1_ci_1.curriculum_item.id == ci_1.id
      assert expected_m_1_ap_1_ci_1.curriculum_item.curriculum_component.id == cc.id
      assert %Lanttern.Grading.Scale{} = expected_m_1_ap_1_ci_1.scale

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

    test "list_strand_assessment_point_ids/1 returns ids of all strand and moment assessment points",
         %{
           strand: strand,
           s_ap_1_ci_1: s_ap_1_ci_1,
           s_ap_2_ci_2: s_ap_2_ci_2,
           s_ap_3_ci_3: s_ap_3_ci_3,
           m_1_ap_1_ci_1: m_1_ap_1_ci_1,
           m_1_ap_2_ci_2: m_1_ap_2_ci_2,
           m_2_ap_1_ci_2: m_2_ap_1_ci_2
         } do
      result = Assessments.list_strand_assessment_point_ids(strand.id)

      assert s_ap_1_ci_1.id in result
      assert s_ap_2_ci_2.id in result
      assert s_ap_3_ci_3.id in result
      assert m_1_ap_1_ci_1.id in result
      assert m_1_ap_2_ci_2.id in result
      assert m_2_ap_1_ci_2.id in result
      assert length(result) == 6
    end

    test "list_strand_assessment_point_ids/1 does not return assessment points from other strands",
         %{strand: strand} do
      other_ap = insert(:assessment_point)

      result = Assessments.list_strand_assessment_point_ids(strand.id)

      refute other_ap.id in result
    end

    test "create_assessment_point/2 with valid data creates an assessment point linked to a strand" do
      strand = LearningContextFixtures.strand_fixture()
      curriculum_item = insert(:curriculum_item)
      scale = insert(:scale)

      valid_attrs = %{
        strand_id: strand.id,
        name: "some assessment point name abc",
        curriculum_item_id: curriculum_item.id,
        scale_id: scale.id
      }

      assert {:ok, %AssessmentPoint{} = assessment_point} =
               Assessments.create_assessment_point(%Lanttern.Identity.Scope{}, valid_attrs)

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
               Assessments.list_strand_students_entries(strand.id,
                 classes_ids: [class_a.id],
                 active_students_only: true
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
      student_1_cycle_info: student_1_cycle_info,
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
                 classes_ids: [class_a.id, class_b.id],
                 load_profile_picture_from_cycle_id: student_1_cycle_info.cycle_id,
                 active_students_only: true
               )

      assert expected_student_1.id == student_1.id
      assert expected_student_1.profile_picture_url == student_1_cycle_info.profile_picture_url
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

    cc = insert(:curriculum_component)
    ci_1 = insert(:curriculum_item, %{curriculum_component_id: cc.id})
    ci_2 = insert(:curriculum_item, %{curriculum_component_id: cc.id})
    ci_3 = insert(:curriculum_item, %{curriculum_component_id: cc.id})

    scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
    ov_a = insert(:ordinal_value, scale_id: scale.id)
    ov_b = insert(:ordinal_value, scale_id: scale.id)
    ov_c = insert(:ordinal_value, scale_id: scale.id)

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
        school_id: school.id,
        name: "AAA",
        classes_ids: [class_a.id, class_b.id]
      })

    # create cycle info to test profile picture loading
    student_1_cycle_info =
      Lanttern.StudentsCycleInfoFixtures.student_cycle_info_fixture(%{
        school_id: school.id,
        student_id: student_1.id,
        profile_picture_url: "http://example.com/profile_picture.jpg"
      })

    student_2 =
      Lanttern.SchoolsFixtures.student_fixture(%{name: "BBB", classes_ids: [class_a.id]})

    student_3 =
      Lanttern.SchoolsFixtures.student_fixture(%{name: "CCC", classes_ids: [class_a.id]})

    deactivated_student =
      Lanttern.SchoolsFixtures.student_fixture(%{
        classes_ids: [class_a.id],
        deactivated_at: ~U[2022-01-12 00:01:00.00Z]
      })

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

    # deactivated student entries
    # ci_3 s - ov_a

    _std_d_s_ap_3_ci_3 =
      Lanttern.AssessmentsFixtures.assessment_point_entry_fixture(%{
        student_id: deactivated_student.id,
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
      student_1_cycle_info: student_1_cycle_info,
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

  describe "strand moments assessment points with student entries" do
    alias Lanttern.Assessments.AssessmentPoint
    alias Lanttern.Identity.Scope

    import Lanttern.AssessmentsFixtures

    alias Lanttern.IdentityFixtures
    alias Lanttern.LearningContextFixtures
    alias Lanttern.SchoolsFixtures

    test "list_strand_moments_assessment_points_with_student_entries/3 returns aps with student entries ordered by moment then ap position" do
      school = SchoolsFixtures.school_fixture()
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})
      scope = %Scope{school_id: school.id}

      strand = LearningContextFixtures.strand_fixture()
      # create in order so positions are 0, 1
      m_1 = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})
      m_2 = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = insert(:curriculum_item)

      # create in order so positions within m_1 are 0, 1, 2
      m_1_ap_1 =
        assessment_point_fixture(%{
          moment_id: m_1.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      m_1_ap_2 =
        assessment_point_fixture(%{
          moment_id: m_1.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      # AP in m_1 with no entry for this student – should be ignored
      _m_1_ap_no_entry =
        assessment_point_fixture(%{
          moment_id: m_1.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      m_2_ap_1 =
        assessment_point_fixture(%{
          moment_id: m_2.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      m_1_entry_1 =
        assessment_point_entry_fixture(%{
          assessment_point_id: m_1_ap_1.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      m_1_entry_2 =
        assessment_point_entry_fixture(%{
          assessment_point_id: m_1_ap_2.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      m_2_entry_1 =
        assessment_point_entry_fixture(%{
          assessment_point_id: m_2_ap_1.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      # entry for a different student – should not appear in results
      other_student = SchoolsFixtures.student_fixture(%{school_id: school.id})

      _other_entry =
        assessment_point_entry_fixture(%{
          assessment_point_id: m_1_ap_1.id,
          student_id: other_student.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      m_1_ap_1_id = m_1_ap_1.id
      m_1_ap_2_id = m_1_ap_2.id
      m_2_ap_1_id = m_2_ap_1.id

      assert [
               %AssessmentPoint{id: ^m_1_ap_1_id, student_entry: entry_1},
               %AssessmentPoint{id: ^m_1_ap_2_id, student_entry: entry_2},
               %AssessmentPoint{id: ^m_2_ap_1_id, student_entry: entry_3}
             ] =
               Assessments.list_strand_moments_assessment_points_with_student_entries(
                 scope,
                 student,
                 strand.id
               )

      assert entry_1.id == m_1_entry_1.id
      assert entry_1.ordinal_value.id == ov.id
      assert entry_2.id == m_1_entry_2.id
      assert entry_3.id == m_2_entry_1.id
    end

    test "list_strand_moments_assessment_points_with_student_entries/3 excludes assessment points with unmarked entries" do
      school = SchoolsFixtures.school_fixture()
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})
      scope = %Scope{school_id: school.id}

      strand = LearningContextFixtures.strand_fixture()
      m_1 = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = insert(:curriculum_item)

      ap_marked =
        assessment_point_fixture(%{
          moment_id: m_1.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      ap_unmarked =
        assessment_point_fixture(%{
          moment_id: m_1.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      # entry with marking (ordinal_value assigned)
      _entry_marked =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap_marked.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      # entry without marking (no ordinal_value, no score) — should be excluded
      _entry_unmarked =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap_unmarked.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      ap_marked_id = ap_marked.id

      assert [%AssessmentPoint{id: ^ap_marked_id}] =
               Assessments.list_strand_moments_assessment_points_with_student_entries(
                 scope,
                 student,
                 strand.id
               )
    end

    test "list_strand_moments_assessment_points_with_student_entries/3 calculates has_evidences correctly" do
      school = SchoolsFixtures.school_fixture()
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})
      scope = %Scope{school_id: school.id}

      profile = IdentityFixtures.staff_member_profile_fixture()

      strand = LearningContextFixtures.strand_fixture()
      m_1 = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = insert(:curriculum_item)

      # create in order so positions are 0, 1
      ap_with_evidence =
        assessment_point_fixture(%{
          moment_id: m_1.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      ap_without_evidence =
        assessment_point_fixture(%{
          moment_id: m_1.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      entry_with_evidence =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap_with_evidence.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      _entry_without_evidence =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap_without_evidence.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      {:ok, _attachment} =
        Assessments.create_assessment_point_entry_evidence(
          %{current_profile: profile},
          entry_with_evidence.id,
          %{
            "name" => "Evidence attachment",
            "link" => "https://somevaliduri.com",
            "is_external" => true
          }
        )

      ap_with_evidence_id = ap_with_evidence.id
      ap_without_evidence_id = ap_without_evidence.id

      assert [
               %AssessmentPoint{id: ^ap_with_evidence_id, student_entry: entry_1},
               %AssessmentPoint{id: ^ap_without_evidence_id, student_entry: entry_2}
             ] =
               Assessments.list_strand_moments_assessment_points_with_student_entries(
                 scope,
                 student,
                 strand.id
               )

      assert entry_1.has_evidences == true
      assert entry_2.has_evidences == false
    end
  end

  describe "lesson assessment points with student entries" do
    alias Lanttern.Assessments.AssessmentPoint
    alias Lanttern.Identity.Scope

    import Lanttern.AssessmentsFixtures

    alias Lanttern.IdentityFixtures
    alias Lanttern.LearningContextFixtures
    alias Lanttern.SchoolsFixtures

    test "list_lesson_assessment_points_with_student_entries/3 returns aps with student entries ordered by ap position" do
      school = SchoolsFixtures.school_fixture()
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})
      scope = %Scope{school_id: school.id}

      strand = LearningContextFixtures.strand_fixture()
      lesson = insert(:lesson, strand: strand)

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = insert(:curriculum_item)

      # create in order so positions are 0, 1
      ap_1 =
        assessment_point_fixture(%{
          lesson_id: lesson.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      ap_2 =
        assessment_point_fixture(%{
          lesson_id: lesson.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      # AP with no entry for this student – should be ignored
      _ap_no_entry =
        assessment_point_fixture(%{
          lesson_id: lesson.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      entry_1 =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap_1.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      entry_2 =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap_2.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      # entry for a different student – should not appear in results
      other_student = SchoolsFixtures.student_fixture(%{school_id: school.id})

      _other_entry =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap_1.id,
          student_id: other_student.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      ap_1_id = ap_1.id
      ap_2_id = ap_2.id

      assert [
               %AssessmentPoint{id: ^ap_1_id, student_entry: result_entry_1},
               %AssessmentPoint{id: ^ap_2_id, student_entry: result_entry_2}
             ] =
               Assessments.list_lesson_assessment_points_with_student_entries(
                 scope,
                 student,
                 lesson.id
               )

      assert result_entry_1.id == entry_1.id
      assert result_entry_1.ordinal_value.id == ov.id
      assert result_entry_2.id == entry_2.id
    end

    test "list_lesson_assessment_points_with_student_entries/3 excludes assessment points with unmarked entries" do
      school = SchoolsFixtures.school_fixture()
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})
      scope = %Scope{school_id: school.id}

      strand = LearningContextFixtures.strand_fixture()
      lesson = insert(:lesson, strand: strand)

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = insert(:curriculum_item)

      ap_marked =
        assessment_point_fixture(%{
          lesson_id: lesson.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      ap_unmarked =
        assessment_point_fixture(%{
          lesson_id: lesson.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      _entry_marked =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap_marked.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      # entry without marking – should be excluded
      _entry_unmarked =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap_unmarked.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      ap_marked_id = ap_marked.id

      assert [%AssessmentPoint{id: ^ap_marked_id}] =
               Assessments.list_lesson_assessment_points_with_student_entries(
                 scope,
                 student,
                 lesson.id
               )
    end

    test "list_lesson_assessment_points_with_student_entries/3 excludes hidden assessment points" do
      school = SchoolsFixtures.school_fixture()
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})
      scope = %Scope{school_id: school.id}

      strand = LearningContextFixtures.strand_fixture()
      lesson = insert(:lesson, strand: strand)

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = insert(:curriculum_item)

      ap_visible =
        assessment_point_fixture(%{
          lesson_id: lesson.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      ap_hidden =
        assessment_point_fixture(%{
          lesson_id: lesson.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id,
          is_hidden: true
        })

      _entry_visible =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap_visible.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      # marked entry on the hidden assessment point – should still be excluded
      _entry_hidden =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap_hidden.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      ap_visible_id = ap_visible.id

      assert [%AssessmentPoint{id: ^ap_visible_id}] =
               Assessments.list_lesson_assessment_points_with_student_entries(
                 scope,
                 student,
                 lesson.id
               )
    end

    test "list_lesson_assessment_points_with_student_entries/3 calculates has_evidences correctly" do
      school = SchoolsFixtures.school_fixture()
      student = SchoolsFixtures.student_fixture(%{school_id: school.id})
      scope = %Scope{school_id: school.id}

      profile = IdentityFixtures.staff_member_profile_fixture()

      strand = LearningContextFixtures.strand_fixture()
      lesson = insert(:lesson, strand: strand)

      scale = insert(:scale, type: "ordinal", breakpoints: [0.4, 0.8])
      ov = insert(:ordinal_value, scale_id: scale.id)
      ci = insert(:curriculum_item)

      ap_with_evidence =
        assessment_point_fixture(%{
          lesson_id: lesson.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      ap_without_evidence =
        assessment_point_fixture(%{
          lesson_id: lesson.id,
          scale_id: scale.id,
          curriculum_item_id: ci.id
        })

      entry_with_evidence =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap_with_evidence.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      _entry_without_evidence =
        assessment_point_entry_fixture(%{
          assessment_point_id: ap_without_evidence.id,
          student_id: student.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov.id
        })

      {:ok, _attachment} =
        Assessments.create_assessment_point_entry_evidence(
          %{current_profile: profile},
          entry_with_evidence.id,
          %{
            "name" => "Evidence attachment",
            "link" => "https://somevaliduri.com",
            "is_external" => true
          }
        )

      ap_with_evidence_id = ap_with_evidence.id
      ap_without_evidence_id = ap_without_evidence.id

      assert [
               %AssessmentPoint{id: ^ap_with_evidence_id, student_entry: entry_1},
               %AssessmentPoint{id: ^ap_without_evidence_id, student_entry: entry_2}
             ] =
               Assessments.list_lesson_assessment_points_with_student_entries(
                 scope,
                 student,
                 lesson.id
               )

      assert entry_1.has_evidences == true
      assert entry_2.has_evidences == false
    end
  end
end
