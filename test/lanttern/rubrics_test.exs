defmodule Lanttern.RubricsTest do
  alias Lanttern.SchoolsFixtures
  use Lanttern.DataCase

  alias Lanttern.Rubrics
  import Lanttern.RubricsFixtures

  describe "rubrics" do
    alias Lanttern.Rubrics.Rubric

    alias Lanttern.AssessmentsFixtures
    alias Lanttern.CurriculaFixtures
    alias Lanttern.GradingFixtures
    alias Lanttern.LearningContextFixtures
    alias Lanttern.SchoolsFixtures

    @invalid_attrs %{criteria: nil, is_differentiation: nil}

    test "list_rubrics/1 returns all rubrics" do
      rubric = rubric_fixture()
      assert Rubrics.list_rubrics() == [rubric]
    end

    test "list_rubrics/1 with preloads returns all rubrics with preloaded data" do
      scale = GradingFixtures.scale_fixture()

      rubric = rubric_fixture(%{scale_id: scale.id})

      [expected] = Rubrics.list_rubrics(preloads: :scale)
      assert expected.id == rubric.id
      assert expected.scale.id == scale.id
    end

    test "list_rubrics/1 with scale_id and is_differentiation opts returns all rubrics filtered" do
      scale = GradingFixtures.scale_fixture()

      rubric = rubric_fixture(%{scale_id: scale.id, is_differentiation: true})

      # extra rubrics for filtering test
      rubric_fixture(%{scale_id: scale.id, is_differentiation: false})
      rubric_fixture(%{is_differentiation: true})

      assert [rubric] == Rubrics.list_rubrics(scale_id: scale.id, is_differentiation: true)
    end

    test "list_student_strand_rubrics_grouped_by_goal/2 returns all rubrics with descriptors preloaded and ordered correctly" do
      strand = LearningContextFixtures.strand_fixture()
      moment = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      curriculum_component = CurriculaFixtures.curriculum_component_fixture()

      curriculum_item =
        CurriculaFixtures.curriculum_item_fixture(%{
          curriculum_component_id: curriculum_component.id
        })

      diff_curriculum_item =
        CurriculaFixtures.curriculum_item_fixture(%{
          curriculum_component_id: curriculum_component.id
        })

      scale = GradingFixtures.scale_fixture()

      rubric_1 =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id
        })

      rubric_1_diff =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          is_differentiation: true
        })

      rubric_2 =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id
        })

      rubric_3 =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id
        })

      diff_goal_rubric =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: diff_curriculum_item.id
        })

      goal =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id,
          rubric_id: rubric_1.id
        })

      diff_goal =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: diff_curriculum_item.id,
          scale_id: scale.id,
          rubric_id: diff_goal_rubric.id,
          is_differentiation: true
        })

      moment_ap_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment.id,
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id,
          rubric_id: rubric_2.id
        })

      _moment_ap_2 =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment.id,
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id,
          rubric_id: rubric_3.id
        })

      school = SchoolsFixtures.school_fixture()

      student =
        SchoolsFixtures.student_fixture(%{school_id: school.id})

      _student_diff_ape =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: goal.id,
          differentiation_rubric_id: rubric_1_diff.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      _student_diff_goal_ape =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: diff_goal.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      _student_moment_ap_1_ape =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student.id,
          assessment_point_id: moment_ap_1.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      # other fixtures for filter test

      _other_diff_goal =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand.id,
          scale_id: scale.id,
          rubric_id: rubric_fixture(%{scale_id: scale.id, strand_id: strand.id}).id,
          is_differentiation: true
        })

      other_class_student = SchoolsFixtures.student_fixture(%{school_id: school.id})

      _other_class_student_diff_ape =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: other_class_student.id,
          assessment_point_id: goal.id,
          differentiation_rubric_id: rubric_1_diff.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      # assert

      [
        {expected_goal, [expected_rubric_1_diff, expected_rubric_2, expected_rubric_3]},
        {expected_diff_goal, [expected_diff_goal_rubric]}
      ] = Rubrics.list_student_strand_rubrics_grouped_by_goal(student.id, strand.id)

      assert expected_goal.id == goal.id
      assert expected_goal.curriculum_item.id == curriculum_item.id

      assert expected_goal.curriculum_item.curriculum_component.id ==
               curriculum_component.id

      refute expected_goal.is_differentiation
      assert expected_rubric_1_diff.id == rubric_1_diff.id
      assert expected_rubric_2.id == rubric_2.id
      assert expected_rubric_3.id == rubric_3.id

      assert expected_diff_goal.id == diff_goal.id
      assert expected_diff_goal.curriculum_item.id == diff_curriculum_item.id

      assert expected_diff_goal.curriculum_item.curriculum_component.id ==
               curriculum_component.id

      assert expected_diff_goal.is_differentiation
      assert expected_diff_goal_rubric.id == diff_goal_rubric.id

      # use same setup to validate only_with_entries opt
      [
        {expected_goal, [expected_rubric_1_diff, expected_rubric_2]},
        {expected_diff_goal, [expected_diff_goal_rubric]}
      ] =
        Rubrics.list_student_strand_rubrics_grouped_by_goal(student.id, strand.id,
          only_with_entries: true
        )

      assert expected_goal.id == goal.id
      assert expected_goal.curriculum_item.id == curriculum_item.id

      assert expected_goal.curriculum_item.curriculum_component.id ==
               curriculum_component.id

      refute expected_goal.is_differentiation
      assert expected_rubric_1_diff.id == rubric_1_diff.id
      assert expected_rubric_2.id == rubric_2.id

      assert expected_diff_goal.id == diff_goal.id
      assert expected_diff_goal.curriculum_item.id == diff_curriculum_item.id

      assert expected_diff_goal.curriculum_item.curriculum_component.id ==
               curriculum_component.id

      assert expected_diff_goal.is_differentiation
      assert expected_diff_goal_rubric.id == diff_goal_rubric.id
    end

    test "list_assessment_point_rubrics/1 returns all rubrics matching the assessment point" do
      strand = LearningContextFixtures.strand_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()
      scale = GradingFixtures.scale_fixture()

      rubric =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id
        })

      diff_rubric =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          is_differentiation: true
        })

      assessment_point =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id
        })

      # extra fixtures for filter testing

      _other_scale_rubric =
        rubric_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id
        })

      _other_curriculum_diff_rubric =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id
        })

      # assert

      assert Rubrics.list_assessment_point_rubrics(assessment_point) == [
               rubric,
               diff_rubric
             ]
    end

    test "list_assessment_point_rubrics/1 with `exclude_diff` returns all not diff rubrics matching the assessment point" do
      strand = LearningContextFixtures.strand_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()
      scale = GradingFixtures.scale_fixture()

      rubric =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id
        })

      assessment_point =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id
        })

      # extra fixtures for filter testing

      _diff_rubric =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          is_differentiation: true
        })

      _other_scale_rubric =
        rubric_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id
        })

      _other_curriculum_diff_rubric =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id
        })

      # assert

      assert Rubrics.list_assessment_point_rubrics(assessment_point, exclude_diff: true) == [
               rubric
             ]
    end

    test "list_assessment_point_rubrics/1 with `only_diff` returns all diff rubrics matching the assessment point" do
      strand = LearningContextFixtures.strand_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()
      scale = GradingFixtures.scale_fixture()

      diff_rubric_1 =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          is_differentiation: true
        })

      diff_rubric_2 =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          is_differentiation: true
        })

      assessment_point =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id
        })

      # extra fixtures for filter testing

      _not_diff_rubric =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id
        })

      _other_scale_rubric =
        rubric_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id
        })

      _other_curriculum_diff_rubric =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          is_differentiation: true
        })

      # assert

      assert Rubrics.list_assessment_point_rubrics(assessment_point, only_diff: true) == [
               diff_rubric_1,
               diff_rubric_2
             ]
    end

    test "list_assessment_point_rubrics/1 with `only_diff` returns all diff rubrics matching the moment assessment point" do
      strand = LearningContextFixtures.strand_fixture()
      moment = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()
      scale = GradingFixtures.scale_fixture()

      diff_rubric_1 =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          is_differentiation: true
        })

      diff_rubric_2 =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          is_differentiation: true
        })

      assessment_point =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment.id,
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id
        })

      # extra fixtures for filter testing

      _not_diff_rubric =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id
        })

      _other_scale_rubric =
        rubric_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id
        })

      _other_curriculum_diff_rubric =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          is_differentiation: true
        })

      # assert

      assert Rubrics.list_assessment_point_rubrics(assessment_point, only_diff: true) == [
               diff_rubric_1,
               diff_rubric_2
             ]
    end

    test "list_strand_rubrics_grouped_by_goal/1 returns all strand rubrics" do
      strand = LearningContextFixtures.strand_fixture()

      curriculum_component = CurriculaFixtures.curriculum_component_fixture()

      curriculum_item =
        CurriculaFixtures.curriculum_item_fixture(%{
          curriculum_component_id: curriculum_component.id
        })

      diff_curriculum_item =
        CurriculaFixtures.curriculum_item_fixture(%{
          curriculum_component_id: curriculum_component.id
        })

      scale = GradingFixtures.scale_fixture()

      rubric_1 =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id
        })

      rubric_1_diff =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          is_differentiation: true
        })

      diff_goal_rubric =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: diff_curriculum_item.id
        })

      goal =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id
        })

      diff_goal =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: diff_curriculum_item.id,
          scale_id: scale.id,
          rubric_id: diff_goal_rubric.id,
          is_differentiation: true
        })

      school = SchoolsFixtures.school_fixture()
      class = SchoolsFixtures.class_fixture(%{school_id: school.id})

      student_a =
        SchoolsFixtures.student_fixture(%{
          name: "AAA",
          school_id: school.id,
          classes_ids: [class.id]
        })

      student_b =
        SchoolsFixtures.student_fixture(%{
          name: "BBB",
          school_id: school.id,
          classes_ids: [class.id]
        })

      _student_a_diff_ape =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student_a.id,
          assessment_point_id: goal.id,
          differentiation_rubric_id: rubric_1_diff.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      _student_b_diff_ape =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student_b.id,
          assessment_point_id: goal.id,
          differentiation_rubric_id: rubric_1_diff.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      _student_b_diff_goal_ape =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: student_b.id,
          assessment_point_id: diff_goal.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      # other fixtures for filter test

      other_class_student = SchoolsFixtures.student_fixture(%{school_id: school.id})

      _other_class_student_diff_ape =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: other_class_student.id,
          assessment_point_id: goal.id,
          differentiation_rubric_id: rubric_1_diff.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      # assert

      [
        {expected_goal, [expected_rubric_1, expected_rubric_1_diff]},
        {expected_diff_goal, [expected_diff_goal_rubric]}
      ] = Rubrics.list_strand_rubrics_grouped_by_goal(strand.id)

      assert expected_goal.id == goal.id
      assert expected_goal.curriculum_item.id == curriculum_item.id

      assert expected_goal.curriculum_item.curriculum_component.id ==
               curriculum_component.id

      refute expected_goal.is_differentiation
      assert expected_rubric_1.id == rubric_1.id
      assert expected_rubric_1_diff.id == rubric_1_diff.id

      assert expected_diff_goal.id == diff_goal.id
      assert expected_diff_goal.curriculum_item.id == diff_curriculum_item.id

      assert expected_diff_goal.curriculum_item.curriculum_component.id ==
               curriculum_component.id

      assert expected_diff_goal.is_differentiation
      assert expected_diff_goal_rubric.id == diff_goal_rubric.id

      # use same setup to validate exclude_diff opt
      [
        {expected_goal, [expected_rubric_1]}
      ] = Rubrics.list_strand_rubrics_grouped_by_goal(strand.id, exclude_diff: true)

      assert expected_goal.id == goal.id
      assert expected_rubric_1.id == rubric_1.id

      # use same setup to validate only_diff opt
      [
        {expected_goal, [expected_rubric_1_diff]},
        {expected_diff_goal, [expected_diff_goal_rubric]}
      ] =
        Rubrics.list_strand_rubrics_grouped_by_goal(strand.id,
          only_diff: true,
          preload_diff_students_from_classes_ids: [class.id]
        )

      assert expected_goal.id == goal.id
      assert expected_rubric_1_diff.id == rubric_1_diff.id
      assert expected_diff_goal.id == diff_goal.id
      assert expected_diff_goal_rubric.id == diff_goal_rubric.id

      [expected_student_a, expected_student_b] = expected_rubric_1_diff.diff_students
      assert expected_student_a.id == student_a.id
      assert expected_student_b.id == student_b.id

      [expected_student_b] = expected_diff_goal_rubric.diff_students
      assert expected_student_b.id == student_b.id
    end

    test "search_rubrics/2 returns all rubrics matched by search" do
      _rubric_1 = rubric_fixture(%{criteria: "lorem ipsum xolor sit amet"})
      rubric_2 = rubric_fixture(%{criteria: "lorem ipsum dolor sit amet"})
      rubric_3 = rubric_fixture(%{criteria: "lorem ipsum dolorxxx sit amet"})
      _rubric_4 = rubric_fixture(%{criteria: "lorem ipsum xxxxx sit amet"})

      expected = Rubrics.search_rubrics("dolor")

      assert length(expected) == 2

      # assert order
      assert [rubric_2, rubric_3] == expected
    end

    test "search_rubrics/2 with #id returns item with id" do
      rubric = rubric_fixture()
      rubric_fixture()
      rubric_fixture()
      rubric_fixture()

      [expected] = Rubrics.search_rubrics("##{rubric.id}")

      assert expected.id == rubric.id
    end

    test "search_rubrics/2 with is_differentiation opt returns results filtered by differentiation flag" do
      rubric = rubric_fixture(%{criteria: "abcde", is_differentiation: true})

      # create extra items for filtering test
      rubric_fixture(%{criteria: "abcde", is_differentiation: false})
      rubric_fixture(%{criteria: "zzzzz", is_differentiation: true})

      assert [rubric] == Rubrics.search_rubrics("abcde", is_differentiation: true)
    end

    test "get_rubric!/2 returns the rubric with given id" do
      rubric = rubric_fixture()
      assert Rubrics.get_rubric!(rubric.id) == rubric
    end

    test "get_rubric!/2 with preloads returns the rubric with given id and preloaded data" do
      scale = GradingFixtures.scale_fixture()

      rubric = rubric_fixture(%{scale_id: scale.id})

      expected =
        Rubrics.get_rubric!(rubric.id, preloads: :scale)

      assert expected.id == rubric.id
      assert expected.scale.id == scale.id
    end

    test "load_rubric_descriptors/1 returns rubric with descriptors preloaded and ordered correctly" do
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ov_1 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.1})
      ov_2 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.2})

      rubric = rubric_fixture(%{scale_id: scale.id})

      descriptor_2 =
        rubric_descriptor_fixture(%{
          rubric_id: rubric.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_2.id
        })

      descriptor_1 =
        rubric_descriptor_fixture(%{
          rubric_id: rubric.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_1.id
        })

      # other descriptors and rubrics for filter test
      rubric_descriptor_fixture()
      rubric_descriptor_fixture()

      expected = Rubrics.load_rubric_descriptors(rubric)
      assert expected.id == rubric.id

      [expected_descriptor_1, expected_descriptor_2] = expected.descriptors
      assert expected_descriptor_1.id == descriptor_1.id
      assert expected_descriptor_2.id == descriptor_2.id
    end

    test "get_full_rubric!/1 returns rubric with descriptors preloaded and ordered correctly" do
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ov_1 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.1})
      ov_2 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.2})

      rubric = rubric_fixture(%{scale_id: scale.id})

      descriptor_2 =
        rubric_descriptor_fixture(%{
          rubric_id: rubric.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_2.id
        })

      descriptor_1 =
        rubric_descriptor_fixture(%{
          rubric_id: rubric.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_1.id
        })

      expected = Rubrics.get_full_rubric!(rubric.id)
      assert expected.id == rubric.id

      [expected_descriptor_1, expected_descriptor_2] = expected.descriptors
      assert expected_descriptor_1.id == descriptor_1.id
      assert expected_descriptor_2.id == descriptor_2.id
    end

    test "create_rubric/1 with valid data creates a rubric" do
      valid_attrs = %{
        criteria: "some criteria",
        scale_id: GradingFixtures.scale_fixture().id,
        strand_id: LearningContextFixtures.strand_fixture().id,
        curriculum_item_id: CurriculaFixtures.curriculum_item_fixture().id,
        is_differentiation: true
      }

      assert {:ok, %Rubric{} = rubric} = Rubrics.create_rubric(valid_attrs)
      assert rubric.criteria == "some criteria"
      assert rubric.is_differentiation == true
    end

    test "create_rubric/1 with valid data including descriptors creates a rubric and related descriptors" do
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ordinal_value = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id})
      strand = LearningContextFixtures.strand_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()

      valid_attrs = %{
        criteria: "some criteria with descriptors",
        scale_id: scale.id,
        strand_id: strand.id,
        curriculum_item_id: curriculum_item.id,
        is_differentiation: true,
        descriptors: %{
          "0" => %{
            scale_id: scale.id,
            scale_type: scale.type,
            ordinal_value_id: ordinal_value.id,
            descriptor: "some descriptor in rubric"
          }
        }
      }

      assert {:ok, %Rubric{} = rubric} = Rubrics.create_rubric(valid_attrs)
      assert rubric.criteria == "some criteria with descriptors"
      assert rubric.is_differentiation == true

      [expected_descriptor] = rubric.descriptors
      assert expected_descriptor.descriptor == "some descriptor in rubric"
      assert expected_descriptor.ordinal_value_id == ordinal_value.id
    end

    test "create_rubric/1 with valid data and preloads opt creates a rubric and return it with preloaded data" do
      scale = GradingFixtures.scale_fixture()
      strand = LearningContextFixtures.strand_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()

      valid_attrs = %{
        criteria: "some criteria",
        scale_id: scale.id,
        strand_id: strand.id,
        curriculum_item_id: curriculum_item.id,
        is_differentiation: true
      }

      assert {:ok, %Rubric{} = rubric} =
               Rubrics.create_rubric(valid_attrs, preloads: [:scale, :strand, :curriculum_item])

      assert rubric.criteria == "some criteria"
      assert rubric.scale.id == scale.id
      assert rubric.strand.id == strand.id
      assert rubric.curriculum_item.id == curriculum_item.id
      assert rubric.is_differentiation == true
    end

    test "create_rubric/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rubrics.create_rubric(@invalid_attrs)
    end

    test "update_rubric/2 with valid data updates the rubric" do
      rubric = rubric_fixture()
      update_attrs = %{criteria: "some updated criteria", is_differentiation: false}

      assert {:ok, %Rubric{} = rubric} = Rubrics.update_rubric(rubric, update_attrs)
      assert rubric.criteria == "some updated criteria"
      assert rubric.is_differentiation == false
    end

    test "update_rubric/2 with valid data and preloads opt updates the rubric and return it with preloaded data" do
      rubric = rubric_fixture()
      scale = GradingFixtures.scale_fixture()

      update_attrs = %{
        criteria: "some updated criteria",
        scale_id: scale.id,
        is_differentiation: false
      }

      assert {:ok, %Rubric{} = rubric} =
               Rubrics.update_rubric(rubric, update_attrs, preloads: :scale)

      assert rubric.criteria == "some updated criteria"
      assert rubric.scale.id == scale.id
      assert rubric.is_differentiation == false
    end

    test "update_rubric/2 with valid data including descriptors updates the rubric and handle descriptors correctly" do
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})

      ordinal_value_1 =
        GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0})

      ordinal_value_2 =
        GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.5})

      ordinal_value_3 =
        GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 1})

      rubric = rubric_fixture(%{scale_id: scale.id})

      descriptor =
        rubric_descriptor_fixture(%{
          rubric_id: rubric.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ordinal_value_1.id
        })

      descriptor_to_remove =
        rubric_descriptor_fixture(%{
          rubric_id: rubric.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ordinal_value_2.id
        })

      rubric = rubric |> Lanttern.Repo.preload(:descriptors)

      update_attrs = %{
        criteria: "some updated criteria",
        descriptors: %{
          "0" => %{
            id: descriptor.id,
            rubric_id: rubric.id,
            scale_id: scale.id,
            scale_type: scale.type,
            ordinal_value_id: ordinal_value_1.id,
            descriptor: "updated descriptor 1"
          },
          "1" => %{
            rubric_id: rubric.id,
            scale_id: scale.id,
            scale_type: scale.type,
            ordinal_value_id: ordinal_value_3.id,
            descriptor: "new descriptor 3"
          }
        }
      }

      assert {:ok, %Rubric{} = rubric} = Rubrics.update_rubric(rubric, update_attrs)

      assert rubric.criteria == "some updated criteria"
      assert length(rubric.descriptors) == 2
      existing_descriptor = rubric.descriptors |> Enum.find(&(&1.id == descriptor.id))
      assert existing_descriptor.descriptor == "updated descriptor 1"
      refute rubric.descriptors |> Enum.find(&(&1.id == descriptor_to_remove.id))
      assert rubric.descriptors |> Enum.find(&(&1.descriptor == "new descriptor 3"))
    end

    test "update_rubric/2 with different scale handle the descriptors correctly" do
      scale_1 = GradingFixtures.scale_fixture(%{type: "ordinal"})
      scale_2 = GradingFixtures.scale_fixture(%{type: "ordinal"})

      ordinal_value_1 =
        GradingFixtures.ordinal_value_fixture(%{scale_id: scale_1.id})

      ordinal_value_2 =
        GradingFixtures.ordinal_value_fixture(%{scale_id: scale_2.id})

      rubric = rubric_fixture(%{scale_id: scale_1.id})

      _descriptor =
        rubric_descriptor_fixture(%{
          rubric_id: rubric.id,
          scale_id: scale_1.id,
          scale_type: scale_1.type,
          ordinal_value_id: ordinal_value_1.id
        })

      rubric = rubric |> Lanttern.Repo.preload(:descriptors)

      update_attrs = %{
        criteria: "some updated criteria",
        scale_id: scale_2.id,
        descriptors: %{
          "0" => %{
            rubric_id: rubric.id,
            scale_id: scale_2.id,
            scale_type: scale_2.type,
            ordinal_value_id: ordinal_value_2.id,
            descriptor: "different scale descriptor"
          }
        }
      }

      assert {:ok, %Rubric{} = rubric} = Rubrics.update_rubric(rubric, update_attrs)

      assert rubric.criteria == "some updated criteria"
      assert [expected_descriptor] = rubric.descriptors
      assert expected_descriptor.descriptor == "different scale descriptor"
      assert expected_descriptor.scale_id == scale_2.id
    end

    test "update_rubric/2 with invalid data returns error changeset" do
      rubric = rubric_fixture()
      assert {:error, %Ecto.Changeset{}} = Rubrics.update_rubric(rubric, @invalid_attrs)
      assert rubric == Rubrics.get_rubric!(rubric.id)
    end

    test "delete_rubric/1 deletes the rubric" do
      rubric = rubric_fixture()
      assert {:ok, %Rubric{}} = Rubrics.delete_rubric(rubric)
      assert_raise Ecto.NoResultsError, fn -> Rubrics.get_rubric!(rubric.id) end
    end

    test "change_rubric/1 returns a rubric changeset" do
      rubric = rubric_fixture()
      assert %Ecto.Changeset{} = Rubrics.change_rubric(rubric)
    end
  end

  describe "differentiation rubrics" do
    alias Lanttern.Rubrics.Rubric

    alias Lanttern.AssessmentsFixtures
    alias Lanttern.CurriculaFixtures
    alias Lanttern.GradingFixtures
    alias Lanttern.LearningContextFixtures
    alias Lanttern.SchoolsFixtures
    alias Lanttern.StudentsCycleInfoFixtures

    test "list_diff_students_for_rubric/1 returns all diff students linked to given rubric" do
      strand = LearningContextFixtures.strand_fixture()
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()
      diff_curriculum_item = CurriculaFixtures.curriculum_item_fixture()
      scale = GradingFixtures.scale_fixture()

      diff_rubric =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          is_differentiation: true
        })

      goal =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          scale_id: scale.id
        })

      diff_goal =
        AssessmentsFixtures.assessment_point_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: diff_curriculum_item.id,
          scale_id: scale.id,
          rubric_id: diff_rubric.id,
          is_differentiation: true
        })

      school = SchoolsFixtures.school_fixture()

      diff_rubric_student =
        SchoolsFixtures.student_fixture(%{
          name: "AAA",
          school_id: school.id
        })

      diff_goal_rubric_student =
        SchoolsFixtures.student_fixture(%{
          name: "BBB",
          school_id: school.id
        })

      cycle = SchoolsFixtures.cycle_fixture(%{school_id: school.id})

      _diff_rubric_student_cycle_info =
        StudentsCycleInfoFixtures.student_cycle_info_fixture(%{
          school_id: school.id,
          student_id: diff_rubric_student.id,
          cycle_id: cycle.id,
          profile_picture_url: "http://example.com/diff_student_profile_picture.jpg"
        })

      _diff_rubric_ape =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: diff_rubric_student.id,
          assessment_point_id: goal.id,
          differentiation_rubric_id: diff_rubric.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      _diff_goal_ape =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: diff_goal_rubric_student.id,
          assessment_point_id: diff_goal.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      # other fixtures for filter test

      not_diff_student = SchoolsFixtures.student_fixture()

      _not_diff_student_diff_rubric_ape =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: not_diff_student.id,
          assessment_point_id: goal.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      other_school_student = SchoolsFixtures.student_fixture()

      _other_school_student_diff_rubric_ape =
        AssessmentsFixtures.assessment_point_entry_fixture(%{
          student_id: other_school_student.id,
          assessment_point_id: goal.id,
          differentiation_rubric_id: diff_rubric.id,
          scale_id: scale.id,
          scale_type: scale.type
        })

      # assert

      [expected_diff_rubric_student, expected_diff_goal_rubric_student] =
        Rubrics.list_diff_students_for_rubric(diff_rubric.id, school.id,
          load_profile_picture_from_cycle_id: cycle.id
        )

      assert expected_diff_rubric_student.id == diff_rubric_student.id

      assert expected_diff_rubric_student.profile_picture_url ==
               "http://example.com/diff_student_profile_picture.jpg"

      assert expected_diff_goal_rubric_student.id == diff_goal_rubric_student.id
    end
  end

  describe "rubric_descriptors" do
    alias Lanttern.Rubrics.RubricDescriptor

    alias Lanttern.GradingFixtures

    @invalid_attrs %{descriptor: nil, score: nil}

    test "list_rubric_descriptors/0 returns all rubric_descriptors" do
      rubric_descriptor = rubric_descriptor_fixture()
      assert Rubrics.list_rubric_descriptors() == [rubric_descriptor]
    end

    test "build_rubrics_descriptors_map/1 returns the map of rubrics descriptors ordered correctly" do
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ov_1 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.1})
      ov_2 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.2})

      rubric_1 = rubric_fixture(%{scale_id: scale.id})
      rubric_2 = rubric_fixture(%{scale_id: scale.id})

      descriptor_1_1 =
        rubric_descriptor_fixture(%{
          rubric_id: rubric_1.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_1.id
        })

      descriptor_1_2 =
        rubric_descriptor_fixture(%{
          rubric_id: rubric_1.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_2.id
        })

      descriptor_2_1 =
        rubric_descriptor_fixture(%{
          rubric_id: rubric_2.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_1.id
        })

      descriptor_2_2 =
        rubric_descriptor_fixture(%{
          rubric_id: rubric_2.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_2.id
        })

      expected = Rubrics.build_rubrics_descriptors_map([rubric_1.id, rubric_2.id])

      [expected_descriptor_1_1, expected_descriptor_1_2] = expected[rubric_1.id]
      assert expected_descriptor_1_1.id == descriptor_1_1.id
      assert expected_descriptor_1_1.ordinal_value.id == ov_1.id
      assert expected_descriptor_1_2.id == descriptor_1_2.id
      assert expected_descriptor_1_2.ordinal_value.id == ov_2.id

      [expected_descriptor_2_1, expected_descriptor_2_2] = expected[rubric_2.id]
      assert expected_descriptor_2_1.id == descriptor_2_1.id
      assert expected_descriptor_2_1.ordinal_value.id == ov_1.id
      assert expected_descriptor_2_2.id == descriptor_2_2.id
      assert expected_descriptor_2_2.ordinal_value.id == ov_2.id
    end

    test "get_rubric_descriptor!/1 returns the rubric_descriptor with given id" do
      rubric_descriptor = rubric_descriptor_fixture()
      assert Rubrics.get_rubric_descriptor!(rubric_descriptor.id) == rubric_descriptor
    end

    test "create_rubric_descriptor/1 with valid data creates a rubric_descriptor" do
      scale = GradingFixtures.scale_fixture(%{type: "numeric"})
      rubric = rubric_fixture(%{scale_id: scale.id})

      valid_attrs = %{
        descriptor: "some descriptor",
        rubric_id: rubric.id,
        scale_id: scale.id,
        scale_type: scale.type,
        score: 120.5
      }

      assert {:ok, %RubricDescriptor{} = rubric_descriptor} =
               Rubrics.create_rubric_descriptor(valid_attrs)

      assert rubric_descriptor.descriptor == "some descriptor"
      assert rubric_descriptor.score == 120.5
    end

    test "create_rubric_descriptor/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rubrics.create_rubric_descriptor(@invalid_attrs)
    end

    test "update_rubric_descriptor/2 with valid data updates the rubric_descriptor" do
      rubric_descriptor = rubric_descriptor_fixture()
      update_attrs = %{descriptor: "some updated descriptor"}

      assert {:ok, %RubricDescriptor{} = rubric_descriptor} =
               Rubrics.update_rubric_descriptor(rubric_descriptor, update_attrs)

      assert rubric_descriptor.descriptor == "some updated descriptor"
    end

    test "update_rubric_descriptor/2 with invalid data returns error changeset" do
      rubric_descriptor = rubric_descriptor_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Rubrics.update_rubric_descriptor(rubric_descriptor, @invalid_attrs)

      assert rubric_descriptor == Rubrics.get_rubric_descriptor!(rubric_descriptor.id)
    end

    test "delete_rubric_descriptor/1 deletes the rubric_descriptor" do
      rubric_descriptor = rubric_descriptor_fixture()
      assert {:ok, %RubricDescriptor{}} = Rubrics.delete_rubric_descriptor(rubric_descriptor)

      assert_raise Ecto.NoResultsError, fn ->
        Rubrics.get_rubric_descriptor!(rubric_descriptor.id)
      end
    end

    test "change_rubric_descriptor/1 returns a rubric_descriptor changeset" do
      rubric_descriptor = rubric_descriptor_fixture()
      assert %Ecto.Changeset{} = Rubrics.change_rubric_descriptor(rubric_descriptor)
    end
  end

  describe "rubric assessment points" do
    alias Lanttern.AssessmentsFixtures
    alias Lanttern.CurriculaFixtures
    alias Lanttern.GradingFixtures
    alias Lanttern.LearningContextFixtures

    alias Lanttern.Assessments

    test "list_rubric_assessment_points_options/1 returns all assessment points eligible to rubric connection" do
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()

      strand = LearningContextFixtures.strand_fixture()
      moment_1 = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})
      moment_2 = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      rubric =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id
        })

      other_rubric =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id
        })

      goal =
        AssessmentsFixtures.assessment_point_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          rubric_id: rubric.id
        })

      moment_1_ap =
        AssessmentsFixtures.assessment_point_fixture(%{
          scale_id: scale.id,
          moment_id: moment_1.id,
          curriculum_item_id: curriculum_item.id,
          rubric_id: other_rubric.id
        })

      moment_2_ap =
        AssessmentsFixtures.assessment_point_fixture(%{
          scale_id: scale.id,
          moment_id: moment_2.id,
          curriculum_item_id: curriculum_item.id
        })

      # other assessment points for filter test

      _goal_with_other_curriculum_item =
        AssessmentsFixtures.assessment_point_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id
        })

      _same_curriculum_different_scale =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_1.id,
          curriculum_item_id: curriculum_item.id
        })

      _same_scale_different_curriculum =
        AssessmentsFixtures.assessment_point_fixture(%{
          moment_id: moment_2.id,
          scale_id: scale.id
        })

      _differentiation_ap =
        AssessmentsFixtures.assessment_point_fixture(%{
          scale_id: scale.id,
          moment_id: moment_2.id,
          curriculum_item_id: curriculum_item.id,
          is_differentiation: true
        })

      [{expected_goal, true}, {expected_moment_1_ap, false}, {expected_moment_2_ap, false}] =
        Rubrics.list_rubric_assessment_points_options(rubric)

      assert expected_goal.id == goal.id

      assert expected_moment_1_ap.id == moment_1_ap.id
      assert expected_moment_1_ap.moment.id == moment_1.id

      assert expected_moment_2_ap.id == moment_2_ap.id
      assert expected_moment_2_ap.moment.id == moment_2.id
    end

    test "create_rubric/1 with link_to_assessment_points_ids params updates the assessment points" do
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()

      strand = LearningContextFixtures.strand_fixture()
      moment_1 = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})
      moment_2 = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      other_rubric =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id
        })

      goal =
        AssessmentsFixtures.assessment_point_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          rubric_id: other_rubric.id
        })

      moment_1_ap =
        AssessmentsFixtures.assessment_point_fixture(%{
          scale_id: scale.id,
          moment_id: moment_1.id,
          curriculum_item_id: curriculum_item.id
        })

      moment_2_ap =
        AssessmentsFixtures.assessment_point_fixture(%{
          scale_id: scale.id,
          moment_id: moment_2.id,
          curriculum_item_id: curriculum_item.id
        })

      valid_attrs = %{
        "criteria" => "some criteria",
        "scale_id" => scale.id,
        "strand_id" => strand.id,
        "curriculum_item_id" => curriculum_item.id,
        "link_to_assessment_points_ids" => [goal.id, moment_1_ap.id]
      }

      assert {:ok, rubric} = Rubrics.create_rubric(valid_attrs)

      goal = Assessments.get_assessment_point!(goal.id)
      assert goal.rubric_id == rubric.id

      moment_1_ap = Assessments.get_assessment_point!(moment_1_ap.id)
      assert moment_1_ap.rubric_id == rubric.id

      moment_2_ap = Assessments.get_assessment_point!(moment_2_ap.id)
      assert is_nil(moment_2_ap.rubric_id)
    end

    test "update_rubric/1 with link_to and unlink_from_assessment_points_ids params updates the assessment points" do
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      curriculum_item = CurriculaFixtures.curriculum_item_fixture()

      strand = LearningContextFixtures.strand_fixture()
      moment_1 = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})
      moment_2 = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      rubric =
        rubric_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id
        })

      goal =
        AssessmentsFixtures.assessment_point_fixture(%{
          scale_id: scale.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id,
          rubric_id: rubric.id
        })

      moment_1_ap =
        AssessmentsFixtures.assessment_point_fixture(%{
          scale_id: scale.id,
          moment_id: moment_1.id,
          curriculum_item_id: curriculum_item.id
        })

      moment_2_ap =
        AssessmentsFixtures.assessment_point_fixture(%{
          scale_id: scale.id,
          moment_id: moment_2.id,
          curriculum_item_id: curriculum_item.id
        })

      valid_attrs = %{
        "link_to_assessment_points_ids" => [moment_1_ap.id],
        "unlink_from_assessment_points_ids" => [goal.id]
      }

      assert {:ok, rubric} = Rubrics.update_rubric(rubric, valid_attrs)

      goal = Assessments.get_assessment_point!(goal.id)
      assert is_nil(goal.rubric_id)

      moment_1_ap = Assessments.get_assessment_point!(moment_1_ap.id)
      assert moment_1_ap.rubric_id == rubric.id

      moment_2_ap = Assessments.get_assessment_point!(moment_2_ap.id)
      assert is_nil(moment_2_ap.rubric_id)
    end
  end
end
