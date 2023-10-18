defmodule Lanttern.BNCC do
  @moduledoc """
  The BNCC context.

  ## BNCC context codes

  ### Curriculum
    - `bncc`

  ### Components
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
  @c_co "bncc_co"
  @c_ca "bncc_ca"
  @c_pl "bncc_pl"
  @c_ei "bncc_ei"
  @c_ut "bncc_ut"
  @c_oc "bncc_oc"
  @c_ha "bncc_ha"

  @doc """
  Create BNCC curriculum and components.

  Use this function to setup a new environment before importing BNCC items.

  In case a curriculum with the code "bncc" already exists, the function
  will use this. In case a component already exists (same `code` and `curriculum_id`),
  the function will ignore the insertion (using `on_conflict: :nothing`).
  """
  def seed_bncc_structure() do
    %{id: bncc_id} =
      case Repo.get_by(Curriculum, code: @bncc) do
        nil -> Repo.insert!(%Curriculum{code: @bncc, name: "BNCC"})
        bncc -> bncc
      end

    [
      {@c_co, "Competências"},
      {@c_ca, "Campos de Atuação"},
      {@c_pl, "Práticas de Linguagem"},
      {@c_ut, "Unidades Temáticas"},
      {@c_oc, "Objetos de Conhecimento"},
      {@c_ha, "Habilidades"}
    ]
    |> Enum.map(fn {code, name} ->
      %{code: code, name: name, curriculum_id: bncc_id}
    end)
    |> Enum.map(&insert_component/1)

    :ok
  end

  defp insert_component(params) do
    %CurriculumComponent{}
    |> CurriculumComponent.changeset(params)
    |> Repo.insert!(on_conflict: :nothing)
  end

  @doc """
  Create BNCC competencies based on the csv file in `priv/static/seeds/bncc/competencies.csv`
  """
  def seed_bncc_competencies() do
    with %{id: competencies_component_id} <- Repo.get_by(CurriculumComponent, code: @c_co),
         path <- Application.app_dir(:lanttern, "priv/static/seeds/bncc/competencies.csv"),
         {:ok, csv} <- File.read(path),
         subjects_code_id_map <- Taxonomy.generate_subjects_code_id_map() do
      competencies =
        CSV.parse_string(csv)
        |> Enum.map(fn [name, subjects] ->
          %{
            name: name,
            subjects_ids: get_ids_from_codes(subjects, subjects_code_id_map),
            curriculum_component_id: competencies_component_id
          }
        end)
        |> Enum.map(&get_or_insert_item/1)

      {:ok, competencies}
    end
  end

  defp get_ids_from_codes(codes, code_id_map) do
    codes
    |> String.split(",", trim: true)
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

  @doc """
  Create BNCC EF items based on the csv file in `priv/static/seeds/bncc/ef.csv`
  """
  def seed_bncc_ef_items() do
    with path <- Application.app_dir(:lanttern, "priv/static/seeds/bncc/ef.csv"),
         {:ok, csv} <- File.read(path) do
      components_code_id_map = generate_components_code_id_map()
      subjects_code_id_map = Taxonomy.generate_subjects_code_id_map()
      years_code_id_map = Taxonomy.generate_years_code_id_map()

      ef_items =
        CSV.parse_string(csv)
        |> Enum.map(fn [ca, pl, ei, ut, oc, ha, code, subjects, years] ->
          insert_bncc_ef_item(
            %HabilidadeBNCCEF{
              campo_de_atuacao: ca,
              pratica_de_linguagem: pl,
              eixo: ei,
              unidade_tematica: ut,
              objeto_de_conhecimento: oc,
              name: ha,
              code: code
            },
            get_ids_from_codes(subjects, subjects_code_id_map),
            get_ids_from_codes(years, years_code_id_map),
            components_code_id_map
          )
        end)

      {:ok, ef_items}
    end
  end

  defp generate_components_code_id_map() do
    from(
      c in CurriculumComponent,
      select: {c.code, c.id}
    )
    |> Repo.all()
    |> Enum.into(%{})
  end

  defp insert_bncc_ef_item(
         %HabilidadeBNCCEF{
           campo_de_atuacao: ca,
           pratica_de_linguagem: pl,
           eixo: ei,
           unidade_tematica: ut,
           objeto_de_conhecimento: oc,
           name: ha,
           code: code
         },
         subjects_ids,
         years_ids,
         components_code_id_map
       ) do
    item_ca =
      get_or_insert_item(%{
        curriculum_component_id: components_code_id_map[@c_ca],
        name: ca,
        subjects_ids: subjects_ids
      })

    item_pl =
      get_or_insert_item(%{
        curriculum_component_id: components_code_id_map[@c_pl],
        name: pl,
        subjects_ids: subjects_ids
      })

    item_ei =
      get_or_insert_item(%{
        curriculum_component_id: components_code_id_map[@c_ei],
        name: ei,
        subjects_ids: subjects_ids
      })

    item_ut =
      get_or_insert_item(%{
        curriculum_component_id: components_code_id_map[@c_ut],
        name: ut,
        subjects_ids: subjects_ids
      })

    item_oc =
      get_or_insert_item(%{
        curriculum_component_id: components_code_id_map[@c_oc],
        name: oc,
        subjects_ids: subjects_ids
      })

    item_ha =
      get_or_insert_item(%{
        curriculum_component_id: components_code_id_map[@c_ha],
        code: code,
        name: ha,
        subjects_ids: subjects_ids,
        years_ids: years_ids
      })

    insert_relationship(item_ca, item_ha.id)
    insert_relationship(item_pl, item_ha.id)
    insert_relationship(item_ei, item_ha.id)
    insert_relationship(item_ut, item_ha.id)
    insert_relationship(item_oc, item_ha.id)
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
