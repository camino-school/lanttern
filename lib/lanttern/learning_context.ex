defmodule Lanttern.LearningContext do
  @moduledoc """
  The LearningContext context.
  """

  import Ecto.Query, warn: false
  use Gettext, backend: Lanttern.Gettext

  alias Lanttern.Repo
  alias Lanttern.RepoHelpers.Page
  import Lanttern.RepoHelpers

  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Attachments
  alias Lanttern.Attachments.Attachment
  alias Lanttern.LearningContext.Moment
  alias Lanttern.LearningContext.MomentCard
  alias Lanttern.LearningContext.MomentCardAttachment
  alias Lanttern.LearningContext.StarredStrand
  alias Lanttern.LearningContext.Strand
  alias Lanttern.LearningContextLog

  @doc """
  Returns the list of strands ordered alphabetically.

  ## Options

  - `:subjects_ids` – filter strands by subjects
  - `:years_ids` – filter strands by years
  - `:cycles_ids` – filter strands by cycle, using linked report cards to determine the relationship between strands and cycles
  - `:parent_cycle_id` – same as `cycles_ids`, but will use report cards' parent cycle
  - `:show_starred_for_profile_id` - handles `is_starred` field
  - `:only_starred` - requires `show_starred_for_profile_id`. List only profile starred strands
  - `:preloads` – preloads associated data
  - page opts (view `Page.opts()`)

  ## Examples

      iex> list_strands()
      [%Strand{}, ...]

  """
  @type list_strands_opts ::
          [
            subjects_ids: [pos_integer()],
            years_ids: [pos_integer()],
            cycles_ids: [pos_integer()],
            parent_cycle_id: pos_integer(),
            show_starred_for_profile_id: pos_integer(),
            only_starred: boolean(),
            preloads: list()
          ]
          | Page.opts()
  @spec list_strands(list_strands_opts()) :: [Strand.t()]
  def list_strands(opts \\ []) do
    from(
      s in Strand,
      distinct: [asc: s.name, asc: s.id],
      order_by: [asc: s.name]
    )
    |> apply_list_strands_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_strands_opts(queryable, []), do: queryable

  defp apply_list_strands_opts(queryable, [{:subjects_ids, subjects_ids} | opts])
       when is_list(subjects_ids) and subjects_ids != [] do
    from(
      s in queryable,
      join: sub in assoc(s, :subjects),
      where: sub.id in ^subjects_ids
    )
    |> apply_list_strands_opts(opts)
  end

  defp apply_list_strands_opts(queryable, [{:years_ids, years_ids} | opts])
       when is_list(years_ids) and years_ids != [] do
    from(
      s in queryable,
      join: y in assoc(s, :years),
      where: y.id in ^years_ids
    )
    |> apply_list_strands_opts(opts)
  end

  defp apply_list_strands_opts(queryable, [{:cycles_ids, cycles_ids} | opts])
       when is_list(cycles_ids) and cycles_ids != [] do
    queryable = bind_cycles_to_strands(queryable)

    from(
      [s, cycles: c] in queryable,
      where: c.id in ^cycles_ids
    )
    |> apply_list_strands_opts(opts)
  end

  defp apply_list_strands_opts(queryable, [{:parent_cycle_id, parent_cycle_id} | opts])
       when is_integer(parent_cycle_id) do
    queryable = bind_cycles_to_strands(queryable)

    from(
      [s, cycles: c] in queryable,
      where: c.parent_cycle_id == ^parent_cycle_id
    )
    |> apply_list_strands_opts(opts)
  end

  defp apply_list_strands_opts(queryable, [{:show_starred_for_profile_id, profile_id} | opts]) do
    condition =
      if Keyword.get(opts, :only_starred) == true do
        dynamic([starred_strands: ss], not is_nil(ss))
      else
        true
      end

    from(
      s in queryable,
      left_join: ss in StarredStrand,
      on: ss.profile_id == ^profile_id and ss.strand_id == s.id,
      as: :starred_strands,
      select: %{s | is_starred: not is_nil(ss)},
      where: ^condition
    )
    |> apply_list_strands_opts(opts)
  end

  defp apply_list_strands_opts(queryable, [{:first, first} | opts]) do
    from(s in queryable, limit: ^first + 1)
    |> apply_list_strands_opts(opts)
  end

  defp apply_list_strands_opts(queryable, [
         {:after, [name: name, id: id]} | opts
       ]) do
    from(
      s in queryable,
      where: s.name > ^name or (s.name == ^name and s.id > ^id)
    )
    |> apply_list_strands_opts(opts)
  end

  defp apply_list_strands_opts(queryable, [_ | opts]),
    do: apply_list_strands_opts(queryable, opts)

  defp bind_cycles_to_strands(queryable) do
    if has_named_binding?(queryable, :cycles) do
      queryable
    else
      from(
        s in queryable,
        join: sr in assoc(s, :strand_reports),
        join: rc in assoc(sr, :report_card),
        join: c in assoc(rc, :school_cycle),
        as: :cycles
      )
    end
  end

  @doc """
  Returns a page with the list of strands.

  Sets the `first` default to 100.

  Keyset for this query is `[:name, :id]`.

  Same as `list_strands/1`, but returned in a `%Page{}` struct.
  """
  @spec list_strands_page(list_strands_opts()) :: Page.t()
  def list_strands_page(opts \\ []) do
    # set default for first opt
    first = Keyword.get(opts, :first, 100)
    opts = Keyword.put(opts, :first, first)

    strands = list_strands(opts)

    {results, has_next, keyset} =
      Page.extract_pagination_fields_from(
        strands,
        first,
        fn last -> [name: last.name, id: last.id] end
      )

    %Page{results: results, keyset: keyset, has_next: has_next}
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
        # exclude empty entries and entries where there are only student self-assessments
        where: e.has_marking,
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

  ## Options:

  - `:show_starred_for_profile_id` - handles `is_starred` field
  - `:preloads` – preloads associated data

  ## Examples

      iex> get_strand(123)
      %Strand{}

      iex> get_strand(456)
      nil

  """
  def get_strand(id, opts \\ []) do
    Strand
    |> apply_get_strand_opts(opts)
    |> Repo.get(id)
    |> maybe_preload(opts)
  end

  defp apply_get_strand_opts(queryable, []), do: queryable

  defp apply_get_strand_opts(queryable, [{:show_starred_for_profile_id, profile_id} | opts]) do
    from(
      s in queryable,
      left_join: ss in StarredStrand,
      on: ss.profile_id == ^profile_id and ss.strand_id == s.id,
      select: %{s | is_starred: not is_nil(ss)}
    )
    |> apply_get_strand_opts(opts)
  end

  defp apply_get_strand_opts(queryable, [_ | opts]),
    do: apply_get_strand_opts(queryable, opts)

  @doc """
  Gets a single strand.

  Same as `get_strand/2`, but raises `Ecto.NoResultsError` if the strand does not exist.
  """
  def get_strand!(id, opts \\ []) do
    Strand
    |> apply_get_strand_opts(opts)
    |> Repo.get!(id)
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
  Update moments positions based on ids list order.

  ## Examples

      iex> update_moments_positions([3, 2, 1])
      :ok

  """
  def update_moments_positions(moments_ids),
    do: update_positions(Moment, moments_ids)

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
  - `:school_id` – filter cards by school
  - `:count_attachments` – (boolean) calculate virtual `attachments_count` field

  ## Examples

      iex> list_moment_cards()
      [%MomentCard{}, ...]

  """
  def list_moment_cards(opts \\ []) do
    from(
      mc in MomentCard,
      order_by: mc.position
    )
    |> apply_list_moment_cards_opts(opts)
    |> Repo.all()
  end

  defp apply_list_moment_cards_opts(queryable, []), do: queryable

  defp apply_list_moment_cards_opts(queryable, [{:ids, ids} | opts]) do
    from(mc in queryable, where: mc.id in ^ids)
    |> apply_list_moment_cards_opts(opts)
  end

  defp apply_list_moment_cards_opts(queryable, [{:moments_ids, ids} | opts]) do
    from(mc in queryable, where: mc.moment_id in ^ids)
    |> apply_list_moment_cards_opts(opts)
  end

  defp apply_list_moment_cards_opts(queryable, [{:school_id, id} | opts]) do
    from(mc in queryable, where: mc.school_id == ^id)
    |> apply_list_moment_cards_opts(opts)
  end

  defp apply_list_moment_cards_opts(queryable, [{:count_attachments, true} | opts]) do
    from(
      mc in queryable,
      left_join: mca in assoc(mc, :moment_card_attachments),
      group_by: mc.id,
      select: %{mc | attachments_count: count(mca.id)}
    )
    |> apply_list_moment_cards_opts(opts)
  end

  defp apply_list_moment_cards_opts(queryable, [_ | opts]),
    do: apply_list_moment_cards_opts(queryable, opts)

  @doc """
  Gets a single moment_card.

  Returns `nil` if the Moment card does not exist.

  ## Options:

  - `:count_attachments` – (boolean) calculate virtual `attachments_count` field

  ## Examples

      iex> get_moment_card(123)
      %MomentCard{}

      iex> get_moment_card(456)
      nil

  """
  def get_moment_card(id, opts \\ []) do
    MomentCard
    |> apply_get_moment_card_opts(opts)
    |> Repo.get(id)
  end

  defp apply_get_moment_card_opts(queryable, []), do: queryable

  defp apply_get_moment_card_opts(queryable, [{:count_attachments, true} | opts]) do
    from(
      mc in queryable,
      left_join: mca in assoc(mc, :moment_card_attachments),
      group_by: mc.id,
      select: %{mc | attachments_count: count(mca.id)}
    )
    |> apply_get_moment_card_opts(opts)
  end

  defp apply_get_moment_card_opts(queryable, [_ | opts]),
    do: apply_get_moment_card_opts(queryable, opts)

  @doc """
  Gets a single moment_card.

  Same as `get_moment_card/1`, but raises `Ecto.NoResultsError` if the Moment card does not exist.

  """
  def get_moment_card!(id, opts \\ []) do
    MomentCard
    |> apply_get_moment_card_opts(opts)
    |> Repo.get!(id)
  end

  @doc """
  Creates a moment_card.

  ## Options:

  - `:log_profile_id` - logs the operation, linked to given profile

  ## Examples

      iex> create_moment_card(%{field: value})
      {:ok, %MomentCard{}}

      iex> create_moment_card(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_moment_card(attrs \\ %{}, opts \\ []) do
    %MomentCard{}
    |> MomentCard.changeset(attrs)
    |> set_moment_card_position()
    |> Repo.insert()
    |> LearningContextLog.maybe_create_moment_card_log("CREATE", opts)
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

  ## Options:

  - `:log_profile_id` - logs the operation, linked to given profile

  ## Examples

      iex> update_moment_card(moment_card, %{field: new_value})
      {:ok, %MomentCard{}}

      iex> update_moment_card(moment_card, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_moment_card(%MomentCard{} = moment_card, attrs, opts \\ []) do
    moment_card
    |> MomentCard.changeset(attrs)
    |> Repo.update()
    |> LearningContextLog.maybe_create_moment_card_log("UPDATE", opts)
  end

  @doc """
  Update moment cards positions based on ids list order.

  ## Examples

      iex> update_moment_cards_positions([3, 2, 1])
      :ok

  """
  def update_moment_cards_positions(moment_cards_ids),
    do: update_positions(MomentCard, moment_cards_ids)

  @doc """
  Deletes a moment_card.

  Before deleting the moment card, this function tries to delete all linked attachments.
  After the whole operation, in case of success, we trigger a request for deleting
  the attachments from the cloud (if they are internal).

  ## Options:

  - `:log_profile_id` - logs the operation, linked to given profile

  ## Examples

      iex> delete_moment_card(moment_card)
      {:ok, %MomentCard{}}

      iex> delete_moment_card(moment_card)
      {:error, %Ecto.Changeset{}}

  """
  def delete_moment_card(%MomentCard{} = moment_card, opts \\ []) do
    attachments_query =
      from(
        a in Attachment,
        join: mca in assoc(a, :moment_card_attachment),
        where: mca.moment_card_id == ^moment_card.id,
        select: a
      )

    Ecto.Multi.new()
    |> Ecto.Multi.delete_all(:delete_attachments, attachments_query)
    |> Ecto.Multi.delete(:delete_moment_card, moment_card)
    |> Repo.transaction()
    |> case do
      {:ok, %{delete_moment_card: moment_card, delete_attachments: {_qty, attachments}}} ->
        # if attachment is internal (Supabase),
        # delete from cloud in an async task (fire and forget)
        Enum.each(attachments, &Attachments.maybe_delete_attachment_from_cloud(&1))

        {:ok, moment_card}

      {:error, _name, value, _changes_so_far} ->
        {:error, value}
    end
    |> LearningContextLog.maybe_create_moment_card_log("DELETE", opts)
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

  @doc """
  Creates an attachment and links it to an existing moment card in a single transaction.

  ## Examples

      iex> create_moment_card_attachment(profile_id, moment_card_id, %{field: value})
      {:ok, %Attachment{}}

      iex> create_moment_card_attachment(profile_id, moment_card_id, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_moment_card_attachment(
          profile_id :: pos_integer(),
          moment_card_id :: pos_integer(),
          attachment_attrs :: map(),
          shared_with_students :: boolean()
        ) ::
          {:ok, Attachment.t()} | {:error, Ecto.Changeset.t()}
  def create_moment_card_attachment(
        profile_id,
        moment_card_id,
        attachment_attrs,
        shared_with_students \\ false
      ) do
    insert_query =
      %Attachment{}
      |> Attachment.changeset(Map.put(attachment_attrs, "owner_id", profile_id))

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:insert_attachment, insert_query)
    |> Ecto.Multi.run(
      :link_moment_card,
      fn _repo, %{insert_attachment: attachment} ->
        attrs =
          from(
            mca in MomentCardAttachment,
            where: mca.moment_card_id == ^moment_card_id
          )
          |> set_position_in_attrs(%{
            moment_card_id: moment_card_id,
            attachment_id: attachment.id,
            shared_with_students: shared_with_students,
            owner_id: profile_id
          })

        %MomentCardAttachment{}
        |> MomentCardAttachment.changeset(attrs)
        |> Repo.insert()
      end
    )
    |> Repo.transaction()
    |> case do
      {:error, _multi, changeset, _changes} ->
        {:error, changeset}

      {:ok, %{insert_attachment: attachment}} ->
        {:ok, %{attachment | is_shared: shared_with_students}}
    end
  end

  @doc """
  Update moment card attachments positions based on ids list order.

  ## Examples

      iex> update_moment_card_attachments_positions([3, 2, 1])
      :ok

  """
  @spec update_moment_card_attachments_positions(attachments_ids :: [pos_integer()]) ::
          :ok | {:error, String.t()}
  def update_moment_card_attachments_positions(attachments_ids),
    do: update_positions(MomentCardAttachment, attachments_ids, id_field: :attachment_id)

  @doc """
  Toggle the moment card `shared_with_students` field and returns the attachment with `is_shared` field updated.

  ## Examples

      iex> toggle_moment_card_attachment_share(attachment_id)
      {:ok, %Attachment{}}

      iex> toggle_moment_card_attachment_share(attachment_id)
      {:error, %Ecto.Changeset{}}

  """
  @spec toggle_moment_card_attachment_share(Attachment.t()) ::
          {:ok, Attachment.t()} | {:error, Ecto.Changeset.t()}
  def toggle_moment_card_attachment_share(attachment) do
    moment_card_attachment =
      from(
        mca in MomentCardAttachment,
        where: mca.attachment_id == ^attachment.id
      )
      |> Repo.one!()

    moment_card_attachment
    |> MomentCardAttachment.changeset(%{
      shared_with_students: !moment_card_attachment.shared_with_students
    })
    |> Repo.update()
    |> case do
      {:ok, _} ->
        {:ok, %{attachment | is_shared: !moment_card_attachment.shared_with_students}}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
