defmodule Lanttern.BNCC do
  @moduledoc """
  The BNCC context.

  ## BNCC curriculum and component codes

  ### Curriculum
    - `bncc`

  ### Components
    - `bncc_da` "Direitos de aprendizagem"
    - `bncc_ce` "Campos de experiência"
    - `bncc_oa` "Objetivos de aprendizagem"
    - `bncc_co` "Competências"
    - `bncc_ca` "Campos de atuação"
    - `bncc_pl` "Práticas de linguagem"
    - `bncc_ei` "Eixos"
    - `bncc_ut` "Unidades temáticas"
    - `bncc_oc` "Objetos de conhecimento"
    - `bncc_ha` "Habilidades"
  """

  import Ecto.Query, warn: false
  alias NimbleCSV.RFC4180, as: CSV

  import Lanttern.RepoHelpers

  alias Lanttern.Repo
  alias Lanttern.BNCC.HabilidadeBNCCEF
  alias Lanttern.Curricula.Curriculum
  alias Lanttern.Curricula.CurriculumComponent
  alias Lanttern.Curricula.CurriculumItem
  alias Lanttern.Curricula.CurriculumRelationship
  alias Lanttern.Taxonomy
  alias Lanttern.Taxonomy.Subject
  alias Lanttern.Taxonomy.Year

  # BNCC related taxonomy
  @ef_subjects_codes ["port", "arts", "move", "engl", "math", "scie", "geog", "hist", "reli"]
  @ef_years_codes ["g1", "g2", "g3", "g4", "g5", "g6", "g7", "g8", "g9"]

  # curriculum code
  @bncc "bncc"

  # component codes
  @c_da "bncc_da"
  @c_ce "bncc_ce"
  @c_oa "bncc_oa"
  @c_co "bncc_co"
  @c_ca "bncc_ca"
  @c_pl "bncc_pl"
  @c_ei "bncc_ei"
  @c_ut "bncc_ut"
  @c_oc "bncc_oc"
  @c_ha "bncc_ha"

  # CSV paths
  @csv_path_da "priv/static/seeds/bncc/direitos_de_aprendizagem.csv"
  @csv_path_co "priv/static/seeds/bncc/competencias.csv"
  @csv_path_ei "priv/static/seeds/bncc/ei.csv"
  @csv_path_ef1 "priv/static/seeds/bncc/ef1.csv"
  @csv_path_ef2 "priv/static/seeds/bncc/ef2.csv"
  @csv_path_em "priv/static/seeds/bncc/em.csv"
  @csv_path_em_lp_co "priv/static/seeds/bncc/em_lp_competencias.csv"

  @doc """
  Create BNCC curriculum, components, and items.

  This function is intended to be run a single time, during
  environment setup. In case a curriculum with the code "bncc"
  already exists, the function will not run and will return `:noop`.
  Else, it'll return `:ok`.

  ## Support (private) functions

  To help with the understading of the whole pipeline, we are documenting
  the role of the main private functions present in the pipeline.

  ### `generate_subjects_and_years_maps/0`

  This function generates two maps: one for subjects and one for years,
  comprising of the subjects and years codes as keys, and their ids as values.
  Those two maps are put inside a general code/id pairs map:

      %{subjects: %{...}, years: %{...}}

  ### `seed_bncc_components/2`

  This function receives the code/id map and BNCC curriculum id as arguments,
  and insert all curriculum components in DB. It'll add a `:components` key to the
  code/id map and return it:

      %{components: %{...}, subjects: %{...}, years: %{...}}

  ### `seed_bncc_learning_rights/1`

  Receives the code/id map as argument, and insert all learning rights into DB.
  It'll return the code/id map for chaining.

  ### `seed_bncc_competencies/1`

  Receives the code/id map as argument, and insert all competencies into DB.
  It'll return the code/id map for chaining.

  ### `seed_bncc_items/1`

  Receives the code/id map as argument, and insert all items into DB.
  This function also inserts all BNCC items relationships.

  Returns `:ok`.

  ## Examples

      iex> seed_bncc()
      :ok

      iex> seed_bncc()
      :noop
  """
  def seed_bncc() do
    case Repo.get_by(Curriculum, code: @bncc) do
      nil ->
        %{id: bncc_id} = Repo.insert!(%Curriculum{code: @bncc, name: "BNCC"})

        generate_subjects_and_years_maps()
        |> seed_bncc_components(bncc_id)
        |> seed_bncc_learning_rights()
        |> seed_bncc_competencies()
        |> seed_bncc_items()

        :ok

      _bncc ->
        :noop
    end
  end

  defp generate_subjects_and_years_maps() do
    with subjects_code_id_map <- Taxonomy.generate_subjects_code_id_map(),
         years_code_id_map <- Taxonomy.generate_years_code_id_map() do
      %{
        subjects: subjects_code_id_map,
        years: years_code_id_map
      }
    end
  end

  # Seed BNCC components

  defp seed_bncc_components(code_id_maps, bncc_id) do
    components_code_id_map =
      [
        {bncc_id, @c_da, "Direitos de Aprendizagem"},
        {bncc_id, @c_ce, "Campos de experiência"},
        {bncc_id, @c_oa, "Objetivos de Aprendizagem"},
        {bncc_id, @c_co, "Competências"},
        {bncc_id, @c_ca, "Campos de Atuação"},
        {bncc_id, @c_pl, "Práticas de Linguagem"},
        {bncc_id, @c_ei, "Eixos"},
        {bncc_id, @c_ut, "Unidades Temáticas"},
        {bncc_id, @c_oc, "Objetos de Conhecimento"},
        {bncc_id, @c_ha, "Habilidades"}
      ]
      |> Enum.map(&build_component_params/1)
      |> Enum.map(&insert_component/1)
      |> build_component_code_id_map()

    code_id_maps
    |> Map.put(:components, components_code_id_map)
  end

  defp build_component_params({bncc_id, code, name}),
    do: %{curriculum_id: bncc_id, code: code, name: name}

  defp insert_component(params) do
    %CurriculumComponent{}
    |> CurriculumComponent.changeset(params)
    |> Repo.insert!(on_conflict: :nothing)
  end

  defp build_component_code_id_map(components_list) do
    components_list
    |> Enum.map(&{&1.code, &1.id})
    |> Enum.into(%{})
  end

  # Seed learning rights

  defp seed_bncc_learning_rights(code_id_maps) do
    parse_csv_string(@csv_path_da)
    |> Enum.map(&build_learning_right_params(&1, code_id_maps))
    |> Enum.map(&get_or_insert_item/1)

    code_id_maps
  end

  defp build_learning_right_params([name, _subjects, years], code_id_maps) do
    %{
      name: name,
      years_ids: get_ids_from_codes(years, code_id_maps.years),
      curriculum_component_id: code_id_maps.components[@c_da]
    }
  end

  # Seed competencies

  defp seed_bncc_competencies(code_id_maps) do
    parse_csv_string(@csv_path_co)
    |> Enum.map(&build_competency_params(&1, code_id_maps))
    |> Enum.map(&get_or_insert_item/1)

    code_id_maps
  end

  defp build_competency_params([name, subjects, years], code_id_maps) do
    %{
      name: name,
      subjects_ids: get_ids_from_codes(subjects, code_id_maps.subjects),
      years_ids: get_ids_from_codes(years, code_id_maps.years),
      curriculum_component_id: code_id_maps.components[@c_co]
    }
  end

  # Seed items

  def seed_bncc_items(code_id_maps) do
    # EI
    parse_csv_string(@csv_path_ei)
    |> Enum.map(&insert_ei_item(&1, code_id_maps))

    # EF and EM
    [
      parse_csv_string(@csv_path_ef1),
      parse_csv_string(@csv_path_ef2),
      parse_csv_string(@csv_path_em)
    ]
    |> Enum.concat()
    |> Enum.map(&insert_item(&1, code_id_maps))

    # create EM Portuguese and competencies relationships
    parse_csv_string(@csv_path_em_lp_co)
    |> Enum.map(&create_em_competency_item_relationship/1)
  end

  defp insert_ei_item([ce, oa, code, years], code_id_maps) do
    item_ce =
      get_or_insert_item(%{
        curriculum_component_id: code_id_maps.components[@c_ce],
        name: ce
      })

    item_oa =
      get_or_insert_item(%{
        curriculum_component_id: code_id_maps.components[@c_oa],
        years_ids: get_ids_from_codes(years, code_id_maps.years),
        name: oa,
        code: code
      })

    insert_relationship(item_ce, item_oa.id)
  end

  defp insert_item(
         [ca, pl, ei, ut, oc, ha, code, subjects, years],
         code_id_maps
       ) do
    item_ca =
      get_or_insert_item(%{
        curriculum_component_id: code_id_maps.components[@c_ca],
        name: ca
      })

    item_pl =
      get_or_insert_item(%{
        curriculum_component_id: code_id_maps.components[@c_pl],
        name: pl
      })

    item_ei =
      get_or_insert_item(%{
        curriculum_component_id: code_id_maps.components[@c_ei],
        name: ei
      })

    item_ut =
      get_or_insert_item(%{
        curriculum_component_id: code_id_maps.components[@c_ut],
        name: ut
      })

    item_oc =
      get_or_insert_item(%{
        curriculum_component_id: code_id_maps.components[@c_oc],
        name: oc
      })

    item_ha =
      get_or_insert_item(%{
        curriculum_component_id: code_id_maps.components[@c_ha],
        code: code,
        name: ha,
        subjects_ids: get_ids_from_codes(subjects, code_id_maps.subjects),
        years_ids: get_ids_from_codes(years, code_id_maps.years)
      })

    insert_relationship(item_ca, item_ha.id)
    insert_relationship(item_pl, item_ha.id)
    insert_relationship(item_ei, item_ha.id)
    insert_relationship(item_ut, item_ha.id)
    insert_relationship(item_oc, item_ha.id)
  end

  defp create_em_competency_item_relationship([competency, item_code]) do
    competency = Repo.get_by!(CurriculumItem, name: competency)
    item = Repo.get_by!(CurriculumItem, code: item_code)
    insert_relationship(competency, item.id)
  end

  # Utils

  defp parse_csv_string(path) do
    with Application.app_dir(:lanttern, path),
         {:ok, csv} <- File.read(path),
         do: CSV.parse_string(csv)
  end

  defp get_ids_from_codes(codes, code_id_map) do
    codes
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn code -> code_id_map[code] end)
  end

  defp get_or_insert_item(%{name: ""}), do: nil

  defp get_or_insert_item(%{name: name, curriculum_component_id: component_id} = params) do
    case Repo.get_by(CurriculumItem, name: name, curriculum_component_id: component_id) do
      nil ->
        %CurriculumItem{}
        |> CurriculumItem.changeset(params)
        |> Repo.insert!()

      curriculum_item ->
        curriculum_item
    end
  end

  defp insert_relationship(nil, _), do: nil

  defp insert_relationship(%{id: item_id}, ha_id) do
    Repo.insert!(
      %CurriculumRelationship{
        curriculum_item_a_id: item_id,
        curriculum_item_b_id: ha_id,
        type: "hierarchical"
      },
      on_conflict: :nothing
    )
  end

  @doc """
  Returns the list of "Habilidades BNCC" with full BNCC structure thread.
  Specific for grades 1 to 9.

  ### Options:

  `:filters` – accepts `:subjects_ids` and `:years_ids`

  ## Examples

      iex> list_bncc_items()
      [%CurriculumItem{}, ...]

  """
  def list_bncc_ef_items(opts \\ []) do
    filter_fields_and_ops = [
      subjects_ids: :in,
      years_ids: :in
    ]

    flop_params = %{
      filters: build_flop_filters_param(opts, filter_fields_and_ops),
      order_by: [:code]
    }

    # subquery parent items (UT, OC, etc.)
    structure_items =
      from(
        ci in CurriculumItem,
        join: cc in assoc(ci, :curriculum_component),
        on: cc.code in [@c_ut, @c_oc, @c_ca, @c_pl, @c_ei],
        join: re in CurriculumRelationship,
        on: re.curriculum_item_a_id == ci.id and re.type == "hierarchical",
        select: %{ci | children_id: re.curriculum_item_b_id, component_code: cc.code}
      )

    from(
      ha in CurriculumItem,
      join: cc in assoc(ha, :curriculum_component),
      on: cc.code == @c_ha,
      left_join: ca in subquery(structure_items),
      on: ca.children_id == ha.id and ca.component_code == @c_ca,
      left_join: pl in subquery(structure_items),
      on: pl.children_id == ha.id and pl.component_code == @c_pl,
      left_join: ei in subquery(structure_items),
      on: ei.children_id == ha.id and ei.component_code == @c_ei,
      left_join: ut in subquery(structure_items),
      on: ut.children_id == ha.id and ut.component_code == @c_ut,
      join: oc in subquery(structure_items),
      on: oc.children_id == ha.id and oc.component_code == @c_oc,
      join: su in assoc(ha, :subjects),
      as: :subjects,
      on: su.code in @ef_subjects_codes,
      join: ye in assoc(ha, :years),
      as: :years,
      on: ye.code in @ef_years_codes,
      join: cu in assoc(cc, :curriculum),
      where: cu.code == @bncc,
      order_by: [su.id, ye.id],
      preload: [subjects: su, years: ye],
      select: {ha, ca.name, pl.name, ei.name, ut.name, oc.name}
    )
    |> handle_flop_validate_and_run(flop_params, for: CurriculumItem)
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

  @doc """
  Returns the list of BNCC EF curriculum subjects

  ## Examples

      iex> list_bncc_ef_subjects()
      [%Subject{}, ...]

  """
  def list_bncc_ef_subjects() do
    from(
      s in Subject,
      where: s.code in @ef_subjects_codes
    )
    |> Repo.all()
  end

  @doc """
  Returns the list of BNCC EF curriculum years

  ## Examples

      iex> list_bncc_ef_years()
      [%Year{}, ...]

  """
  def list_bncc_ef_years() do
    from(
      y in Year,
      where: y.code in @ef_years_codes
    )
    |> Repo.all()
  end
end
