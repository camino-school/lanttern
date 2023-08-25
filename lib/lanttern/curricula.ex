defmodule Lanttern.Curricula do
  @moduledoc """
  The Curricula context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Curricula.Item

  @doc """
  Returns the list of items.

  ## Examples

      iex> list_items()
      [%Item{}, ...]

  """
  def list_items do
    Repo.all(Item)
  end

  @doc """
  Gets a single item.

  Raises `Ecto.NoResultsError` if the Item does not exist.

  ## Examples

      iex> get_item!(123)
      %Item{}

      iex> get_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_item!(id), do: Repo.get!(Item, id)

  @doc """
  Creates a item.

  ## Examples

      iex> create_item(%{field: value})
      {:ok, %Item{}}

      iex> create_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_item(attrs \\ %{}) do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a item.

  ## Examples

      iex> update_item(item, %{field: new_value})
      {:ok, %Item{}}

      iex> update_item(item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_item(%Item{} = item, attrs) do
    item
    |> Item.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a item.

  ## Examples

      iex> delete_item(item)
      {:ok, %Item{}}

      iex> delete_item(item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking item changes.

  ## Examples

      iex> change_item(item)
      %Ecto.Changeset{data: %Item{}}

  """
  def change_item(%Item{} = item, attrs \\ %{}) do
    Item.changeset(item, attrs)
  end

  alias Lanttern.Curricula.Curriculum

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
end
