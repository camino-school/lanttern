defmodule Lanttern.Strands do
  @moduledoc """
  The Strands context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Identity.Scope
  alias Lanttern.Strands.StrandCurriculumItem

  @doc """
  Subscribes to scoped notifications about any strand_curriculum_item changes.

  The broadcasted messages match the pattern:

    * {:created, %StrandCurriculumItem{}}
    * {:updated, %StrandCurriculumItem{}}
    * {:deleted, %StrandCurriculumItem{}}

  """
  def subscribe_strand_curriculum_items(%Scope{} = scope) do
    key = scope.school_id

    Phoenix.PubSub.subscribe(Lanttern.PubSub, "school:#{key}:strand_curriculum_items")
  end

  defp broadcast_strand_curriculum_item(%Scope{} = scope, message) do
    key = scope.school_id

    Phoenix.PubSub.broadcast(Lanttern.PubSub, "school:#{key}:strand_curriculum_items", message)
  end

  @doc """
  Returns the list of strand_curriculum_items.

  ## Examples

      iex> list_strand_curriculum_items(scope)
      [%StrandCurriculumItem{}, ...]

  """
  def list_strand_curriculum_items(%Scope{} = _scope) do
    Repo.all(StrandCurriculumItem)
  end

  @doc """
  Gets a single strand_curriculum_item.

  Raises `Ecto.NoResultsError` if the Strand curriculum item does not exist.

  ## Examples

      iex> get_strand_curriculum_item!(scope, 123)
      %StrandCurriculumItem{}

      iex> get_strand_curriculum_item!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_strand_curriculum_item!(%Scope{} = _scope, id) do
    Repo.get!(StrandCurriculumItem, id)
  end

  @doc """
  Creates a strand_curriculum_item.

  ## Examples

      iex> create_strand_curriculum_item(scope, %{field: value})
      {:ok, %StrandCurriculumItem{}}

      iex> create_strand_curriculum_item(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_strand_curriculum_item(%Scope{} = scope, attrs) do
    true = Scope.profile_type?(scope, "staff")

    with {:ok, strand_curriculum_item = %StrandCurriculumItem{}} <-
           %StrandCurriculumItem{}
           |> StrandCurriculumItem.changeset(attrs)
           |> Repo.insert() do
      broadcast_strand_curriculum_item(scope, {:created, strand_curriculum_item})
      {:ok, strand_curriculum_item}
    end
  end

  @doc """
  Updates a strand_curriculum_item.

  ## Examples

      iex> update_strand_curriculum_item(scope, strand_curriculum_item, %{field: new_value})
      {:ok, %StrandCurriculumItem{}}

      iex> update_strand_curriculum_item(scope, strand_curriculum_item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_strand_curriculum_item(
        %Scope{} = scope,
        %StrandCurriculumItem{} = strand_curriculum_item,
        attrs
      ) do
    true = Scope.profile_type?(scope, "staff")

    with {:ok, strand_curriculum_item = %StrandCurriculumItem{}} <-
           strand_curriculum_item
           |> StrandCurriculumItem.changeset(attrs)
           |> Repo.update() do
      broadcast_strand_curriculum_item(scope, {:updated, strand_curriculum_item})
      {:ok, strand_curriculum_item}
    end
  end

  @doc """
  Deletes a strand_curriculum_item.

  ## Examples

      iex> delete_strand_curriculum_item(scope, strand_curriculum_item)
      {:ok, %StrandCurriculumItem{}}

      iex> delete_strand_curriculum_item(scope, strand_curriculum_item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_strand_curriculum_item(
        %Scope{} = scope,
        %StrandCurriculumItem{} = strand_curriculum_item
      ) do
    true = Scope.profile_type?(scope, "staff")

    with {:ok, strand_curriculum_item = %StrandCurriculumItem{}} <-
           Repo.delete(strand_curriculum_item) do
      broadcast_strand_curriculum_item(scope, {:deleted, strand_curriculum_item})
      {:ok, strand_curriculum_item}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking strand_curriculum_item changes.

  ## Examples

      iex> change_strand_curriculum_item(scope, strand_curriculum_item)
      %Ecto.Changeset{data: %StrandCurriculumItem{}}

  """
  def change_strand_curriculum_item(
        %Scope{} = _scope,
        %StrandCurriculumItem{} = strand_curriculum_item,
        attrs \\ %{}
      ) do
    StrandCurriculumItem.changeset(strand_curriculum_item, attrs)
  end
end
