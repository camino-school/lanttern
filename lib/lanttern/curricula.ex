defmodule Lanttern.Curricula do
  @moduledoc """
  The Curricula context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  alias Lanttern.Repo

  alias Lanttern.Curricula.Curriculum
  alias Lanttern.Curricula.CurriculumComponent
  alias Lanttern.Curricula.CurriculumItem
  alias Lanttern.Curricula.CurriculumRelationship

  alias Lanttern.LearningContext.Moment

  @doc """
  Returns the list of curricula.

  ## Examples

      iex> list_curricula()
      [%Curriculum{}, ...]

  """
  def list_curricula do
    from(
      c in Curriculum,
      order_by: :name
    )
    |> Repo.all()
  end

  @doc """
  Gets a single curriculum.

  Raises `Ecto.NoResultsError` if the Curriculum does not exist.

  ## Examples

      iex> get_curriculum!(123)
      %Curriculum{}

      iex> get_curriculum!(456)
      ** (Ecto.NoResultsError)

  """
  def get_curriculum!(id), do: Repo.get!(Curriculum, id)

  @doc """
  Creates a curriculum.

  ## Examples

      iex> create_curriculum(%{field: value})
      {:ok, %Curriculum{}}

      iex> create_curriculum(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_curriculum(attrs \\ %{}) do
    %Curriculum{}
    |> Curriculum.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a curriculum.

  ## Examples

      iex> update_curriculum(curriculum, %{field: new_value})
      {:ok, %Curriculum{}}

      iex> update_curriculum(curriculum, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_curriculum(%Curriculum{} = curriculum, attrs) do
    curriculum
    |> Curriculum.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a curriculum.

  ## Examples

      iex> delete_curriculum(curriculum)
      {:ok, %Curriculum{}}

      iex> delete_curriculum(curriculum)
      {:error, %Ecto.Changeset{}}

  """
  def delete_curriculum(%Curriculum{} = curriculum) do
    Repo.delete(curriculum)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking curriculum changes.

  ## Examples

      iex> change_curriculum(curriculum)
      %Ecto.Changeset{data: %Curriculum{}}

  """
  def change_curriculum(%Curriculum{} = curriculum, attrs \\ %{}) do
    Curriculum.changeset(curriculum, attrs)
  end

  @doc """
  Returns the list of curriculum_components.

  Ordered by position.

  ## Options:

      - `:preloads` – preloads associated data
      - `:curricula_ids` – filter results by curriculum

  ## Examples

      iex> list_curriculum_components()
      [%CurriculumComponent{}, ...]

  """
  def list_curriculum_components(opts \\ []) do
    from(cc in CurriculumComponent,
      order_by: :position
    )
    |> apply_list_curriculum_components_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_curriculum_components_opts(queryable, []), do: queryable

  defp apply_list_curriculum_components_opts(queryable, [{:curricula_ids, curricula_ids} | opts]) do
    from(
      cc in queryable,
      where: cc.curriculum_id in ^curricula_ids
    )
    |> apply_list_curriculum_components_opts(opts)
  end

  defp apply_list_curriculum_components_opts(queryable, [_opt | opts]),
    do: apply_list_curriculum_components_opts(queryable, opts)

  @doc """
  Gets a single curriculum_component.

  Raises `Ecto.NoResultsError` if the Curriculum component does not exist.

  ## Options:

      - `:preloads` – preloads associated data

  ## Examples

      iex> get_curriculum_component!(123)
      %CurriculumComponent{}

      iex> get_curriculum_component!(456)
      ** (Ecto.NoResultsError)

  """
  def get_curriculum_component!(id, opts \\ []) do
    Repo.get!(CurriculumComponent, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a curriculum_component.

  ## Examples

      iex> create_curriculum_component(%{field: value})
      {:ok, %CurriculumComponent{}}

      iex> create_curriculum_component(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_curriculum_component(attrs \\ %{}) do
    %CurriculumComponent{}
    |> CurriculumComponent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a curriculum_component.

  ## Examples

      iex> update_curriculum_component(curriculum_component, %{field: new_value})
      {:ok, %CurriculumComponent{}}

      iex> update_curriculum_component(curriculum_component, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_curriculum_component(%CurriculumComponent{} = curriculum_component, attrs) do
    curriculum_component
    |> CurriculumComponent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a curriculum_component.

  ## Examples

      iex> delete_curriculum_component(curriculum_component)
      {:ok, %CurriculumComponent{}}

      iex> delete_curriculum_component(curriculum_component)
      {:error, %Ecto.Changeset{}}

  """
  def delete_curriculum_component(%CurriculumComponent{} = curriculum_component) do
    Repo.delete(curriculum_component)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking curriculum_component changes.

  ## Examples

      iex> change_curriculum_component(curriculum_component)
      %Ecto.Changeset{data: %CurriculumComponent{}}

  """
  def change_curriculum_component(%CurriculumComponent{} = curriculum_component, attrs \\ %{}) do
    CurriculumComponent.changeset(curriculum_component, attrs)
  end

  @doc """
  Returns the list of curriculum items.

  Results are ordered by `subject.name`, `year.id`, and `code`.

  ## Options:

  - `:preloads` – preloads associated data (subjects and years are always preloaded *)
  - `:subjects_ids` – filter by subjects
  - `:years_ids` – filter by years
  - `:components_ids` – filter by curriculum components
  - `:base_query` - used in conjunction with `search_curriculum_items/2`

  ## Examples

      iex> list_curriculum_items()
      [%CurriculumItem{}, ...]

  #### * About subjects and years preload

  We don't preload in query because the list would be incomplete.

  E.g. if the curriculum item has subjects `A`, `B`, and `C`, and we're filtering by
  `B`, preloading in query would show only subject `B`.

  """
  @spec list_curriculum_items(Keyword.t()) :: [CurriculumItem.t()]
  def list_curriculum_items(opts \\ []) do
    queryable = Keyword.get(opts, :base_query, CurriculumItem)

    from(ci in queryable,
      left_join: s in assoc(ci, :subjects),
      as: :subject,
      left_join: y in assoc(ci, :years),
      as: :year,
      group_by: ci.id,
      order_by: [asc: min(s.name), asc: min(y.id), asc: ci.code]
    )
    |> apply_list_curriculum_items_opts(opts)
    |> Repo.all()
    |> maybe_preload(preloads: [:subjects, :years])
    |> maybe_preload(opts)
  end

  defp apply_list_curriculum_items_opts(queryable, []), do: queryable

  defp apply_list_curriculum_items_opts(queryable, [{:subjects_ids, subjects_ids} | opts])
       when is_list(subjects_ids) and subjects_ids != [] do
    from(
      [ci, subject: s] in queryable,
      where: s.id in ^subjects_ids
    )
    |> apply_list_curriculum_items_opts(opts)
  end

  defp apply_list_curriculum_items_opts(queryable, [{:years_ids, years_ids} | opts])
       when is_list(years_ids) and years_ids != [] do
    from(
      [ci, year: y] in queryable,
      where: y.id in ^years_ids
    )
    |> apply_list_curriculum_items_opts(opts)
  end

  defp apply_list_curriculum_items_opts(queryable, [{:components_ids, components_ids} | opts]) do
    from(
      ci in queryable,
      where: ci.curriculum_component_id in ^components_ids
    )
    |> apply_list_curriculum_items_opts(opts)
  end

  defp apply_list_curriculum_items_opts(queryable, [_opt | opts]),
    do: apply_list_curriculum_items_opts(queryable, opts)

  @doc """
  Returns the list of curriculum items linked to the given strand.

  ## Options:

      - `:preloads` – preloads associated data

  ## Examples

      iex> list_strand_curriculum_items(1)
      [%CurriculumItem{}, ...]

  """
  def list_strand_curriculum_items(strand_id, opts \\ []) do
    from(
      ci in CurriculumItem,
      join: ap in assoc(ci, :assessment_points),
      where: ap.strand_id == ^strand_id,
      order_by: ap.position,
      preload: [assessment_points: ap],
      select: %{
        ci
        | assessment_point_id: ap.id,
          is_differentiation: ap.is_differentiation,
          has_rubric: not is_nil(ap.rubric_id)
      }
    )
    |> Repo.all()
    |> maybe_preload(opts)
  end

  @doc """
  Returns the list of curriculum items linked to the given moment.

  ## Options:

      - `:preloads` – preloads associated data

  ## Examples

      iex> list_moment_curriculum_items(1)
      [%CurriculumItem{}, ...]

  """
  def list_moment_curriculum_items(moment_id, opts \\ []) do
    from(
      m in Moment,
      join: ci in assoc(m, :curriculum_items),
      where: m.id == ^moment_id,
      order_by: ci.name,
      distinct: ci.id,
      select: ci
    )
    |> Repo.all()
    |> maybe_preload(opts)
  end

  @doc """
  Search curriculum items by name.

  User can search by id by adding `#` before the id `#123`
  and search by code wrapping it in parenthesis `(ABC123)`.

  ## Options:

  View `list_curriculum_items/1` for `opts`

  ## Examples

      iex> list_curriculum_items()
      [%CurriculumItem{}, ...]

  """
  def search_curriculum_items(search_term, opts \\ [])

  def search_curriculum_items("#" <> search_term, opts) do
    if search_term =~ ~r/^[0-9]+\z/ do
      query =
        from(
          ci in CurriculumItem,
          where: ci.id == ^search_term
        )

      [{:base_query, query} | opts]
      |> list_curriculum_items()
    else
      search_curriculum_items(search_term, opts)
    end
  end

  def search_curriculum_items("(" <> search_term, opts) do
    case Regex.run(~r/(.+)\)\z/, search_term, capture: :all_but_first) do
      [code] ->
        query =
          from(
            ci in CurriculumItem,
            where: ci.code == ^code
          )

        [{:base_query, query} | opts]
        |> list_curriculum_items()

      _ ->
        search_curriculum_items(search_term, opts)
    end
  end

  def search_curriculum_items(search_term, opts) do
    ilike_search_term = "%#{search_term}%"

    query =
      from(
        ci in CurriculumItem,
        where: ilike(ci.name, ^ilike_search_term),
        order_by: {:asc, fragment("? <<-> ?", ^search_term, ci.name)}
      )

    [{:base_query, query} | opts]
    |> list_curriculum_items()
  end

  @doc """
  Gets a single curriculum item.

  Returns `nil` if the Curriculum Item does not exist.

  ## Options:

  - `:preloads` – preloads associated data

  ## Examples

      iex> get_curriculum_item(123)
      %CurriculumItem{}

      iex> get_curriculum_item(456)
      nil

  """
  def get_curriculum_item(id, opts \\ []) do
    Repo.get(CurriculumItem, id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single curriculum item.

  Same as `get_curriculum_item/2`, but raises `Ecto.NoResultsError` if the Curriculum Item does not exist.

  """
  def get_curriculum_item!(id, opts \\ []) do
    Repo.get!(CurriculumItem, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a curriculum item.

  ## Examples

      iex> create_curriculum_item(%{field: value})
      {:ok, %CurriculumItem{}}

      iex> create_curriculum_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_curriculum_item(attrs \\ %{}) do
    %CurriculumItem{}
    |> CurriculumItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a curriculum item.

  ## Examples

      iex> update_curriculum_item(item, %{field: new_value})
      {:ok, %CurriculumItem{}}

      iex> update_curriculum_item(item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_curriculum_item(%CurriculumItem{} = curriculum_item, attrs) do
    curriculum_item
    |> Repo.preload([:subjects, :years])
    |> CurriculumItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a curriculum item.

  ## Examples

      iex> delete_curriculum_item(curriculum_item)
      {:ok, %CurriculumItem{}}

      iex> delete_curriculum_item(curriculum_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_curriculum_item(%CurriculumItem{} = curriculum_item) do
    Repo.delete(curriculum_item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking curriculum item changes.

  ## Examples

      iex> change_curriculum_item(curriculum_item)
      %Ecto.Changeset{data: %CurriculumItem{}}

  """
  def change_curriculum_item(%CurriculumItem{} = curriculum_item, attrs \\ %{}) do
    CurriculumItem.changeset(curriculum_item, attrs)
  end

  @doc """
  Returns the list of curriculum_relationships.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> list_curriculum_relationships()
      [%CurriculumRelationship{}, ...]

  """
  def list_curriculum_relationships(opts \\ []) do
    Repo.all(CurriculumRelationship)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single curriculum_relationship.

  Raises `Ecto.NoResultsError` if the Curriculum relationship does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_curriculum_relationship!(123)
      %CurriculumRelationship{}

      iex> get_curriculum_relationship!(456)
      ** (Ecto.NoResultsError)

  """
  def get_curriculum_relationship!(id, opts \\ []) do
    Repo.get!(CurriculumRelationship, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a curriculum_relationship.

  ## Examples

      iex> create_curriculum_relationship(%{field: value})
      {:ok, %CurriculumRelationship{}}

      iex> create_curriculum_relationship(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_curriculum_relationship(attrs \\ %{}) do
    %CurriculumRelationship{}
    |> CurriculumRelationship.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a curriculum_relationship.

  ## Examples

      iex> update_curriculum_relationship(curriculum_relationship, %{field: new_value})
      {:ok, %CurriculumRelationship{}}

      iex> update_curriculum_relationship(curriculum_relationship, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_curriculum_relationship(%CurriculumRelationship{} = curriculum_relationship, attrs) do
    curriculum_relationship
    |> CurriculumRelationship.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a curriculum_relationship.

  ## Examples

      iex> delete_curriculum_relationship(curriculum_relationship)
      {:ok, %CurriculumRelationship{}}

      iex> delete_curriculum_relationship(curriculum_relationship)
      {:error, %Ecto.Changeset{}}

  """
  def delete_curriculum_relationship(%CurriculumRelationship{} = curriculum_relationship) do
    Repo.delete(curriculum_relationship)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking curriculum_relationship changes.

  ## Examples

      iex> change_curriculum_relationship(curriculum_relationship)
      %Ecto.Changeset{data: %CurriculumRelationship{}}

  """
  def change_curriculum_relationship(
        %CurriculumRelationship{} = curriculum_relationship,
        attrs \\ %{}
      ) do
    CurriculumRelationship.changeset(curriculum_relationship, attrs)
  end
end
