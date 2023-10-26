defmodule Lanttern.BNCCTest do
  use Lanttern.DataCase

  describe "BNCC EF" do
    import Lanttern.BNCCFixtures
    import Lanttern.CurriculaFixtures
    import Lanttern.TaxonomyFixtures

    alias Lanttern.BNCC

    setup do
      [sub_lp, sub_ar, sub_ef, sub_li, sub_ma, sub_ci, sub_ge, sub_hi, sub_er] =
        ["port", "arts", "move", "engl", "math", "scie", "geog", "hist", "reli"]
        |> Enum.map(fn code -> subject_fixture(%{code: code}) end)

      [year_ef1, year_ef2, year_ef3, year_ef4, year_ef5, year_ef6, year_ef7, year_ef8, year_ef9] =
        ["g1", "g2", "g3", "g4", "g5", "g6", "g7", "g8", "g9"]
        |> Enum.map(fn code -> year_fixture(%{code: code}) end)

      {ca_lp_1, pl_lp_1, oc_lp_1, ha_lp_1} =
        habilidade_bncc_ef_lp_fixture(%{
          subjects_ids: [sub_lp.id],
          years_ids: [year_ef1.id]
        })

      {ca_lp_3, pl_lp_3, oc_lp_3, ha_lp_3} =
        habilidade_bncc_ef_lp_fixture(%{
          subjects_ids: [sub_lp.id],
          years_ids: [year_ef3.id]
        })

      {ei_li, ut_li, oc_li, ha_li} =
        habilidade_bncc_ef_li_fixture(%{
          subjects_ids: [sub_li.id],
          years_ids: [year_ef6.id]
        })

      {ut_ci, oc_ci, ha_ci} =
        habilidade_bncc_ef_fixture(%{
          subjects_ids: [sub_ci.id],
          years_ids: [year_ef3.id]
        })

      %{
        sub_lp: sub_lp,
        sub_ar: sub_ar,
        sub_ef: sub_ef,
        sub_li: sub_li,
        sub_ma: sub_ma,
        sub_ci: sub_ci,
        sub_ge: sub_ge,
        sub_hi: sub_hi,
        sub_er: sub_er,
        year_ef1: year_ef1,
        year_ef2: year_ef2,
        year_ef3: year_ef3,
        year_ef4: year_ef4,
        year_ef5: year_ef5,
        year_ef6: year_ef6,
        year_ef7: year_ef7,
        year_ef8: year_ef8,
        year_ef9: year_ef9,
        ca_lp_1: ca_lp_1,
        pl_lp_1: pl_lp_1,
        oc_lp_1: oc_lp_1,
        ha_lp_1: ha_lp_1,
        ca_lp_3: ca_lp_3,
        pl_lp_3: pl_lp_3,
        oc_lp_3: oc_lp_3,
        ha_lp_3: ha_lp_3,
        ei_li: ei_li,
        ut_li: ut_li,
        oc_li: oc_li,
        ha_li: ha_li,
        ut_ci: ut_ci,
        oc_ci: oc_ci,
        ha_ci: ha_ci
      }
    end

    test "list_bncc_ef_items/1 returns all EF BNCC curriculum items", %{
      ca_lp_1: ca_lp_1,
      pl_lp_1: pl_lp_1,
      oc_lp_1: oc_lp_1,
      ha_lp_1: ha_lp_1,
      ca_lp_3: ca_lp_3,
      pl_lp_3: pl_lp_3,
      oc_lp_3: oc_lp_3,
      ha_lp_3: ha_lp_3,
      ei_li: ei_li,
      ut_li: ut_li,
      oc_li: oc_li,
      ha_li: ha_li,
      ut_ci: ut_ci,
      oc_ci: oc_ci,
      ha_ci: ha_ci
    } do
      # extra fixtures for "filtering" test
      curriculum_item_fixture()
      curriculum_item_fixture()
      curriculum_item_fixture()

      # expected
      expected = BNCC.list_bncc_ef_items()
      assert length(expected) == 4

      expected_ha_lp_1 = Enum.find(expected, fn ha -> ha.id == ha_lp_1.id end)
      assert expected_ha_lp_1.id == ha_lp_1.id
      assert expected_ha_lp_1.campo_de_atuacao == ca_lp_1.name
      assert expected_ha_lp_1.pratica_de_linguagem == pl_lp_1.name
      assert expected_ha_lp_1.objeto_de_conhecimento == oc_lp_1.name

      expected_ha_lp_3 = Enum.find(expected, fn ha -> ha.id == ha_lp_3.id end)
      assert expected_ha_lp_3.id == ha_lp_3.id
      assert expected_ha_lp_3.campo_de_atuacao == ca_lp_3.name
      assert expected_ha_lp_3.pratica_de_linguagem == pl_lp_3.name
      assert expected_ha_lp_3.objeto_de_conhecimento == oc_lp_3.name

      expected_ha_li = Enum.find(expected, fn ha -> ha.id == ha_li.id end)
      assert expected_ha_li.id == ha_li.id
      assert expected_ha_li.eixo == ei_li.name
      assert expected_ha_li.unidade_tematica == ut_li.name
      assert expected_ha_li.objeto_de_conhecimento == oc_li.name

      expected_ha_ci = Enum.find(expected, fn ha -> ha.id == ha_ci.id end)
      assert expected_ha_ci.id == ha_ci.id
      assert expected_ha_ci.unidade_tematica == ut_ci.name
      assert expected_ha_ci.objeto_de_conhecimento == oc_ci.name
    end

    test "list_bncc_ef_items/1 with filters returns EF BNCC curriculum items that match filter criteria",
         %{
           sub_lp: sub_lp,
           year_ef1: year_ef1,
           ha_lp_1: ha_lp_1
         } do
      # extra fixtures for "filtering" test
      curriculum_item_fixture()
      curriculum_item_fixture()
      curriculum_item_fixture()

      # expected
      [expected] =
        BNCC.list_bncc_ef_items(filters: [subjects_ids: [sub_lp.id], years_ids: [year_ef1.id]])

      assert expected.id == ha_lp_1.id
    end

    test "list_bncc_ef_subjects/0 list all EF BNCC related subjects",
         %{
           sub_lp: sub_lp,
           sub_ar: sub_ar,
           sub_ef: sub_ef,
           sub_li: sub_li,
           sub_ma: sub_ma,
           sub_ci: sub_ci,
           sub_ge: sub_ge,
           sub_hi: sub_hi,
           sub_er: sub_er
         } do
      # extra fixtures for "filtering" test
      subject_fixture()
      subject_fixture()
      subject_fixture()

      expected = BNCC.list_bncc_ef_subjects()

      assert length(expected) == 9

      all_subs = [sub_lp, sub_ar, sub_ef, sub_li, sub_ma, sub_ci, sub_ge, sub_hi, sub_er]
      assert Enum.all?(expected, fn sub -> sub in all_subs end)
    end

    test "list_bncc_ef_years/0 list all EF BNCC related years",
         %{
           year_ef1: year_ef1,
           year_ef2: year_ef2,
           year_ef3: year_ef3,
           year_ef4: year_ef4,
           year_ef5: year_ef5,
           year_ef6: year_ef6,
           year_ef7: year_ef7,
           year_ef8: year_ef8,
           year_ef9: year_ef9
         } do
      # extra fixtures for "filtering" test
      year_fixture()
      year_fixture()
      year_fixture()

      expected = BNCC.list_bncc_ef_years()

      assert length(expected) == 9

      all_years = [
        year_ef1,
        year_ef2,
        year_ef3,
        year_ef4,
        year_ef5,
        year_ef6,
        year_ef7,
        year_ef8,
        year_ef9
      ]

      assert Enum.all?(expected, fn year -> year in all_years end)
    end
  end
end
