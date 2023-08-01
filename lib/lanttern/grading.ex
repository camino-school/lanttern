defmodule Lanttern.Grading do
  @moduledoc """
  The Grading context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Grading.Composition
  alias Lanttern.Grading.CompositionComponent

  @doc """
  Returns the list of compositions.

  ## Examples

      iex> list_compositions()
      [%Composition{}, ...]

  """
  def list_compositions do
    Repo.all(Composition)
  end

  @doc """
  Gets a single composition.

  Raises `Ecto.NoResultsError` if the Composition does not exist.

  ## Examples

      iex> get_composition!(123)
      %Composition{}

      iex> get_composition!(456)
      ** (Ecto.NoResultsError)

  """
  def get_composition!(id), do: Repo.get!(Composition, id)

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

  alias Lanttern.Grading.CompositionComponentItem

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

  alias Lanttern.Grading.NumericScale

  @doc """
  Returns the list of numeric_scales.

  ## Examples

      iex> list_numeric_scales()
      [%NumericScale{}, ...]

  """
  def list_numeric_scales do
    Repo.all(NumericScale)
  end

  @doc """
  Gets a single numeric_scale.

  Raises `Ecto.NoResultsError` if the Numeric scale does not exist.

  ## Examples

      iex> get_numeric_scale!(123)
      %NumericScale{}

      iex> get_numeric_scale!(456)
      ** (Ecto.NoResultsError)

  """
  def get_numeric_scale!(id), do: Repo.get!(NumericScale, id)

  @doc """
  Creates a numeric_scale.

  ## Examples

      iex> create_numeric_scale(%{field: value})
      {:ok, %NumericScale{}}

      iex> create_numeric_scale(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_numeric_scale(attrs \\ %{}) do
    %NumericScale{}
    |> NumericScale.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a numeric_scale.

  ## Examples

      iex> update_numeric_scale(numeric_scale, %{field: new_value})
      {:ok, %NumericScale{}}

      iex> update_numeric_scale(numeric_scale, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_numeric_scale(%NumericScale{} = numeric_scale, attrs) do
    numeric_scale
    |> NumericScale.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a numeric_scale.

  ## Examples

      iex> delete_numeric_scale(numeric_scale)
      {:ok, %NumericScale{}}

      iex> delete_numeric_scale(numeric_scale)
      {:error, %Ecto.Changeset{}}

  """
  def delete_numeric_scale(%NumericScale{} = numeric_scale) do
    Repo.delete(numeric_scale)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking numeric_scale changes.

  ## Examples

      iex> change_numeric_scale(numeric_scale)
      %Ecto.Changeset{data: %NumericScale{}}

  """
  def change_numeric_scale(%NumericScale{} = numeric_scale, attrs \\ %{}) do
    NumericScale.changeset(numeric_scale, attrs)
  end

  alias Lanttern.Grading.OrdinalScale

  @doc """
  Returns the list of ordinal_scales.

  ## Examples

      iex> list_ordinal_scales()
      [%OrdinalScale{}, ...]

  """
  def list_ordinal_scales do
    Repo.all(OrdinalScale)
  end

  @doc """
  Gets a single ordinal_scale.

  Raises `Ecto.NoResultsError` if the Ordinal scale does not exist.

  ## Examples

      iex> get_ordinal_scale!(123)
      %OrdinalScale{}

      iex> get_ordinal_scale!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ordinal_scale!(id), do: Repo.get!(OrdinalScale, id)

  @doc """
  Creates a ordinal_scale.

  ## Examples

      iex> create_ordinal_scale(%{field: value})
      {:ok, %OrdinalScale{}}

      iex> create_ordinal_scale(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ordinal_scale(attrs \\ %{}) do
    %OrdinalScale{}
    |> OrdinalScale.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ordinal_scale.

  ## Examples

      iex> update_ordinal_scale(ordinal_scale, %{field: new_value})
      {:ok, %OrdinalScale{}}

      iex> update_ordinal_scale(ordinal_scale, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ordinal_scale(%OrdinalScale{} = ordinal_scale, attrs) do
    ordinal_scale
    |> OrdinalScale.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ordinal_scale.

  ## Examples

      iex> delete_ordinal_scale(ordinal_scale)
      {:ok, %OrdinalScale{}}

      iex> delete_ordinal_scale(ordinal_scale)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ordinal_scale(%OrdinalScale{} = ordinal_scale) do
    Repo.delete(ordinal_scale)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ordinal_scale changes.

  ## Examples

      iex> change_ordinal_scale(ordinal_scale)
      %Ecto.Changeset{data: %OrdinalScale{}}

  """
  def change_ordinal_scale(%OrdinalScale{} = ordinal_scale, attrs \\ %{}) do
    OrdinalScale.changeset(ordinal_scale, attrs)
  end

  alias Lanttern.Grading.OrdinalValue

  @doc """
  Returns the list of ordinal_values.
  Optionally preloads associated data.

  ## Examples

      iex> list_ordinal_values()
      [%OrdinalValue{}, ...]

  """
  def list_ordinal_values(preloads \\ []) do
    Repo.all(OrdinalValue)
    |> Repo.preload(preloads)
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
end
