defmodule Lanttern.RubricsTest do
  alias Lanttern.Rubrics.AssessmentPointRubric
  use Lanttern.DataCase

  alias Lanttern.Repo

  alias Lanttern.Rubrics
  alias Lanttern.GradingFixtures
  import Lanttern.RubricsFixtures

  describe "rubrics" do
    alias Lanttern.Rubrics.Rubric
    import Lanttern.AssessmentsFixtures
    import Lanttern.SchoolsFixtures

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

    test "list_full_rubrics/1 returns all rubrics with descriptors preloaded and ordered correctly" do
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

      [expected] = Rubrics.list_full_rubrics()
      assert expected.id == rubric.id

      [expected_descriptor_1, expected_descriptor_2] = expected.descriptors
      assert expected_descriptor_1.id == descriptor_1.id
      assert expected_descriptor_2.id == descriptor_2.id
    end

    test "list_full_rubrics/1 with assessment_points_ids opts returns all filtered rubrics with descriptors preloaded and ordered correctly" do
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

      assessment_point = assessment_point_fixture(%{scale_id: scale.id})

      assessment_point_rubric_fixture(%{
        assessment_point_id: assessment_point.id,
        rubric_id: rubric.id,
        scale_id: scale.id
      })

      # extra fixtures for filter test
      rubric_fixture(%{scale_id: scale.id})
      assessment_point_rubric_fixture(%{rubric_id: rubric.id, scale_id: scale.id})

      [expected] = Rubrics.list_full_rubrics(assessment_points_ids: [assessment_point.id])
      assert expected.id == rubric.id

      [expected_descriptor_1, expected_descriptor_2] = expected.descriptors
      assert expected_descriptor_1.id == descriptor_1.id
      assert expected_descriptor_2.id == descriptor_2.id
    end

    test "list_full_rubrics/1 with students_ids and parent_rubrics_ids opts returns all filtered rubrics with descriptors preloaded and ordered correctly" do
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ov_1 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.1})
      ov_2 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.2})

      parent_rubric = rubric_fixture(%{scale_id: scale.id})
      rubric = rubric_fixture(%{scale_id: scale.id, diff_for_rubric_id: parent_rubric.id})

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

      student = student_fixture()
      Rubrics.link_rubric_to_student(rubric, student.id)

      # extra fixtures for filter test
      rubric_fixture(%{scale_id: scale.id})
      other_student = student_fixture()
      Rubrics.link_rubric_to_student(rubric, other_student.id)
      other_parent_rubric = rubric_fixture(%{scale_id: scale.id})

      other_rubric =
        rubric_fixture(%{scale_id: scale.id, diff_for_rubric_id: other_parent_rubric.id})

      Rubrics.link_rubric_to_student(other_rubric, student.id)

      [expected] =
        Rubrics.list_full_rubrics(
          students_ids: [student.id],
          parent_rubrics_ids: [parent_rubric.id]
        )

      assert expected.id == rubric.id

      [expected_descriptor_1, expected_descriptor_2] = expected.descriptors
      assert expected_descriptor_1.id == descriptor_1.id
      assert expected_descriptor_2.id == descriptor_2.id
    end

    test "list_strand_assessment_points_rubrics/1 returns all strand rubrics with descriptors preloaded and ordered correctly" do
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ov_1 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.1})
      ov_2 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.2})

      rubric_1 = rubric_fixture(%{scale_id: scale.id})
      rubric_2 = rubric_fixture(%{scale_id: scale.id})

      # register rubric 2 before 1 to validate ordering
      descriptor_1_2 =
        rubric_descriptor_fixture(%{
          rubric_id: rubric_1.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_2.id
        })

      descriptor_1_1 =
        rubric_descriptor_fixture(%{
          rubric_id: rubric_1.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_1.id
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

      strand = Lanttern.LearningContextFixtures.strand_fixture()
      curriculum_component = Lanttern.CurriculaFixtures.curriculum_component_fixture()

      curriculum_item_1 =
        Lanttern.CurriculaFixtures.curriculum_item_fixture(%{
          curriculum_component_id: curriculum_component.id
        })

      curriculum_item_2 =
        Lanttern.CurriculaFixtures.curriculum_item_fixture(%{
          curriculum_component_id: curriculum_component.id
        })

      curriculum_item_3 =
        Lanttern.CurriculaFixtures.curriculum_item_fixture(%{
          curriculum_component_id: curriculum_component.id
        })

      assessment_point_1 =
        assessment_point_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: curriculum_item_1.id,
          scale_id: scale.id
        })

      assessment_point_2 =
        assessment_point_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: curriculum_item_2.id,
          scale_id: scale.id
        })

      assessment_point_3 =
        assessment_point_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: curriculum_item_3.id,
          scale_id: scale.id
        })

      assessment_point_1_rubric_1 =
        assessment_point_rubric_fixture(%{
          rubric_id: rubric_1.id,
          assessment_point_id: assessment_point_1.id,
          scale_id: scale.id
        })

      assessment_point_2_rubric_2 =
        assessment_point_rubric_fixture(%{
          rubric_id: rubric_2.id,
          assessment_point_id: assessment_point_2.id,
          scale_id: scale.id
        })

      # extra fixtures for filter test
      other_strand = Lanttern.LearningContextFixtures.strand_fixture()
      other_rubric = rubric_fixture(%{scale_id: scale.id})

      other_assessment_point =
        assessment_point_fixture(%{
          rubric_id: other_rubric.id,
          strand_id: other_strand.id,
          scale_id: scale.id
        })

      assessment_point_rubric_fixture(%{
        rubric_id: other_rubric.id,
        assessment_point_id: other_assessment_point.id,
        scale_id: scale.id
      })

      assessment_point_rubric_fixture(%{
        rubric_id: rubric_1.id,
        assessment_point_id: other_assessment_point.id,
        scale_id: scale.id
      })

      rubric_fixture(%{scale_id: scale.id})

      diff_rubric = rubric_fixture(%{scale_id: scale.id})

      _assessment_point_2_diff_rubric =
        assessment_point_rubric_fixture(%{
          rubric_id: diff_rubric.id,
          assessment_point_id: assessment_point_2.id,
          scale_id: scale.id,
          is_diff: true
        })

      _diff_assessment_point =
        assessment_point_fixture(%{
          strand_id: strand.id,
          is_differentiation: true
        })

      [
        {expected_ap_1, [expected_apr_1]},
        {expected_ap_2, [expected_apr_2]},
        {expected_ap_3, []}
      ] =
        Rubrics.list_strand_assessment_points_rubrics(strand.id)

      assert expected_ap_1.id == assessment_point_1.id
      assert expected_apr_1.id == assessment_point_1_rubric_1.id
      assert expected_apr_1.rubric.id == rubric_1.id

      [expected_descriptor_1_1, expected_descriptor_1_2] = expected_apr_1.rubric.descriptors
      assert expected_descriptor_1_1.id == descriptor_1_1.id
      assert expected_descriptor_1_2.id == descriptor_1_2.id
      assert expected_ap_1.curriculum_item.id == curriculum_item_1.id
      assert expected_ap_1.curriculum_item.curriculum_component.id == curriculum_component.id

      assert expected_ap_2.id == assessment_point_2.id
      assert expected_apr_2.id == assessment_point_2_rubric_2.id
      assert expected_apr_2.rubric.id == rubric_2.id

      [expected_descriptor_2_1, expected_descriptor_2_2] = expected_apr_2.rubric.descriptors
      assert expected_descriptor_2_1.id == descriptor_2_1.id
      assert expected_descriptor_2_2.id == descriptor_2_2.id
      assert expected_ap_2.curriculum_item.id == curriculum_item_2.id
      assert expected_ap_2.curriculum_item.curriculum_component.id == curriculum_component.id

      assert expected_ap_3.id == assessment_point_3.id
    end

    test "list_strand_diff_assessment_points_rubrics/2 returns all strand differentiation rubrics with descriptors preloaded and ordered correctly" do
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ov_1 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.1})
      ov_2 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.2})

      rubric_1 = rubric_fixture(%{scale_id: scale.id})
      rubric_2 = rubric_fixture(%{scale_id: scale.id})

      # register rubric 2 before 1 to validate ordering
      descriptor_1_2 =
        rubric_descriptor_fixture(%{
          rubric_id: rubric_1.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_2.id
        })

      descriptor_1_1 =
        rubric_descriptor_fixture(%{
          rubric_id: rubric_1.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_1.id
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

      strand = Lanttern.LearningContextFixtures.strand_fixture()
      curriculum_component = Lanttern.CurriculaFixtures.curriculum_component_fixture()

      curriculum_item_1 =
        Lanttern.CurriculaFixtures.curriculum_item_fixture(%{
          curriculum_component_id: curriculum_component.id
        })

      curriculum_item_2 =
        Lanttern.CurriculaFixtures.curriculum_item_fixture(%{
          curriculum_component_id: curriculum_component.id
        })

      curriculum_item_3 =
        Lanttern.CurriculaFixtures.curriculum_item_fixture(%{
          curriculum_component_id: curriculum_component.id
        })

      assessment_point_1 =
        assessment_point_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: curriculum_item_1.id,
          scale_id: scale.id
        })

      assessment_point_2 =
        assessment_point_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: curriculum_item_2.id,
          scale_id: scale.id,
          is_differentiation: true
        })

      assessment_point_3 =
        assessment_point_fixture(%{
          strand_id: strand.id,
          curriculum_item_id: curriculum_item_3.id,
          scale_id: scale.id
        })

      assessment_point_1_diff_rubric_1 =
        assessment_point_rubric_fixture(%{
          rubric_id: rubric_1.id,
          assessment_point_id: assessment_point_1.id,
          scale_id: scale.id,
          is_diff: true
        })

      assessment_point_2_diff_rubric_2 =
        assessment_point_rubric_fixture(%{
          rubric_id: rubric_2.id,
          assessment_point_id: assessment_point_2.id,
          scale_id: scale.id,
          is_diff: true
        })

      class = Lanttern.SchoolsFixtures.class_fixture()
      student = Lanttern.SchoolsFixtures.student_fixture(%{classes_ids: [class.id]})

      _assessment_point_1_diff_rubric_1_assessment_entry =
        Lanttern.AssessmentsFixtures.rubric_assessment_entry_fixture(%{
          student_id: student.id,
          assessment_point_rubric_id: assessment_point_1_diff_rubric_1.id
        })

      # extra fixtures for filter test
      other_strand = Lanttern.LearningContextFixtures.strand_fixture()
      other_rubric = rubric_fixture(%{scale_id: scale.id})

      _not_diff_rubric =
        assessment_point_rubric_fixture(%{
          rubric_id: rubric_1.id,
          assessment_point_id: assessment_point_1.id,
          scale_id: scale.id
        })

      other_assessment_point =
        assessment_point_fixture(%{
          rubric_id: other_rubric.id,
          strand_id: other_strand.id,
          scale_id: scale.id
        })

      assessment_point_rubric_fixture(%{
        rubric_id: other_rubric.id,
        assessment_point_id: other_assessment_point.id,
        scale_id: scale.id
      })

      assessment_point_rubric_fixture(%{
        rubric_id: rubric_1.id,
        assessment_point_id: other_assessment_point.id,
        scale_id: scale.id
      })

      rubric_fixture(%{scale_id: scale.id})
      other_class_student = Lanttern.SchoolsFixtures.student_fixture()

      Lanttern.AssessmentsFixtures.rubric_assessment_entry_fixture(%{
        student_id: other_class_student.id,
        assessment_point_rubric_id: assessment_point_1_diff_rubric_1.id
      })

      [{expected_ap_1, [expected_apr_1]}, {expected_ap_2, [expected_apr_2]}, {expected_ap_3, []}] =
        Rubrics.list_strand_diff_assessment_points_rubrics(strand.id, classes_ids: [class.id])

      assert expected_ap_1.id == assessment_point_1.id
      assert expected_apr_1.id == assessment_point_1_diff_rubric_1.id
      assert expected_apr_1.rubric.id == rubric_1.id

      [expected_descriptor_1_1, expected_descriptor_1_2] = expected_apr_1.rubric.descriptors
      assert expected_descriptor_1_1.id == descriptor_1_1.id
      assert expected_descriptor_1_2.id == descriptor_1_2.id
      assert expected_ap_1.curriculum_item.id == curriculum_item_1.id
      assert expected_ap_1.curriculum_item.curriculum_component.id == curriculum_component.id
      refute expected_ap_1.is_differentiation

      [expected_student] = expected_apr_1.students
      assert expected_student.id == student.id

      assert expected_ap_2.id == assessment_point_2.id
      assert expected_apr_2.id == assessment_point_2_diff_rubric_2.id
      assert expected_apr_2.rubric.id == rubric_2.id

      [expected_descriptor_2_1, expected_descriptor_2_2] = expected_apr_2.rubric.descriptors
      assert expected_descriptor_2_1.id == descriptor_2_1.id
      assert expected_descriptor_2_2.id == descriptor_2_2.id
      assert expected_ap_2.curriculum_item.id == curriculum_item_2.id
      assert expected_ap_2.curriculum_item.curriculum_component.id == curriculum_component.id
      assert expected_ap_2.is_differentiation

      assert expected_ap_3.id == assessment_point_3.id
    end

    @tag :skip
    test "list_strand_diff_rubrics_for_student_id/2 returns all strand diff rubrics with descriptors preloaded and ordered correctly" do
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ov_1 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.1})
      ov_2 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.2})

      rubric = rubric_fixture(%{scale_id: scale.id})
      diff_rubric = rubric_fixture(%{scale_id: scale.id, diff_for_rubric_id: rubric.id})

      student = Lanttern.SchoolsFixtures.student_fixture()

      Lanttern.Repo.insert_all(
        "differentiation_rubrics_students",
        [[rubric_id: diff_rubric.id, student_id: student.id]]
      )

      descriptor_1 =
        rubric_descriptor_fixture(%{
          rubric_id: diff_rubric.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_1.id
        })

      descriptor_2 =
        rubric_descriptor_fixture(%{
          rubric_id: diff_rubric.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_2.id
        })

      strand = Lanttern.LearningContextFixtures.strand_fixture()
      curriculum_component = Lanttern.CurriculaFixtures.curriculum_component_fixture()

      curriculum_item =
        Lanttern.CurriculaFixtures.curriculum_item_fixture(%{
          curriculum_component_id: curriculum_component.id
        })

      _assessment_point =
        assessment_point_fixture(%{
          rubric_id: rubric.id,
          strand_id: strand.id,
          curriculum_item_id: curriculum_item.id
        })

      # extra fixtures for filter test
      other_strand = Lanttern.LearningContextFixtures.strand_fixture()
      other_rubric = rubric_fixture(%{scale_id: scale.id})
      assessment_point_fixture(%{rubric_id: other_rubric.id, strand_id: other_strand.id})
      rubric_fixture(%{scale_id: scale.id})

      [expected_diff_rubric] =
        Rubrics.list_strand_diff_rubrics_for_student_id(student.id, strand.id)

      assert expected_diff_rubric.id == diff_rubric.id

      [expected_descriptor_1, expected_descriptor_2] =
        expected_diff_rubric.descriptors

      assert expected_descriptor_1.id == descriptor_1.id
      assert expected_descriptor_2.id == descriptor_2.id
      assert expected_diff_rubric.curriculum_item.id == curriculum_item.id

      assert expected_diff_rubric.curriculum_item.curriculum_component.id ==
               curriculum_component.id
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

    test "get_full_rubric!/1 with diff option returns the diff rubric with descriptors preloaded and ordered correctly" do
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ov_1 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.1})
      ov_2 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.2})

      rubric = rubric_fixture(%{scale_id: scale.id})
      diff_rubric = rubric_fixture(%{scale_id: scale.id, diff_for_rubric_id: rubric.id})

      student = student_fixture()

      Lanttern.Repo.insert_all(
        "differentiation_rubrics_students",
        [[rubric_id: diff_rubric.id, student_id: student.id]]
      )

      descriptor_2 =
        rubric_descriptor_fixture(%{
          rubric_id: diff_rubric.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_2.id
        })

      descriptor_1 =
        rubric_descriptor_fixture(%{
          rubric_id: diff_rubric.id,
          scale_id: scale.id,
          scale_type: scale.type,
          ordinal_value_id: ov_1.id
        })

      expected = Rubrics.get_full_rubric!(rubric.id, check_diff_for_student_id: student.id)
      assert expected.id == diff_rubric.id

      [expected_descriptor_1, expected_descriptor_2] = expected.descriptors
      assert expected_descriptor_1.id == descriptor_1.id
      assert expected_descriptor_2.id == descriptor_2.id
    end

    test "get_full_rubric!/1 with diff option but no diff returns the default rubric with descriptors preloaded and ordered correctly" do
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ov_1 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.1})
      ov_2 = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id, normalized_value: 0.2})

      rubric = rubric_fixture(%{scale_id: scale.id})

      student = student_fixture()

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

      expected = Rubrics.get_full_rubric!(rubric.id, check_diff_for_student_id: student.id)
      assert expected.id == rubric.id

      [expected_descriptor_1, expected_descriptor_2] = expected.descriptors
      assert expected_descriptor_1.id == descriptor_1.id
      assert expected_descriptor_2.id == descriptor_2.id
    end

    test "create_rubric/1 with valid data creates a rubric" do
      valid_attrs = %{
        criteria: "some criteria",
        scale_id: GradingFixtures.scale_fixture().id,
        is_differentiation: true
      }

      assert {:ok, %Rubric{} = rubric} = Rubrics.create_rubric(valid_attrs)
      assert rubric.criteria == "some criteria"
      assert rubric.is_differentiation == true
    end

    test "create_rubric/1 with valid data including descriptors creates a rubric and related descriptors" do
      scale = GradingFixtures.scale_fixture(%{type: "ordinal"})
      ordinal_value = GradingFixtures.ordinal_value_fixture(%{scale_id: scale.id})

      valid_attrs = %{
        criteria: "some criteria with descriptors",
        scale_id: scale.id,
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

      valid_attrs = %{
        criteria: "some criteria",
        scale_id: scale.id,
        is_differentiation: true
      }

      assert {:ok, %Rubric{} = rubric} = Rubrics.create_rubric(valid_attrs, preloads: :scale)
      assert rubric.criteria == "some criteria"
      assert rubric.scale.id == scale.id
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

    test "delete_rubric/2 deletes the rubric" do
      rubric = rubric_fixture()
      assert {:ok, %Rubric{}} = Rubrics.delete_rubric(rubric)
      assert_raise Ecto.NoResultsError, fn -> Rubrics.get_rubric!(rubric.id) end
    end

    test "delete_rubric/2 with linked assessment points and unlink_assessment_points=true deletes the rubric" do
      rubric = rubric_fixture()

      assessment_point_rubric =
        assessment_point_rubric_fixture(%{scale_id: rubric.scale_id, rubric_id: rubric.id})

      assert {:ok, %Rubric{}} = Rubrics.delete_rubric(rubric, unlink_assessment_points: true)
      assert_raise Ecto.NoResultsError, fn -> Rubrics.get_rubric!(rubric.id) end

      assert_raise Ecto.NoResultsError, fn ->
        Repo.get!(AssessmentPointRubric, assessment_point_rubric.id)
      end
    end

    test "change_rubric/1 returns a rubric changeset" do
      rubric = rubric_fixture()
      assert %Ecto.Changeset{} = Rubrics.change_rubric(rubric)
    end
  end

  describe "differentiation rubrics" do
    alias Lanttern.Rubrics.Rubric
    import Lanttern.SchoolsFixtures

    test "link_rubric_to_student/2 links the differentiation rubric to the student" do
      student = student_fixture()
      parent_rubric = rubric_fixture()
      diff_rubric = rubric_fixture(%{diff_for_rubric_id: parent_rubric.id})

      assert Rubrics.link_rubric_to_student(diff_rubric, student.id) == :ok
      expected = Rubrics.get_rubric!(diff_rubric.id, preloads: :students)
      assert expected.students == [student]

      # when linking the rubric to a student twice, it should return :ok
      # (the function handles this duplication internally, avoiding a second insert)
      assert Rubrics.link_rubric_to_student(diff_rubric, student.id) == :ok
      expected = Rubrics.get_rubric!(diff_rubric.id, preloads: :students)
      assert expected.students == [student]

      # only diff rubrics can be linked to students
      assert Rubrics.link_rubric_to_student(parent_rubric, student.id) ==
               {:error, "Only differentiation rubrics can be linked to students"}

      expected = Rubrics.get_rubric!(parent_rubric.id, preloads: :students)
      assert expected.students == []
    end

    test "unlink_rubric_from_student/2 unlinks the rubric from the student" do
      student = student_fixture()
      rubric = rubric_fixture()
      diff_rubric = rubric_fixture(%{diff_for_rubric_id: rubric.id})

      assert Rubrics.link_rubric_to_student(diff_rubric, student.id) == :ok
      expected = Rubrics.get_rubric!(diff_rubric.id, preloads: :students)
      assert expected.students == [student]

      assert Rubrics.unlink_rubric_from_student(diff_rubric, student.id) == :ok
      expected = Rubrics.get_rubric!(diff_rubric.id, preloads: :students)
      assert expected.students == []

      # when trying to unlink rubrics and students that are not linked
      # the function returns ok and nothing changes
      assert Rubrics.unlink_rubric_from_student(rubric, student.id) == :ok
    end

    test "create_diff_rubric_for_student/3 creates a differentiation rubric and links it the student" do
      student = student_fixture()
      parent_rubric = rubric_fixture()
      scale = GradingFixtures.scale_fixture()

      valid_attrs = %{
        criteria: "diff rubric criteria",
        scale_id: scale.id,
        diff_for_rubric_id: parent_rubric.id
      }

      assert {:ok, %Rubric{} = rubric} =
               Rubrics.create_diff_rubric_for_student(student.id, valid_attrs)

      assert rubric.criteria == "diff rubric criteria"
      assert rubric.scale_id == scale.id
      assert rubric.diff_for_rubric_id == parent_rubric.id

      expected = Rubrics.get_rubric!(rubric.id, preloads: :students)
      assert expected.students == [student]
    end
  end

  describe "rubric_descriptors" do
    alias Lanttern.Rubrics.RubricDescriptor

    @invalid_attrs %{descriptor: nil, score: nil}

    test "list_rubric_descriptors/0 returns all rubric_descriptors" do
      rubric_descriptor = rubric_descriptor_fixture()
      assert Rubrics.list_rubric_descriptors() == [rubric_descriptor]
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

  describe "assessment_point_rubrics" do
    alias Lanttern.Rubrics.AssessmentPointRubric
    alias Lanttern.Rubrics.Rubric
    alias Lanttern.AssessmentsFixtures

    @invalid_attrs %{assessment_point_id: nil, rubric_id: nil}

    test "get_assessment_point_rubric!/2 with preloads returns the assessment point rubric with given id and preloaded data" do
      assessment_point_rubric = assessment_point_rubric_fixture()

      expected =
        Rubrics.get_assessment_point_rubric!(assessment_point_rubric.id,
          preloads: :assessment_point
        )

      assert expected.id == assessment_point_rubric.id
      assert expected.assessment_point.id == assessment_point_rubric.assessment_point_id
    end

    test "create_assessment_point_rubric/1 with valid data creates a assessment_point_rubric" do
      assessment_point = AssessmentsFixtures.assessment_point_fixture()
      rubric = rubric_fixture(%{scale_id: assessment_point.scale_id})

      valid_attrs = %{
        assessment_point_id: assessment_point.id,
        rubric_id: rubric.id,
        scale_id: assessment_point.scale_id,
        is_diff: true
      }

      assert {:ok, %AssessmentPointRubric{} = assessment_point_rubric} =
               Rubrics.create_assessment_point_rubric(valid_attrs)

      assert assessment_point_rubric.assessment_point_id == assessment_point.id
      assert assessment_point_rubric.rubric_id == rubric.id
      assert assessment_point_rubric.is_diff
    end

    test "create_assessment_point_rubric/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rubrics.create_assessment_point_rubric(@invalid_attrs)
    end

    test "create_rubric_and_link_to_assessment_point/3 with valid data creates a rubric linked to the given assessment point" do
      assessment_point = AssessmentsFixtures.assessment_point_fixture()

      valid_attrs = %{
        criteria: "some criteria",
        scale_id: assessment_point.scale_id
      }

      assert {:ok, %Rubric{} = rubric} =
               Rubrics.create_rubric_and_link_to_assessment_point(
                 assessment_point.id,
                 valid_attrs,
                 preloads: :scale,
                 is_diff: true
               )

      assert rubric.criteria == "some criteria"
      assert rubric.scale.id == assessment_point.scale_id

      # get updated assessment point rubric
      assessment_point_rubric =
        Repo.get_by(AssessmentPointRubric, assessment_point_id: assessment_point.id)

      assert assessment_point_rubric.rubric_id == rubric.id
      assert assessment_point_rubric.is_diff
    end

    test "update_assessment_point_rubric/2 with valid data updates the assessment_point_rubric" do
      assessment_point_rubric = assessment_point_rubric_fixture()
      update_attrs = %{position: 999}

      assert {:ok, %AssessmentPointRubric{} = assessment_point_rubric} =
               Rubrics.update_assessment_point_rubric(assessment_point_rubric, update_attrs)

      assert assessment_point_rubric.position == 999
    end

    test "update_assessment_point_rubric/2 with invalid data returns error changeset" do
      assessment_point_rubric = assessment_point_rubric_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Rubrics.update_assessment_point_rubric(assessment_point_rubric, @invalid_attrs)

      assert assessment_point_rubric ==
               Repo.get!(AssessmentPointRubric, assessment_point_rubric.id)
    end

    test "delete_assessment_point_rubric/1 deletes the assessment_point_rubric" do
      assessment_point_rubric = assessment_point_rubric_fixture()

      assert {:ok, %AssessmentPointRubric{}} =
               Rubrics.delete_assessment_point_rubric(assessment_point_rubric)

      assert_raise Ecto.NoResultsError, fn ->
        Repo.get!(AssessmentPointRubric, assessment_point_rubric.id)
      end
    end

    test "change_assessment_point_rubric/1 returns a assessment_point_rubric changeset" do
      assessment_point_rubric = assessment_point_rubric_fixture()
      assert %Ecto.Changeset{} = Rubrics.change_assessment_point_rubric(assessment_point_rubric)
    end
  end
end
