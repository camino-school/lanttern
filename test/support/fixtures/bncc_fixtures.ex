defmodule Lanttern.BNCCFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via related contexts (`Lanttern.Curricula`, `Lanttern.Taxonomy`).
  """

  import Lanttern.CurriculaFixtures
  import Lanttern.TaxonomyFixtures

  alias Lanttern.Curricula.Curriculum
  alias Lanttern.Curricula.CurriculumComponent
  alias Lanttern.Repo

  @doc """
  Generate a "Habilidade BNCC EF".
  Uses `Unidade Temática` > `Objeto de Conhecimento` > `Habilidade` structure.
  """
  def habilidade_bncc_ef_fixture(attrs \\ %{}) do
    bncc = get_or_insert_curriculum_by_code(%{code: "bncc"})

    comp_ut = get_or_insert_component_by_code(%{curriculum_id: bncc.id, code: "bncc_ut"})
    comp_oc = get_or_insert_component_by_code(%{curriculum_id: bncc.id, code: "bncc_oc"})
    comp_ha = get_or_insert_component_by_code(%{curriculum_id: bncc.id, code: "bncc_ha"})

    subjects_ids = Map.get(attrs, :subjects_ids, [subject_fixture().id])
    years_ids = Map.get(attrs, :years_ids, [year_fixture().id])

    ut =
      curriculum_item_fixture(%{subjects_ids: subjects_ids, curriculum_component_id: comp_ut.id})

    oc =
      curriculum_item_fixture(%{subjects_ids: subjects_ids, curriculum_component_id: comp_oc.id})

    ha =
      attrs
      |> Enum.into(%{
        subjects_ids: subjects_ids,
        years_ids: years_ids,
        curriculum_component_id: comp_ha.id
      })
      |> curriculum_item_fixture()

    # build structure

    curriculum_relationship_fixture(%{
      curriculum_item_a_id: ut.id,
      curriculum_item_b_id: ha.id,
      type: "hierarchical"
    })

    curriculum_relationship_fixture(%{
      curriculum_item_a_id: oc.id,
      curriculum_item_b_id: ha.id,
      type: "hierarchical"
    })

    {ut, oc, ha}
  end

  @doc """
  Generate a "Habilidade BNCC EF LP".
  Uses `Campo de Atuação` > `Prática de Linguagem` > `Objeto de Conhecimento` > `Habilidade` structure.
  """
  def habilidade_bncc_ef_lp_fixture(attrs \\ %{}) do
    bncc = get_or_insert_curriculum_by_code(%{code: "bncc"})

    comp_ca = get_or_insert_component_by_code(%{curriculum_id: bncc.id, code: "bncc_ca"})
    comp_pl = get_or_insert_component_by_code(%{curriculum_id: bncc.id, code: "bncc_pl"})
    comp_oc = get_or_insert_component_by_code(%{curriculum_id: bncc.id, code: "bncc_oc"})
    comp_ha = get_or_insert_component_by_code(%{curriculum_id: bncc.id, code: "bncc_ha"})

    subjects_ids = Map.get(attrs, :subjects_ids, [subject_fixture().id])
    years_ids = Map.get(attrs, :years_ids, [year_fixture().id])

    ca =
      curriculum_item_fixture(%{subjects_ids: subjects_ids, curriculum_component_id: comp_ca.id})

    pl =
      curriculum_item_fixture(%{subjects_ids: subjects_ids, curriculum_component_id: comp_pl.id})

    oc =
      curriculum_item_fixture(%{subjects_ids: subjects_ids, curriculum_component_id: comp_oc.id})

    ha =
      attrs
      |> Enum.into(%{
        subjects_ids: subjects_ids,
        years_ids: years_ids,
        curriculum_component_id: comp_ha.id
      })
      |> curriculum_item_fixture()

    # build structure

    curriculum_relationship_fixture(%{
      curriculum_item_a_id: ca.id,
      curriculum_item_b_id: ha.id,
      type: "hierarchical"
    })

    curriculum_relationship_fixture(%{
      curriculum_item_a_id: pl.id,
      curriculum_item_b_id: ha.id,
      type: "hierarchical"
    })

    curriculum_relationship_fixture(%{
      curriculum_item_a_id: oc.id,
      curriculum_item_b_id: ha.id,
      type: "hierarchical"
    })

    {ca, pl, oc, ha}
  end

  @doc """
  Generate a "Habilidade BNCC EF LI".
  Uses `Eixo` > `Unidade Temática` > `Objeto de Conhecimento` > `Habilidade` structure.
  """
  def habilidade_bncc_ef_li_fixture(attrs \\ %{}) do
    bncc = get_or_insert_curriculum_by_code(%{code: "bncc"})

    comp_ei = get_or_insert_component_by_code(%{curriculum_id: bncc.id, code: "bncc_ei"})
    comp_ut = get_or_insert_component_by_code(%{curriculum_id: bncc.id, code: "bncc_ut"})
    comp_oc = get_or_insert_component_by_code(%{curriculum_id: bncc.id, code: "bncc_oc"})
    comp_ha = get_or_insert_component_by_code(%{curriculum_id: bncc.id, code: "bncc_ha"})

    subjects_ids = Map.get(attrs, :subjects_ids, [subject_fixture().id])
    years_ids = Map.get(attrs, :years_ids, [year_fixture().id])

    ei =
      curriculum_item_fixture(%{subjects_ids: subjects_ids, curriculum_component_id: comp_ei.id})

    ut =
      curriculum_item_fixture(%{subjects_ids: subjects_ids, curriculum_component_id: comp_ut.id})

    oc =
      curriculum_item_fixture(%{subjects_ids: subjects_ids, curriculum_component_id: comp_oc.id})

    ha =
      attrs
      |> Enum.into(%{
        subjects_ids: subjects_ids,
        years_ids: years_ids,
        curriculum_component_id: comp_ha.id
      })
      |> curriculum_item_fixture()

    # build structure

    curriculum_relationship_fixture(%{
      curriculum_item_a_id: ei.id,
      curriculum_item_b_id: ha.id,
      type: "hierarchical"
    })

    curriculum_relationship_fixture(%{
      curriculum_item_a_id: ut.id,
      curriculum_item_b_id: ha.id,
      type: "hierarchical"
    })

    curriculum_relationship_fixture(%{
      curriculum_item_a_id: oc.id,
      curriculum_item_b_id: ha.id,
      type: "hierarchical"
    })

    {ei, ut, oc, ha}
  end

  defp get_or_insert_curriculum_by_code(%{code: code} = params) do
    case Repo.get_by(Curriculum, code: code) do
      nil -> curriculum_fixture(params)
      curriculum -> curriculum
    end
  end

  defp get_or_insert_component_by_code(%{code: code} = params) do
    case Repo.get_by(CurriculumComponent, code: code) do
      nil -> curriculum_component_fixture(params)
      curriculum_component -> curriculum_component
    end
  end
end
