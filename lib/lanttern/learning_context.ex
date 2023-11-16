defmodule Lanttern.LearningContext do
  @moduledoc """
  The LearningContext context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.LearningContext.Strand
  import Lanttern.RepoHelpers

  @doc """
  Returns the list of strands.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> list_strands()
      [%Strand{}, ...]

  """
  def list_strands(opts \\ []) do
    Repo.all(Strand)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single strand.

  Raises `Ecto.NoResultsError` if the Strand does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_strand!(123)
      %Strand{}

      iex> get_strand!(456)
      ** (Ecto.NoResultsError)

  """
  def get_strand!(id, opts \\ []) do
    Repo.get!(Strand, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a strand.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> create_strand(%{field: value})
      {:ok, %Strand{}}

      iex> create_strand(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_strand(attrs \\ %{}, opts \\ []) do
    %Strand{}
    |> Strand.changeset(attrs)
    |> Repo.insert()
    |> maybe_preload(opts)
  end

  @doc """
  Updates a strand.

  ## Examples

      iex> update_strand(strand, %{field: new_value})
      {:ok, %Strand{}}

      iex> update_strand(strand, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_strand(%Strand{} = strand, attrs) do
    strand
    |> Strand.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a strand.

  ## Examples

      iex> delete_strand(strand)
      {:ok, %Strand{}}

      iex> delete_strand(strand)
      {:error, %Ecto.Changeset{}}

  """
  def delete_strand(%Strand{} = strand) do
    Repo.delete(strand)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking strand changes.

  ## Examples

      iex> change_strand(strand)
      %Ecto.Changeset{data: %Strand{}}

  """
  def change_strand(%Strand{} = strand, attrs \\ %{}) do
    Strand.changeset(strand, attrs)
  end
end
