defmodule Lanttern.BNCC do
  @moduledoc """
  The BNCC context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.BNCC.Habilidade
  alias Lanttern.Curricula.CurriculumItem
  alias Lanttern.Curricula.CurriculumRelationship

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

  # @comp_ca "bncc_ca"
  # @comp_pl "bncc_pl"
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
        on: cc.code in [@comp_ut, @comp_oc],
        join: re in CurriculumRelationship,
        on: re.curriculum_item_a_id == ci.id and re.type == "hierarchical",
        select: %{ci | children_id: re.curriculum_item_b_id, component_code: cc.code}
      )

    from(
      ha in CurriculumItem,
      join: cc in assoc(ha, :curriculum_component),
      on: cc.code == @comp_ha,
      join: oc in subquery(structure_items),
      on: oc.children_id == ha.id and oc.component_code == @comp_oc,
      join: ut in subquery(structure_items),
      on: ut.children_id == ha.id and ut.component_code == @comp_ut,
      join: su in assoc(ha, :subjects),
      join: ye in assoc(ha, :years),
      join: cu in assoc(cc, :curriculum),
      where: cu.code == @cur_bncc,
      preload: [subjects: su, years: ye],
      select: {ha, ut, oc}
    )
    |> Repo.all()
    |> Enum.map(fn {habilidade, unidade_tematica, objeto_de_conhecimento} ->
      Habilidade
      |> struct(Map.to_list(habilidade))
      |> Map.put(:unidade_tematica, unidade_tematica)
      |> Map.put(:objeto_de_conhecimento, objeto_de_conhecimento)
    end)
  end
end
