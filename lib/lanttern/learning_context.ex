defmodule Lanttern.LearningContext do
  @moduledoc """
  The LearningContext context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  import LantternWeb.Gettext
  alias Lanttern.Repo

  alias Lanttern.Assessments.AssessmentPointEntry
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
      from(
        s in Strand,
        distinct: [asc: s.name, asc: s.id]
      )
      |> filter_strands(opts)
      |> handle_is_starred(Keyword.get(opts, :show_starred_for_profile_id))
      |> Flop.validate_and_run(params)

    {results |> maybe_preload(opts), meta}
  end

  @doc """
  Returns the list of strands linked to the student with
  linked moments entries.

  Strands are "linked to the student" through report cards:

      strand -> strand report -> report card -> student report card

  Strands results are ordered by cycle (desc), then by strand report position.
  Entries are ordered by moment position, then by assessment point position.

  Preloads subjects, years, and report cycle.

  The same strand can appear more than once, because it can
  be linked to more than one report card at the same time.
  The `report_card_id` and `report_cycle` can help differentiate them.

  ## Options:

  - `:cycles_ids` - filter results by given cycles, using the report card cycle

  ## Examples

      iex> list_student_strands(1)
      [{%Strand{}, [%AssessmentPointEntry{}, ...]}, ...]

  """
  @spec list_student_strands(student_id :: pos_integer(), opts :: Keyword.t()) :: [
          {Strand.t(), [AssessmentPointEntry.t()]}
        ]
  def list_student_strands(student_id, opts \\ []) do
    student_strands =
      from(
        s in Strand,
        left_join: sub in assoc(s, :subjects),
        left_join: y in assoc(s, :years),
        join: sr in assoc(s, :strand_reports),
        join: rc in assoc(sr, :report_card),
        join: c in assoc(rc, :school_cycle),
        as: :cycles,
        join: src in assoc(rc, :students_report_cards),
        order_by: [desc: c.end_at, asc: c.start_at, asc: sr.position],
        where: src.student_id == ^student_id,
        preload: [subjects: sub, years: y],
        select: %{s | strand_report_id: sr.id, report_cycle: c}
      )
      |> apply_list_student_strands_opts(opts)
      |> Repo.all()

    student_strands_ids =
      student_strands
      |> Enum.map(& &1.id)

    student_strands_entries_map =
      from(
        e in AssessmentPointEntry,
        join: ap in assoc(e, :assessment_point),
        join: m in assoc(ap, :moment),
        where: m.strand_id in ^student_strands_ids,
        where: e.student_id == ^student_id,
        order_by: [asc: m.position, asc: ap.position],
        select: {e, m.strand_id}
      )
      |> Repo.all()
      |> Enum.group_by(
        fn {_entry, strand_id} -> strand_id end,
        fn {entry, _strand_id} -> entry end
      )

    student_strands
    |> Enum.map(&{&1, Map.get(student_strands_entries_map, &1.id, [])})
  end

  defp apply_list_student_strands_opts(queryable, []), do: queryable

  defp apply_list_student_strands_opts(queryable, [{:cycles_ids, cycles_ids} | opts])
       when cycles_ids != [] do
    from(
      [_s, cycles: c] in queryable,
      where: c.id in ^cycles_ids
    )
    |> apply_list_student_strands_opts(opts)
  end

  defp apply_list_student_strands_opts(queryable, [_opt | opts]),
    do: apply_list_student_strands_opts(queryable, opts)

  @doc """
  Returns the list of strands linked to the given report card.

  Results are ordered by strand report position.

  ## Examples

      iex> list_report_card_strands(report_card_id)
      [%Strand{}, ...]

  """
  @spec list_report_card_strands(report_card_id :: pos_integer()) :: [Strand.t()]
  def list_report_card_strands(report_card_id) do
    from(
      s in Strand,
      join: sr in assoc(s, :strand_reports),
      left_join: m in assoc(s, :moments),
      left_join: ap in assoc(m, :assessment_points),
      where: sr.report_card_id == ^report_card_id,
      order_by: sr.position,
      group_by: [s.id, sr.position],
      select: %{s | assessment_points_count: count(ap)}
    )
    |> Repo.all()
  end

  @doc """
  Search strands by name.

  ## Options

      `:preloads` – preloads associated data

  ## Examples

      iex> search_strands()
      [%Strand{}, ...]

  """
  def search_strands(search_term, opts \\ []) do
    ilike_search_term = "%#{search_term}%"

    from(
      s in Strand,
      where: ilike(s.name, ^ilike_search_term),
      order_by: {:asc, fragment("? <<-> ?", ^search_term, s.name)}
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
        distinct: [asc: s.name, asc: s.id]
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
    %Moment{}
    |> Moment.changeset(attrs)
    |> set_moment_position()
    |> Repo.insert()
    |> maybe_preload(opts)
  end

  # skip if not valid
  defp set_moment_position(%Ecto.Changeset{valid?: false} = changeset),
    do: changeset

  # skip if changeset already has position change
  defp set_moment_position(%Ecto.Changeset{changes: %{position: _position}} = changeset),
    do: changeset

  defp set_moment_position(%Ecto.Changeset{} = changeset) do
    strand_id =
      Ecto.Changeset.get_field(changeset, :strand_id)

    position =
      from(
        m in Moment,
        where: m.strand_id == ^strand_id,
        select: m.position,
        order_by: [desc: m.position],
        limit: 1
      )
      |> Repo.one()
      |> case do
        nil -> 0
        pos -> pos + 1
      end

    changeset
    |> Ecto.Changeset.put_change(:position, position)
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

  ## Options:

        - `:ids` – filter cards by ids
        - `:moments_ids` – filter cards by moment

  ## Examples

      iex> list_moment_cards()
      [%MomentCard{}, ...]

  """
  def list_moment_cards(opts \\ []) do
    from(
      c in MomentCard,
      order_by: c.position
    )
    |> filter_moment_cards(opts)
    |> Repo.all()
  end

  defp filter_moment_cards(queryable, opts) do
    Enum.reduce(opts, queryable, &apply_moment_cards_filter/2)
  end

  defp apply_moment_cards_filter({:ids, ids}, queryable),
    do: from(c in queryable, where: c.id in ^ids)

  defp apply_moment_cards_filter({:moments_ids, ids}, queryable),
    do: from(c in queryable, where: c.moment_id in ^ids)

  defp apply_moment_cards_filter(_, queryable), do: queryable

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
    |> set_moment_card_position()
    |> Repo.insert()
  end

  # skip if not valid
  defp set_moment_card_position(%Ecto.Changeset{valid?: false} = changeset),
    do: changeset

  # skip if changeset already has position change
  defp set_moment_card_position(%Ecto.Changeset{changes: %{position: _position}} = changeset),
    do: changeset

  defp set_moment_card_position(%Ecto.Changeset{} = changeset) do
    moment_id =
      Ecto.Changeset.get_field(changeset, :moment_id)

    position =
      from(
        c in MomentCard,
        where: c.moment_id == ^moment_id,
        select: c.position,
        order_by: [desc: c.position],
        limit: 1
      )
      |> Repo.one()
      |> case do
        nil -> 0
        pos -> pos + 1
      end

    changeset
    |> Ecto.Changeset.put_change(:position, position)
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
  Update moment cards positions based on ids list order.

  ## Examples

      iex> update_moment_cards_positions([3, 2, 1])
      {:ok, [%AssessmentPoint{}, ...]}

  """
  def update_moment_cards_positions(moment_cards_ids) do
    moment_cards_ids
    |> Enum.with_index()
    |> Enum.reduce(
      Ecto.Multi.new(),
      fn {id, i}, multi ->
        multi
        |> Ecto.Multi.update_all(
          "update-#{id}",
          from(
            c in MomentCard,
            where: c.id == ^id
          ),
          set: [position: i]
        )
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        {:ok, list_moment_cards(ids: moment_cards_ids)}

      _ ->
        {:error, "Something went wrong"}
    end
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
