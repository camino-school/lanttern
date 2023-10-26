defmodule Lanttern.Rubrics do
  @moduledoc """
  The Rubrics context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  alias Lanttern.Repo

  alias Lanttern.Rubrics.Rubric

  @doc """
  Returns the list of rubrics.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> list_rubrics()
      [%Rubric{}, ...]

  """
  def list_rubrics(opts \\ []) do
    Repo.all(Rubric)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single rubric.

  Raises `Ecto.NoResultsError` if the Rubric does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_rubric!(123)
      %Rubric{}

      iex> get_rubric!(456)
      ** (Ecto.NoResultsError)

  """
  def get_rubric!(id, opts \\ []) do
    Rubric
    |> Repo.get!(id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a rubric.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> create_rubric(%{field: value})
      {:ok, %Rubric{}}

      iex> create_rubric(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_rubric(attrs \\ %{}, opts \\ []) do
    %Rubric{}
    |> Rubric.changeset(attrs)
    |> Repo.insert()
    |> maybe_preload(opts)
  end

  @doc """
  Updates a rubric.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> update_rubric(rubric, %{field: new_value})
      {:ok, %Rubric{}}

      iex> update_rubric(rubric, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_rubric(%Rubric{} = rubric, attrs, opts \\ []) do
    rubric
    |> Rubric.changeset(attrs)
    |> Repo.update()
    |> maybe_preload(opts)
  end

  @doc """
  Deletes a rubric.

  ## Examples

      iex> delete_rubric(rubric)
      {:ok, %Rubric{}}

      iex> delete_rubric(rubric)
      {:error, %Ecto.Changeset{}}

  """
  def delete_rubric(%Rubric{} = rubric) do
    Repo.delete(rubric)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking rubric changes.

  ## Examples

      iex> change_rubric(rubric)
      %Ecto.Changeset{data: %Rubric{}}

  """
  def change_rubric(%Rubric{} = rubric, attrs \\ %{}) do
    Rubric.changeset(rubric, attrs)
  end
end
