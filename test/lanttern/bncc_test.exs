defmodule Lanttern.BNCCTest do
  use Lanttern.DataCase

  describe "BNCC" do
    import Lanttern.CurriculaFixtures
    import Lanttern.TaxonomyFixtures

    alias Lanttern.BNCC

    setup do
      sub_lp = subject_fixture(%{code: "port"})
      sub_li = subject_fixture(%{code: "engl"})
      sub_ci = subject_fixture(%{code: "scie"})

      year_ef1 = year_fixture(%{code: "g1"})
      year_ef3 = year_fixture(%{code: "g3"})
      year_ef6 = year_fixture(%{code: "g6"})

      bncc = curriculum_fixture(%{code: "bncc"})

      comp_ca = curriculum_component_fixture(%{curriculum_id: bncc.id, code: "bncc_ca"})
      comp_pl = curriculum_component_fixture(%{curriculum_id: bncc.id, code: "bncc_pl"})
      comp_ei = curriculum_component_fixture(%{curriculum_id: bncc.id, code: "bncc_ei"})
      comp_ut = curriculum_component_fixture(%{curriculum_id: bncc.id, code: "bncc_ut"})
      comp_oc = curriculum_component_fixture(%{curriculum_id: bncc.id, code: "bncc_oc"})
      comp_ha = curriculum_component_fixture(%{curriculum_id: bncc.id, code: "bncc_ha"})

      ca =
        curriculum_item_fixture(%{subjects_ids: [sub_lp.id], curriculum_component_id: comp_ca.id})

      pl =
        curriculum_item_fixture(%{subjects_ids: [sub_lp.id], curriculum_component_id: comp_pl.id})

      ei =
        curriculum_item_fixture(%{subjects_ids: [sub_li.id], curriculum_component_id: comp_ei.id})

      ut_li =
        curriculum_item_fixture(%{subjects_ids: [sub_ci.id], curriculum_component_id: comp_ut.id})

      ut_ci =
        curriculum_item_fixture(%{subjects_ids: [sub_ci.id], curriculum_component_id: comp_ut.id})

      oc_lp =
        curriculum_item_fixture(%{subjects_ids: [sub_lp.id], curriculum_component_id: comp_oc.id})

      oc_li =
        curriculum_item_fixture(%{subjects_ids: [sub_li.id], curriculum_component_id: comp_oc.id})

      oc_ci =
        curriculum_item_fixture(%{subjects_ids: [sub_ci.id], curriculum_component_id: comp_oc.id})

      ha_lp_1 =
        curriculum_item_fixture(%{
          subjects_ids: [sub_lp.id],
          years_ids: [year_ef1.id],
          curriculum_component_id: comp_ha.id
        })

      ha_lp_3 =
        curriculum_item_fixture(%{
          subjects_ids: [sub_lp.id],
          years_ids: [year_ef3.id],
          curriculum_component_id: comp_ha.id
        })

      ha_li =
        curriculum_item_fixture(%{
          subjects_ids: [sub_li.id],
          years_ids: [year_ef6.id],
          curriculum_component_id: comp_ha.id
        })

      ha_ci =
        curriculum_item_fixture(%{
          subjects_ids: [sub_ci.id],
          years_ids: [year_ef3.id],
          curriculum_component_id: comp_ha.id
        })

      # extra fixtures for "filtering" test
      curriculum_item_fixture()
      curriculum_item_fixture()
      curriculum_item_fixture()

      # build structure

      # LP - ca > pl > oc > ha
      curriculum_relationship_fixture(%{
        curriculum_item_a_id: ca.id,
        curriculum_item_b_id: ha_lp_1.id,
        type: "hierarchical"
      })

      curriculum_relationship_fixture(%{
        curriculum_item_a_id: pl.id,
        curriculum_item_b_id: ha_lp_1.id,
        type: "hierarchical"
      })

      curriculum_relationship_fixture(%{
        curriculum_item_a_id: oc_lp.id,
        curriculum_item_b_id: ha_lp_1.id,
        type: "hierarchical"
      })

      curriculum_relationship_fixture(%{
        curriculum_item_a_id: ca.id,
        curriculum_item_b_id: ha_lp_3.id,
        type: "hierarchical"
      })

      curriculum_relationship_fixture(%{
        curriculum_item_a_id: pl.id,
        curriculum_item_b_id: ha_lp_3.id,
        type: "hierarchical"
      })

      curriculum_relationship_fixture(%{
        curriculum_item_a_id: oc_lp.id,
        curriculum_item_b_id: ha_lp_3.id,
        type: "hierarchical"
      })

      # LI - ei > ut > oc > ha
      curriculum_relationship_fixture(%{
        curriculum_item_a_id: ei.id,
        curriculum_item_b_id: ha_li.id,
        type: "hierarchical"
      })

      curriculum_relationship_fixture(%{
        curriculum_item_a_id: ut_li.id,
        curriculum_item_b_id: ha_li.id,
        type: "hierarchical"
      })

      curriculum_relationship_fixture(%{
        curriculum_item_a_id: oc_li.id,
        curriculum_item_b_id: ha_li.id,
        type: "hierarchical"
      })

      # CI - ut > oc > ha
      curriculum_relationship_fixture(%{
        curriculum_item_a_id: ut_ci.id,
        curriculum_item_b_id: ha_ci.id,
        type: "hierarchical"
      })

      curriculum_relationship_fixture(%{
        curriculum_item_a_id: oc_ci.id,
        curriculum_item_b_id: ha_ci.id,
        type: "hierarchical"
      })

      %{
        sub_lp: sub_lp,
        sub_li: sub_li,
        sub_ci: sub_ci,
        year_ef1: year_ef1,
        year_ef3: year_ef3,
        year_ef6: year_ef6,
        ca: ca,
        pl: pl,
        ei: ei,
        ut_li: ut_li,
        ut_ci: ut_ci,
        oc_lp: oc_lp,
        oc_li: oc_li,
        oc_ci: oc_ci,
        ha_lp_1: ha_lp_1,
        ha_lp_3: ha_lp_3,
        ha_li: ha_li,
        ha_ci: ha_ci
      }
    end

    test "list_bncc_ef_items/1 returns all EF BNCC curriculum items", %{
      ca: ca,
      pl: pl,
      ei: ei,
      ut_li: ut_li,
      ut_ci: ut_ci,
      oc_lp: oc_lp,
      oc_li: oc_li,
      oc_ci: oc_ci,
      ha_lp_1: ha_lp_1,
      ha_lp_3: ha_lp_3,
      ha_li: ha_li,
      ha_ci: ha_ci
    } do
      # expected
      expected = BNCC.list_bncc_ef_items()
      assert length(expected) == 4

      expected_ha_lp_1 = Enum.find(expected, fn ha -> ha.id == ha_lp_1.id end)
      assert expected_ha_lp_1.id == ha_lp_1.id
      assert expected_ha_lp_1.campo_de_atuacao.id == ca.id
      assert expected_ha_lp_1.pratica_de_linguagem.id == pl.id
      assert expected_ha_lp_1.objeto_de_conhecimento.id == oc_lp.id

      expected_ha_lp_3 = Enum.find(expected, fn ha -> ha.id == ha_lp_3.id end)
      assert expected_ha_lp_3.id == ha_lp_3.id
      assert expected_ha_lp_3.campo_de_atuacao.id == ca.id
      assert expected_ha_lp_3.pratica_de_linguagem.id == pl.id
      assert expected_ha_lp_3.objeto_de_conhecimento.id == oc_lp.id

      expected_ha_li = Enum.find(expected, fn ha -> ha.id == ha_li.id end)
      assert expected_ha_li.id == ha_li.id
      assert expected_ha_li.eixo.id == ei.id
      assert expected_ha_li.unidade_tematica.id == ut_li.id
      assert expected_ha_li.objeto_de_conhecimento.id == oc_li.id

      expected_ha_ci = Enum.find(expected, fn ha -> ha.id == ha_ci.id end)
      assert expected_ha_ci.id == ha_ci.id
      assert expected_ha_ci.unidade_tematica.id == ut_ci.id
      assert expected_ha_ci.objeto_de_conhecimento.id == oc_ci.id
    end

    test "list_bncc_ef_items/1 with filters returns EF BNCC curriculum items that match filter criteria",
         %{
           sub_lp: sub_lp,
           year_ef1: year_ef1,
           ha_lp_1: ha_lp_1
         } do
      # expected
      [expected] =
        BNCC.list_bncc_ef_items(filters: [subjects_ids: [sub_lp.id], years_ids: [year_ef1.id]])

      assert expected.id == ha_lp_1.id
    end
  end
end
