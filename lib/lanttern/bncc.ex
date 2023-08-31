defmodule Lanttern.BNCC do
  @moduledoc """
  The BNCC context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.BNCC.HabilidadeBNCCEF
  alias Lanttern.Curricula.CurriculumItem
  alias Lanttern.Curricula.CurriculumRelationship

  # BNCC related taxonomy]
  @ef_subjects_codes ["port", "arts", "move", "engl", "math", "scie", "geog", "hist", "reli"]
  @ef_years_codes ["g1", "g2", "g3", "g4", "g5", "g6", "g7", "g8", "g9"]

  # component codes

  @cur_bncc "bncc"

  # @comp_cgeral "bncc_cgeral"
  # @comp_cch "bncc_cch"
  # @comp_cer "bncc_cer"
  # @comp_clg "bncc_clg"
  # @comp_cma "bncc_cma"
  # @comp_cci "bncc_cci"
  # @comp_clp "bncc_clp"
  # @comp_car "bncc_car"
  # @comp_cef "bncc_cef"
  # @comp_cli "bncc_cli"
  # @comp_cge "bncc_cge"
  # @comp_chi "bncc_chi"

  @comp_ca "bncc_ca"
  @comp_pl "bncc_pl"
  @comp_ei "bncc_ei"
  @comp_ut "bncc_ut"
  @comp_oc "bncc_oc"
  @comp_ha "bncc_ha"

  @doc """
  Returns the list of "Habilidades BNCC" with full BNCC structure thread.
  Specific for grades 1 to 9.

  ### Options:

  `:filters` – accepts `:subjects_ids` and `:years_ids`

  ## Examples

      iex> list_bncc_items()
      [%CurriculumItem{}, ...]

  """
  def list_bncc_ef_items() do
    # subquery parent items (UT, OC, etc.)
    structure_items =
      from(
        ci in CurriculumItem,
        join: cc in assoc(ci, :curriculum_component),
        on: cc.code in [@comp_ut, @comp_oc, @comp_ca, @comp_pl, @comp_ei],
        join: re in CurriculumRelationship,
        on: re.curriculum_item_a_id == ci.id and re.type == "hierarchical",
        select: %{ci | children_id: re.curriculum_item_b_id, component_code: cc.code}
      )

    from(
      ha in CurriculumItem,
      join: cc in assoc(ha, :curriculum_component),
      on: cc.code == @comp_ha,
      left_join: ca in subquery(structure_items),
      on: ca.children_id == ha.id and ca.component_code == @comp_ca,
      left_join: pl in subquery(structure_items),
      on: pl.children_id == ha.id and pl.component_code == @comp_pl,
      left_join: ei in subquery(structure_items),
      on: ei.children_id == ha.id and ei.component_code == @comp_ei,
      left_join: ut in subquery(structure_items),
      on: ut.children_id == ha.id and ut.component_code == @comp_ut,
      join: oc in subquery(structure_items),
      on: oc.children_id == ha.id and oc.component_code == @comp_oc,
      join: su in assoc(ha, :subjects),
      on: su.code in @ef_subjects_codes,
      join: ye in assoc(ha, :years),
      on: ye.code in @ef_years_codes,
      join: cu in assoc(cc, :curriculum),
      where: cu.code == @cur_bncc,
      preload: [subjects: su, years: ye],
      select: {ha, ca, pl, ei, ut, oc}
    )
    |> Repo.all()
    |> Enum.map(fn {habilidade, campo_de_atuacao, pratica_de_linguagem, eixo, unidade_tematica,
                    objeto_de_conhecimento} ->
      HabilidadeBNCCEF
      |> struct(Map.to_list(habilidade))
      |> Map.put(:campo_de_atuacao, campo_de_atuacao)
      |> Map.put(:pratica_de_linguagem, pratica_de_linguagem)
      |> Map.put(:eixo, eixo)
      |> Map.put(:unidade_tematica, unidade_tematica)
      |> Map.put(:objeto_de_conhecimento, objeto_de_conhecimento)
    end)
  end
end
