defmodule Lanttern.DatavizTest do
  use Lanttern.DataCase

  alias Lanttern.Dataviz

  describe "lanttern viz" do
    alias Lanttern.AssessmentsFixtures
    alias Lanttern.CurriculaFixtures
    alias Lanttern.LearningContextFixtures

    test "get_strand_lanttern_viz_data/1 returns the map with data needed to build a lanttern viz" do
      strand = LearningContextFixtures.strand_fixture()
      m_1 = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})
      m_2 = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})
      m_3 = LearningContextFixtures.moment_fixture(%{strand_id: strand.id})

      curriculum_component = CurriculaFixtures.curriculum_component_fixture()

      ci_a =
        CurriculaFixtures.curriculum_item_fixture(%{
          curriculum_component_id: curriculum_component.id
        })

      ci_b =
        CurriculaFixtures.curriculum_item_fixture(%{
          curriculum_component_id: curriculum_component.id
        })

      ci_c =
        CurriculaFixtures.curriculum_item_fixture(%{
          curriculum_component_id: curriculum_component.id
        })

      # expected curriculum items
      # strand - a, b, c
      # moment 3 - b, a, c
      # moment 2 - b
      # moment 1 - a, a, b

      _strand_goal_a =
        AssessmentsFixtures.assessment_point_fixture(%{
          curriculum_item_id: ci_a.id,
          strand_id: strand.id
        })

      _strand_goal_b =
        AssessmentsFixtures.assessment_point_fixture(%{
          curriculum_item_id: ci_b.id,
          strand_id: strand.id
        })

      _strand_goal_c =
        AssessmentsFixtures.assessment_point_fixture(%{
          curriculum_item_id: ci_c.id,
          strand_id: strand.id
        })

      _m_1_ap_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          curriculum_item_id: ci_a.id,
          moment_id: m_1.id
        })

      _m_1_ap_2 =
        AssessmentsFixtures.assessment_point_fixture(%{
          curriculum_item_id: ci_a.id,
          moment_id: m_1.id
        })

      _m_1_ap_3 =
        AssessmentsFixtures.assessment_point_fixture(%{
          curriculum_item_id: ci_b.id,
          moment_id: m_1.id
        })

      _m_2_ap_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          curriculum_item_id: ci_b.id,
          moment_id: m_2.id
        })

      _m_3_ap_1 =
        AssessmentsFixtures.assessment_point_fixture(%{
          curriculum_item_id: ci_b.id,
          moment_id: m_3.id
        })

      _m_3_ap_2 =
        AssessmentsFixtures.assessment_point_fixture(%{
          curriculum_item_id: ci_a.id,
          moment_id: m_3.id
        })

      _m_3_ap_3 =
        AssessmentsFixtures.assessment_point_fixture(%{
          curriculum_item_id: ci_c.id,
          moment_id: m_3.id
        })

      # extra fixtures for testing
      LearningContextFixtures.strand_fixture()
      LearningContextFixtures.moment_fixture()
      CurriculaFixtures.curriculum_item_fixture()
      AssessmentsFixtures.assessment_point_fixture()

      # ids for pattern matching
      ci_a_id = ci_a.id
      ci_b_id = ci_b.id
      ci_c_id = ci_c.id

      assert %{
               moments: [expected_m_3, expected_m_2, expected_m_1],
               strand_goals_curriculum_items: [expected_ci_a, expected_ci_b, expected_ci_c],
               strand_goals_curriculum_items_ids: [^ci_a_id, ^ci_b_id, ^ci_c_id],
               moments_assessments_curriculum_items_ids: [
                 [^ci_c_id, ^ci_a_id, ^ci_b_id],
                 [^ci_b_id],
                 [^ci_b_id, ^ci_a_id, ^ci_a_id]
               ]
             } = Dataviz.get_strand_lanttern_viz_data(strand.id)

      assert expected_m_3.id == m_3.id
      assert expected_m_2.id == m_2.id
      assert expected_m_1.id == m_1.id
      assert expected_ci_a.id == ci_a.id
      assert expected_ci_a.curriculum_component.id == curriculum_component.id
      assert expected_ci_b.id == ci_b.id
      assert expected_ci_b.curriculum_component.id == curriculum_component.id
      assert expected_ci_c.id == ci_c.id
      assert expected_ci_c.curriculum_component.id == curriculum_component.id
    end
  end
end
