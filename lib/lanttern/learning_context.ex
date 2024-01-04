defmodule Lanttern.LearningContext do
  @moduledoc """
  The LearningContext context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  alias Lanttern.Repo

  alias Lanttern.LearningContext.Strand

  @doc """
  Returns the list of strands.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> list_strands()
      [%Strand{}, ...]

  """
  def list_strands(opts \\ []) do
    from(
      s in Strand,
      order_by: :name
    )
    |> Repo.all()
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single strand.

  Returns `nil` if the strand does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_strand(123)
      %Strand{}

      iex> get_strand(456)
      nil

  """
  def get_strand(id, opts \\ []) do
    Repo.get(Strand, id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single strand.

  Same as `get_strand/2`, but raises `Ecto.NoResultsError` if the strand does not exist.
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

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> update_strand(strand, %{field: new_value})
      {:ok, %Strand{}}

      iex> update_strand(strand, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_strand(%Strand{} = strand, attrs, opts \\ []) do
    strand
    |> Strand.changeset(attrs)
    |> Repo.update()
    |> maybe_preload(opts)
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
    strand
    |> Strand.delete_changeset()
    |> Repo.delete()
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

  alias Lanttern.LearningContext.Activity

  @doc """
  Returns the list of activities.

  ### Options:

  `:preloads` – preloads associated data
  `:strands_ids` – filter activities by strands

  ## Examples

      iex> list_activities()
      [%Activity{}, ...]

  """
  def list_activities(opts \\ []) do
    from(
      a in Activity,
      order_by: [asc: a.position]
    )
    |> maybe_filter_by_strands(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single activity.

  Returns `nil` if the Activity does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_activity!(123)
      %Activity{}

      iex> get_activity!(456)
      nil

  """
  def get_activity(id, opts \\ []) do
    Repo.get(Activity, id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single activity.

  Same as `get_activity/2`, but raises `Ecto.NoResultsError` if the Activity does not exist.

  """
  def get_activity!(id, opts \\ []) do
    Repo.get!(Activity, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a activity.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> create_activity(%{field: value})
      {:ok, %Activity{}}

      iex> create_activity(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_activity(attrs \\ %{}, opts \\ []) do
    attrs = set_activity_position_attr(attrs)

    %Activity{}
    |> Activity.changeset(attrs)
    |> Repo.insert()
    |> maybe_preload(opts)
  end

  defp set_activity_position_attr(%{"position" => _} = attrs), do: attrs

  defp set_activity_position_attr(%{position: _} = attrs), do: attrs

  defp set_activity_position_attr(attrs) do
    strand_id = attrs[:strand_id] || attrs["strand_id"]

    positions =
      from(
        a in Activity,
        where: a.strand_id == ^strand_id,
        select: a.position,
        order_by: [desc: a.position]
      )
      |> Repo.all()

    position =
      case Enum.at(positions, 0) do
        nil -> 0
        pos -> pos + 1
      end

    cond do
      not is_nil(attrs[:strand_id]) ->
        Map.put(attrs, :position, position)

      not is_nil(attrs["strand_id"]) ->
        Map.put(attrs, "position", position)
    end
  end

  @doc """
  Updates a activity.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> update_activity(activity, %{field: new_value})
      {:ok, %Activity{}}

      iex> update_activity(activity, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_activity(%Activity{} = activity, attrs, opts \\ []) do
    activity
    |> Activity.changeset(attrs)
    |> Repo.update()
    |> maybe_preload(opts)
  end

  @doc """
  Update strand activities positions based on ids list order.

  ## Examples

      iex> update_strand_activities_positions(strand_id, [3, 2, 1])
      {:ok, [%Activity{}, ...]}

  """
  def update_strand_activities_positions(strand_id, activities_ids) do
    activities_ids
    |> Enum.with_index()
    |> Enum.reduce(
      Ecto.Multi.new(),
      fn {id, i}, multi ->
        multi
        |> Ecto.Multi.update_all(
          "update-#{id}",
          from(
            a in Activity,
            where: a.id == ^id,
            where: a.strand_id == ^strand_id
          ),
          set: [position: i]
        )
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        {:ok, list_activities(strands_ids: [strand_id])}

      _ ->
        {:error, "Something went wrong"}
    end
  end

  @doc """
  Deletes a activity.

  ## Examples

      iex> delete_activity(activity)
      {:ok, %Activity{}}

      iex> delete_activity(activity)
      {:error, %Ecto.Changeset{}}

  """
  def delete_activity(%Activity{} = activity) do
    activity
    |> Activity.delete_changeset()
    |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking activity changes.

  ## Examples

      iex> change_activity(activity)
      %Ecto.Changeset{data: %Activity{}}

  """
  def change_activity(%Activity{} = activity, attrs \\ %{}) do
    Activity.changeset(activity, attrs)
  end

  # Helpers

  defp maybe_filter_by_strands(query, opts) do
    case Keyword.get(opts, :strands_ids) do
      nil ->
        query

      strands_ids ->
        from(
          q in query,
          where: q.strand_id in ^strands_ids
        )
    end
  end
end
