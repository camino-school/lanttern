defmodule Lanttern.Grading do
  @moduledoc """
  The Grading context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo
  import Lanttern.RepoHelpers

  alias Lanttern.Grading.Composition
  alias Lanttern.Grading.CompositionComponent
  alias Lanttern.Grading.CompositionComponentItem
  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Grading.Scale

  @doc """
  Returns the list of compositions.
  Optionally preloads associated data.

  ## Examples

      iex> list_compositions()
      [%Composition{}, ...]

  """
  def list_compositions(preloads \\ []) do
    Repo.all(Composition)
    |> Repo.preload(preloads)
  end

  @doc """
  Gets a single composition.
  Optionally preloads associated data.

  Raises `Ecto.NoResultsError` if the Composition does not exist.

  ## Examples

      iex> get_composition!(123)
      %Composition{}

      iex> get_composition!(456)
      ** (Ecto.NoResultsError)

  """
  def get_composition!(id, preloads \\ []) do
    Repo.get!(Composition, id)
    |> Repo.preload(preloads)
  end

  @doc """
  Creates a composition.

  ## Examples

      iex> create_composition(%{field: value})
      {:ok, %Composition{}}

      iex> create_composition(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_composition(attrs \\ %{}) do
    %Composition{}
    |> Composition.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a composition.

  ## Examples

      iex> update_composition(composition, %{field: new_value})
      {:ok, %Composition{}}

      iex> update_composition(composition, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_composition(%Composition{} = composition, attrs) do
    composition
    |> Composition.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a composition.

  ## Examples

      iex> delete_composition(composition)
      {:ok, %Composition{}}

      iex> delete_composition(composition)
      {:error, %Ecto.Changeset{}}

  """
  def delete_composition(%Composition{} = composition) do
    Repo.delete(composition)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking composition changes.

  ## Examples

      iex> change_composition(composition)
      %Ecto.Changeset{data: %Composition{}}

  """
  def change_composition(%Composition{} = composition, attrs \\ %{}) do
    Composition.changeset(composition, attrs)
  end

  @doc """
  Returns the list of composition_components.
  Optionally preloads associated data.

  ## Examples

      iex> list_composition_components()
      [%CompositionComponent{}, ...]

  """
  def list_composition_components(preloads \\ []) do
    Repo.all(CompositionComponent)
    |> Repo.preload(preloads)
  end

  @doc """
  Gets a single composition_component.
  Optionally preloads associated data.

  Raises `Ecto.NoResultsError` if the Composition component does not exist.

  ## Examples

      iex> get_composition_component!(123)
      %CompositionComponent{}

      iex> get_composition_component!(456)
      ** (Ecto.NoResultsError)

  """
  def get_composition_component!(id, preloads \\ []) do
    CompositionComponent
    |> Repo.get!(id)
    |> Repo.preload(preloads)
  end

  @doc """
  Creates a composition_component.

  ## Examples

      iex> create_composition_component(%{field: value})
      {:ok, %CompositionComponent{}}

      iex> create_composition_component(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_composition_component(attrs \\ %{}) do
    %CompositionComponent{}
    |> CompositionComponent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a composition_component.

  ## Examples

      iex> update_composition_component(composition_component, %{field: new_value})
      {:ok, %CompositionComponent{}}

      iex> update_composition_component(composition_component, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_composition_component(%CompositionComponent{} = composition_component, attrs) do
    composition_component
    |> CompositionComponent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a composition_component.

  ## Examples

      iex> delete_composition_component(composition_component)
      {:ok, %CompositionComponent{}}

      iex> delete_composition_component(composition_component)
      {:error, %Ecto.Changeset{}}

  """
  def delete_composition_component(%CompositionComponent{} = composition_component) do
    Repo.delete(composition_component)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking composition_component changes.

  ## Examples

      iex> change_composition_component(composition_component)
      %Ecto.Changeset{data: %CompositionComponent{}}

  """
  def change_composition_component(%CompositionComponent{} = composition_component, attrs \\ %{}) do
    CompositionComponent.changeset(composition_component, attrs)
  end

  @doc """
  Returns the list of component_items.
  Optionally preloads associated data.

  ## Examples

      iex> list_component_items()
      [%CompositionComponentItem{}, ...]

  """
  def list_component_items(preloads \\ []) do
    Repo.all(CompositionComponentItem)
    |> Repo.preload(preloads)
  end

  @doc """
  Gets a single composition_component_item.
  Optionally preloads associated data.

  Raises `Ecto.NoResultsError` if the Composition component item does not exist.

  ## Examples

      iex> get_composition_component_item!(123)
      %CompositionComponentItem{}

      iex> get_composition_component_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_composition_component_item!(id, preloads \\ []) do
    Repo.get!(CompositionComponentItem, id)
    |> Repo.preload(preloads)
  end

  @doc """
  Creates a composition_component_item.

  ## Examples

      iex> create_composition_component_item(%{field: value})
      {:ok, %CompositionComponentItem{}}

      iex> create_composition_component_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_composition_component_item(attrs \\ %{}) do
    %CompositionComponentItem{}
    |> CompositionComponentItem.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a composition_component_item.

  ## Examples

      iex> update_composition_component_item(composition_component_item, %{field: new_value})
      {:ok, %CompositionComponentItem{}}

      iex> update_composition_component_item(composition_component_item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_composition_component_item(
        %CompositionComponentItem{} = composition_component_item,
        attrs
      ) do
    composition_component_item
    |> CompositionComponentItem.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a composition_component_item.

  ## Examples

      iex> delete_composition_component_item(composition_component_item)
      {:ok, %CompositionComponentItem{}}

      iex> delete_composition_component_item(composition_component_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_composition_component_item(%CompositionComponentItem{} = composition_component_item) do
    Repo.delete(composition_component_item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking composition_component_item changes.

  ## Examples

      iex> change_composition_component_item(composition_component_item)
      %Ecto.Changeset{data: %CompositionComponentItem{}}

  """
  def change_composition_component_item(
        %CompositionComponentItem{} = composition_component_item,
        attrs \\ %{}
      ) do
    CompositionComponentItem.changeset(composition_component_item, attrs)
  end

  @doc """
  Returns the list of ordinal_values.

  ### Options:

  `:preloads` – preloads associated data
  `:scale_id` – filter ordinal values by scale and order results by `normalized_value`

  ## Examples

      iex> list_ordinal_values()
      [%OrdinalValue{}, ...]

  """
  def list_ordinal_values(opts \\ []) do
    OrdinalValue
    |> maybe_filter_ordinal_values_by_scale(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp maybe_filter_ordinal_values_by_scale(ordinal_value_query, opts) do
    case Keyword.get(opts, :scale_id) do
      nil ->
        ordinal_value_query

      scale_id ->
        from(
          ov in ordinal_value_query,
          where: ov.scale_id == ^scale_id,
          order_by: ov.normalized_value
        )
    end
  end

  @doc """
  Gets a single ordinal_value.
  Optionally preloads associated data.

  Raises `Ecto.NoResultsError` if the Ordinal value does not exist.

  ## Examples

      iex> get_ordinal_value!(123)
      %OrdinalValue{}

      iex> get_ordinal_value!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ordinal_value!(id, preloads \\ []) do
    Repo.get!(OrdinalValue, id)
    |> Repo.preload(preloads)
  end

  @doc """
  Creates a ordinal_value.

  ## Examples

      iex> create_ordinal_value(%{field: value})
      {:ok, %OrdinalValue{}}

      iex> create_ordinal_value(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ordinal_value(attrs \\ %{}) do
    %OrdinalValue{}
    |> OrdinalValue.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ordinal_value.

  ## Examples

      iex> update_ordinal_value(ordinal_value, %{field: new_value})
      {:ok, %OrdinalValue{}}

      iex> update_ordinal_value(ordinal_value, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ordinal_value(%OrdinalValue{} = ordinal_value, attrs) do
    ordinal_value
    |> OrdinalValue.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ordinal_value.

  ## Examples

      iex> delete_ordinal_value(ordinal_value)
      {:ok, %OrdinalValue{}}

      iex> delete_ordinal_value(ordinal_value)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ordinal_value(%OrdinalValue{} = ordinal_value) do
    Repo.delete(ordinal_value)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ordinal_value changes.

  ## Examples

      iex> change_ordinal_value(ordinal_value)
      %Ecto.Changeset{data: %OrdinalValue{}}

  """
  def change_ordinal_value(%OrdinalValue{} = ordinal_value, attrs \\ %{}) do
    OrdinalValue.changeset(ordinal_value, attrs)
  end

  @doc """
  Returns the list of scales.

  Accepts `:type` opts.

  ## Examples

      iex> list_scales()
      [%Scale{}, ...]

  """

  def list_scales(opts \\ [])

  def list_scales(type: type) do
    from(s in Scale, where: s.type == ^type)
    |> Repo.all()
  end

  def list_scales(_opts) do
    Repo.all(Scale)
  end

  @doc """
  Gets a single scale.

  Raises `Ecto.NoResultsError` if the Scale does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_scale!(123)
      %Scale{}

      iex> get_scale!(456)
      ** (Ecto.NoResultsError)

  """
  def get_scale!(id, opts \\ []) do
    Repo.get!(Scale, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a scale.

  ## Examples

      iex> create_scale(%{field: value})
      {:ok, %Scale{}}

      iex> create_scale(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_scale(attrs \\ %{}) do
    %Scale{}
    |> Scale.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a scale.

  ## Examples

      iex> update_scale(scale, %{field: new_value})
      {:ok, %Scale{}}

      iex> update_scale(scale, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_scale(%Scale{} = scale, attrs) do
    scale
    |> Scale.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a scale.

  ## Examples

      iex> delete_scale(scale)
      {:ok, %Scale{}}

      iex> delete_scale(scale)
      {:error, %Ecto.Changeset{}}

  """
  def delete_scale(%Scale{} = scale) do
    Repo.delete(scale)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking scale changes.

  ## Examples

      iex> change_scale(scale)
      %Ecto.Changeset{data: %Scale{}}

  """
  def change_scale(%Scale{} = scale, attrs \\ %{}) do
    Scale.changeset(scale, attrs)
  end

  @doc """
  Converts a normalized value to a scale's score (float) or `OrdinalValue`.
  """
  @spec convert_normalized_value_to_scale_value(float(), Scale.t()) :: float() | OrdinalValue.t()

  def convert_normalized_value_to_scale_value(normalized_value, %Scale{type: "ordinal"} = scale) do
    ordinal_values = list_ordinal_values(scale_id: scale.id)

    # get index of ordinal value
    # use sort to ensure scale breakpoints are sorted
    i =
      scale.breakpoints
      |> Enum.sort()
      |> get_normalized_value_breakpoint_index(normalized_value)

    Enum.at(ordinal_values, i)
  end

  def convert_normalized_value_to_scale_value(normalized_value, %Scale{type: "numeric"} = scale) do
    normalized_value * (scale.stop - scale.start) + scale.start
  end

  defp get_normalized_value_breakpoint_index(breakpoints, normalized_value, i \\ 0)

  defp get_normalized_value_breakpoint_index([], _n_value, i), do: i

  defp get_normalized_value_breakpoint_index([breakpoint | _breakpoints], n_value, i)
       when n_value < breakpoint,
       do: i

  defp get_normalized_value_breakpoint_index([_breakpoint | breakpoints], n_value, i),
    do: get_normalized_value_breakpoint_index(breakpoints, n_value, i + 1)
end
