defmodule Lanttern.BNCCTest do
  use Lanttern.DataCase

  alias Lanttern.BNCC

  describe "BNCC" do
    import Lanttern.CurriculaFixtures
    import Lanttern.TaxonomyFixtures

    test "list_bncc_ef_items/0 returns all EF BNCC curriculum items" do
      sub_ar = subject_fixture()
      sub_ma = subject_fixture()
      sub_ci = subject_fixture()

      year_ef1 = year_fixture()
      year_ef3 = year_fixture()
      year_ef5 = year_fixture()

      bncc = curriculum_fixture(%{code: "bncc"})

      comp_ut = curriculum_component_fixture(%{curriculum_id: bncc.id, code: "bncc_ut"})
      comp_oc = curriculum_component_fixture(%{curriculum_id: bncc.id, code: "bncc_oc"})
      comp_ha = curriculum_component_fixture(%{curriculum_id: bncc.id, code: "bncc_ha"})

      ut_1 =
        curriculum_item_fixture(%{subjects_ids: [sub_ar.id], curriculum_component_id: comp_ut.id})

      ut_2 =
        curriculum_item_fixture(%{subjects_ids: [sub_ma.id], curriculum_component_id: comp_ut.id})

      ut_3 =
        curriculum_item_fixture(%{subjects_ids: [sub_ci.id], curriculum_component_id: comp_ut.id})

      oc_1 =
        curriculum_item_fixture(%{subjects_ids: [sub_ar.id], curriculum_component_id: comp_oc.id})

      oc_2 =
        curriculum_item_fixture(%{subjects_ids: [sub_ma.id], curriculum_component_id: comp_oc.id})

      oc_3 =
        curriculum_item_fixture(%{subjects_ids: [sub_ci.id], curriculum_component_id: comp_oc.id})

      ha_1 =
        curriculum_item_fixture(%{
          subjects_ids: [sub_ar.id],
          years_ids: [year_ef1.id],
          curriculum_component_id: comp_ha.id
        })

      ha_2 =
        curriculum_item_fixture(%{
          subjects_ids: [sub_ma.id],
          years_ids: [year_ef3.id],
          curriculum_component_id: comp_ha.id
        })

      ha_3 =
        curriculum_item_fixture(%{
          subjects_ids: [sub_ci.id],
          years_ids: [year_ef5.id],
          curriculum_component_id: comp_ha.id
        })

      # extra fixtures for "filtering" test
      curriculum_item_fixture()
      curriculum_item_fixture()
      curriculum_item_fixture()

      # build structure
      curriculum_relationship_fixture(%{
        curriculum_item_a_id: ut_1.id,
        curriculum_item_b_id: ha_1.id,
        type: "hierarchical"
      })

      curriculum_relationship_fixture(%{
        curriculum_item_a_id: oc_1.id,
        curriculum_item_b_id: ha_1.id,
        type: "hierarchical"
      })

      curriculum_relationship_fixture(%{
        curriculum_item_a_id: ut_2.id,
        curriculum_item_b_id: ha_2.id,
        type: "hierarchical"
      })

      curriculum_relationship_fixture(%{
        curriculum_item_a_id: oc_2.id,
        curriculum_item_b_id: ha_2.id,
        type: "hierarchical"
      })

      curriculum_relationship_fixture(%{
        curriculum_item_a_id: ut_3.id,
        curriculum_item_b_id: ha_3.id,
        type: "hierarchical"
      })

      curriculum_relationship_fixture(%{
        curriculum_item_a_id: oc_3.id,
        curriculum_item_b_id: ha_3.id,
        type: "hierarchical"
      })

      # expected
      expected = BNCC.list_bncc_ef_items()
      assert length(expected) == 3

      expected_ha_1 = Enum.find(expected, fn ha -> ha.id == ha_1.id end)
      assert expected_ha_1.id == ha_1.id
      assert expected_ha_1.unidade_tematica.id == ut_1.id
      assert expected_ha_1.objeto_de_conhecimento.id == oc_1.id

      expected_ha_2 = Enum.find(expected, fn ha -> ha.id == ha_2.id end)
      assert expected_ha_2.id == ha_2.id
      assert expected_ha_2.unidade_tematica.id == ut_2.id
      assert expected_ha_2.objeto_de_conhecimento.id == oc_2.id

      expected_ha_3 = Enum.find(expected, fn ha -> ha.id == ha_3.id end)
      assert expected_ha_3.id == ha_3.id
      assert expected_ha_3.unidade_tematica.id == ut_3.id
      assert expected_ha_3.objeto_de_conhecimento.id == oc_3.id
    end
  end
end
