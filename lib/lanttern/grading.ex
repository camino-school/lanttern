defmodule Lanttern.Grading do
  @moduledoc """
  The Grading context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Grading.Composition

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

  alias Lanttern.Grading.CompositionComponent

  @doc """
  Returns the list of grade_composition_components.

  ## Examples

      iex> list_grade_composition_components()
      [%CompositionComponent{}, ...]

  """
  def list_grade_composition_components do
    Repo.all(CompositionComponent)
  end

  @doc """
  Gets a single composition_component.

  Raises `Ecto.NoResultsError` if the Composition component does not exist.

  ## Examples

      iex> get_composition_component!(123)
      %CompositionComponent{}

      iex> get_composition_component!(456)
      ** (Ecto.NoResultsError)

  """
  def get_composition_component!(id), do: Repo.get!(CompositionComponent, id)

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
end
