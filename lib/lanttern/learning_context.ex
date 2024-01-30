defmodule Lanttern.LearningContext do
  @moduledoc """
  The LearningContext context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  import LantternWeb.Gettext
  alias Lanttern.Repo

  alias Lanttern.LearningContext.Strand
  alias Lanttern.LearningContext.StarredStrand
  alias Lanttern.LearningContext.Moment
  alias Lanttern.LearningContext.MomentCard

  @doc """
  Returns the list of strands ordered alphabetically.

  ### Options:

      - `:subjects_ids` – filter strands by subjects
      - `:years_ids` – filter strands by years
      - `:first` – number of results after cursor. defaults to 10
      - `:after` – the cursor to list results after
      - `:preloads` – preloads associated data
      - `:show_starred_for_profile_id` - handles `is_starred` field

  ## Examples

      iex> list_strands()
      {[%Strand{}, ...], %Flop.Meta{}}

  """
  def list_strands(opts \\ []) do
    params = %{
      order_by: [:name],
      first: Keyword.get(opts, :first, 10),
      after: Keyword.get(opts, :after)
    }

    {:ok, {results, meta}} =
      from(s in Strand)
      |> filter_strands(opts)
      |> handle_is_starred(Keyword.get(opts, :show_starred_for_profile_id))
      |> Flop.validate_and_run(params)

    {results |> maybe_preload(opts), meta}
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

  @doc """
  Returns the list of profile starred strands ordered alphabetically.

  ### Options:
      - `:subjects_ids` – filter strands by subjects
      - `:years_ids` – filter strands by years
      - `:preloads` – preloads associated data

  ## Examples

      iex> list_starred_strands(profile_id)
      [%Strand{}, ...]

  """
  def list_starred_strands(profile_id, opts \\ []) do
    strands_query =
      from(
        s in Strand,
        order_by: s.name
      )
      |> filter_strands(opts)

    from(
      s in strands_query,
      join: ss in StarredStrand,
      on: ss.strand_id == s.id,
      where: ss.profile_id == ^profile_id,
      select: %{s | is_starred: true}
    )
    |> Repo.all()
    |> maybe_preload(opts)
  end

  @doc """
  Marks the strand as starred for the given profile.

  ## Examples

      iex> star_strand(strand_id, profile_id)
      {:ok, %StarredStrand{}}

      iex> star_strand(bad_strand_id, profile_id)
      {:error, %Ecto.Changeset{}}

  """
  def star_strand(strand_id, profile_id) do
    case Repo.get_by(StarredStrand, strand_id: strand_id, profile_id: profile_id) do
      nil ->
        %StarredStrand{}
        |> StarredStrand.changeset(%{strand_id: strand_id, profile_id: profile_id})
        |> Repo.insert()

      starred_strand ->
        {:ok, starred_strand}
    end
  end

  @doc """
  Removes the strand from profile starred strands.

  ## Examples

      iex> unstar_strand(strand_id, profile_id)
      {:ok, %StarredStrand{}}

      iex> unstar_strand(bad_strand_id, profile_id)
      {:error, %Ecto.Changeset{}}

  """
  def unstar_strand(strand_id, profile_id) do
    Repo.get_by(StarredStrand, strand_id: strand_id, profile_id: profile_id)
    |> Repo.delete()
  end

  @doc """
  Returns the list of moments.

  ### Options:

      - `:preloads` – preloads associated data
      - `:strands_ids` – filter moments by strands

  ## Examples

      iex> list_moments()
      [%Moment{}, ...]

  """
  def list_moments(opts \\ []) do
    from(
      m in Moment,
      order_by: [asc: m.position]
    )
    |> maybe_filter_by_strands(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

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

  @doc """
  Gets a single moment.

  Returns `nil` if the Moment does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_moment!(123)
      %Moment{}

      iex> get_moment!(456)
      nil

  """
  def get_moment(id, opts \\ []) do
    Repo.get(Moment, id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single moment.

  Same as `get_moment/2`, but raises `Ecto.NoResultsError` if the Moment does not exist.

  """
  def get_moment!(id, opts \\ []) do
    Repo.get!(Moment, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a moment.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> create_moment(%{field: value})
      {:ok, %Moment{}}

      iex> create_moment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_moment(attrs \\ %{}, opts \\ []) do
    attrs = set_moment_position_attr(attrs)

    %Moment{}
    |> Moment.changeset(attrs)
    |> Repo.insert()
    |> maybe_preload(opts)
  end

  defp set_moment_position_attr(%{"position" => _} = attrs), do: attrs

  defp set_moment_position_attr(%{position: _} = attrs), do: attrs

  defp set_moment_position_attr(attrs) do
    strand_id = attrs[:strand_id] || attrs["strand_id"]

    positions =
      from(
        m in Moment,
        where: m.strand_id == ^strand_id,
        select: m.position,
        order_by: [desc: m.position]
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
  Updates a moment.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> update_moment(moment, %{field: new_value})
      {:ok, %Moment{}}

      iex> update_moment(moment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_moment(%Moment{} = moment, attrs, opts \\ []) do
    moment
    |> Moment.changeset(attrs)
    |> Repo.update()
    |> maybe_preload(opts)
  end

  @doc """
  Update strand moments positions based on ids list order.

  ## Examples

      iex> update_strand_moments_positions(strand_id, [3, 2, 1])
      {:ok, [%Moment{}, ...]}

  """
  def update_strand_moments_positions(strand_id, moments_ids) do
    moments_ids
    |> Enum.with_index()
    |> Enum.reduce(
      Ecto.Multi.new(),
      fn {id, i}, multi ->
        multi
        |> Ecto.Multi.update_all(
          "update-#{id}",
          from(
            m in Moment,
            where: m.id == ^id,
            where: m.strand_id == ^strand_id
          ),
          set: [position: i]
        )
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        {:ok, list_moments(strands_ids: [strand_id])}

      _ ->
        {:error, gettext("Something went wrong")}
    end
  end

  @doc """
  Deletes a moment.

  ## Examples

      iex> delete_moment(moment)
      {:ok, %Moment{}}

      iex> delete_moment(moment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_moment(%Moment{} = moment) do
    moment
    |> Moment.delete_changeset()
    |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking moment changes.

  ## Examples

      iex> change_moment(moment)
      %Ecto.Changeset{data: %Moment{}}

  """
  def change_moment(%Moment{} = moment, attrs \\ %{}) do
    Moment.changeset(moment, attrs)
  end

  @doc """
  Returns the list of moment_cards.

  ## Examples

      iex> list_moment_cards()
      [%MomentCard{}, ...]

  """
  def list_moment_cards do
    Repo.all(MomentCard)
  end

  @doc """
  Gets a single moment_card.

  Raises `Ecto.NoResultsError` if the Moment card does not exist.

  ## Examples

      iex> get_moment_card!(123)
      %MomentCard{}

      iex> get_moment_card!(456)
      ** (Ecto.NoResultsError)

  """
  def get_moment_card!(id), do: Repo.get!(MomentCard, id)

  @doc """
  Creates a moment_card.

  ## Examples

      iex> create_moment_card(%{field: value})
      {:ok, %MomentCard{}}

      iex> create_moment_card(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_moment_card(attrs \\ %{}) do
    %MomentCard{}
    |> MomentCard.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a moment_card.

  ## Examples

      iex> update_moment_card(moment_card, %{field: new_value})
      {:ok, %MomentCard{}}

      iex> update_moment_card(moment_card, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_moment_card(%MomentCard{} = moment_card, attrs) do
    moment_card
    |> MomentCard.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a moment_card.

  ## Examples

      iex> delete_moment_card(moment_card)
      {:ok, %MomentCard{}}

      iex> delete_moment_card(moment_card)
      {:error, %Ecto.Changeset{}}

  """
  def delete_moment_card(%MomentCard{} = moment_card) do
    Repo.delete(moment_card)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking moment_card changes.

  ## Examples

      iex> change_moment_card(moment_card)
      %Ecto.Changeset{data: %MomentCard{}}

  """
  def change_moment_card(%MomentCard{} = moment_card, attrs \\ %{}) do
    MomentCard.changeset(moment_card, attrs)
  end

  # Helpers

  defp filter_strands(strands_query, opts) do
    Enum.reduce(opts, strands_query, &apply_strands_filter/2)
  end

  defp apply_strands_filter({:subjects_ids, subjects_ids}, strands_query)
       when subjects_ids != [] do
    from(
      s in strands_query,
      join: sub in assoc(s, :subjects),
      where: sub.id in ^subjects_ids
    )
  end

  defp apply_strands_filter({:years_ids, years_ids}, strands_query) when years_ids != [] do
    from(
      s in strands_query,
      join: y in assoc(s, :years),
      where: y.id in ^years_ids
    )
  end

  defp apply_strands_filter(_opt, query), do: query

  defp handle_is_starred(strands_query, nil), do: strands_query

  defp handle_is_starred(strands_query, profile_id) do
    from(
      s in strands_query,
      left_join: ss in StarredStrand,
      on: ss.profile_id == ^profile_id and ss.strand_id == s.id,
      select: %{s | is_starred: not is_nil(ss)}
    )
  end
end
