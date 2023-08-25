defmodule Lanttern.Curricula do
  @moduledoc """
  The Curricula context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Curricula.Curriculum
  alias Lanttern.Curricula.CurriculumItem

  @doc """
  Returns the list of curricula.

  ## Examples

      iex> list_curricula()
      [%Curriculum{}, ...]

  """
  def list_curricula do
    Repo.all(Curriculum)
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

  alias Lanttern.Curricula.CurriculumComponent

  @doc """
  Returns the list of curriculum_components.

  ## Examples

      iex> list_curriculum_components()
      [%CurriculumComponent{}, ...]

  """
  def list_curriculum_components do
    Repo.all(CurriculumComponent)
  end

  @doc """
  Gets a single curriculum_component.

  Raises `Ecto.NoResultsError` if the Curriculum component does not exist.

  ## Examples

      iex> get_curriculum_component!(123)
      %CurriculumComponent{}

      iex> get_curriculum_component!(456)
      ** (Ecto.NoResultsError)

  """
  def get_curriculum_component!(id), do: Repo.get!(CurriculumComponent, id)

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

  ## Examples

      iex> list_curriculum_items()
      [%CurriculumItem{}, ...]

  """
  def list_curriculum_items do
    Repo.all(CurriculumItem)
  end

  @doc """
  Gets a single curriculum item.

  Raises `Ecto.NoResultsError` if the Curriculum Item does not exist.

  ## Examples

      iex> get_curriculum_item!(123)
      %CurriculumItem{}

      iex> get_curriculum_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_curriculum_item!(id), do: Repo.get!(CurriculumItem, id)

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
end
