defmodule Lanttern.Reporting do
  @moduledoc """
  The Reporting context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo
  import Lanttern.RepoHelpers

  alias Lanttern.Reporting.ReportCard
  alias Lanttern.Reporting.StrandReport
  alias Lanttern.Reporting.StudentReportCard

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Attachments.Attachment
  alias Lanttern.LearningContext.Moment
  alias Lanttern.LearningContext.MomentCard
  alias Lanttern.LearningContext.Strand
  alias Lanttern.Schools
  alias Lanttern.Schools.Class
  alias Lanttern.Schools.Cycle
  alias Lanttern.Schools.Student
  alias Lanttern.Taxonomy.Year

  @doc """
  Returns the list of report cards.

  Report cards are ordered by cycle end date (desc) and name (asc)

  ## Options:

  - `:preloads` – preloads associated data
  - `:strands_ids` – filter report cards by strands
  - `:school_id` – filter report cards by school (based on school cycle)
  - `:cycles_ids` - filter report cards by cycles
  - `:parent_cycle_id` - filter report cards by subcycles of the given parent cycle
  - `:years_ids` - filter report cards by year

  ## Examples

      iex> list_report_cards()
      [%ReportCard{}, ...]

  """
  def list_report_cards(opts \\ []) do
    from(rc in ReportCard,
      join: sc in assoc(rc, :school_cycle),
      order_by: [desc: sc.end_at, asc: sc.start_at, asc: rc.name]
    )
    |> apply_list_report_cards_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_report_cards_opts(queryable, []), do: queryable

  defp apply_list_report_cards_opts(queryable, [{:strands_ids, ids} | opts])
       when is_list(ids) and ids != [] do
    from(
      rc in queryable,
      join: sr in assoc(rc, :strand_reports),
      join: s in assoc(sr, :strand),
      where: s.id in ^ids
    )
    |> apply_list_report_cards_opts(opts)
  end

  defp apply_list_report_cards_opts(queryable, [{:cycles_ids, ids} | opts])
       when is_list(ids) and ids != [] do
    from(rc in queryable, where: rc.school_cycle_id in ^ids)
    |> apply_list_report_cards_opts(opts)
  end

  defp apply_list_report_cards_opts(queryable, [{:school_id, id} | opts]) do
    from(
      rc in queryable,
      join: sc in assoc(rc, :school_cycle),
      where: sc.school_id == ^id
    )
    |> apply_list_report_cards_opts(opts)
  end

  defp apply_list_report_cards_opts(queryable, [{:parent_cycle_id, id} | opts])
       when is_integer(id) do
    from([_rc, sc] in queryable, where: sc.parent_cycle_id == ^id)
    |> apply_list_report_cards_opts(opts)
  end

  defp apply_list_report_cards_opts(queryable, [{:years_ids, ids} | opts])
       when is_list(ids) and ids != [] do
    from(rc in queryable, where: rc.year_id in ^ids)
    |> apply_list_report_cards_opts(opts)
  end

  defp apply_list_report_cards_opts(queryable, [_ | opts]),
    do: apply_list_report_cards_opts(queryable, opts)

  @doc """
  Returns the list of report cards, grouped by cycle.

  Cycles are ordered by end date (desc), and report cards
  in each group ordered by name (asc) — it's the same order
  returned by `list_report_cards/1`, which is used internally.

  See `list_report_cards/1` for options.

  ## Examples

      iex> list_report_cards_by_cycle()
      [{%Cycle{}, [%ReportCard{}, ...]}, ...]

  """

  @spec list_report_cards_by_cycle(Keyword.t()) :: [
          {Cycle.t(), [ReportCard.t()]}
        ]
  def list_report_cards_by_cycle(opts \\ []) do
    report_cards_by_cycle_map =
      list_report_cards(opts)
      |> Enum.group_by(& &1.school_cycle_id)

    Schools.list_cycles()
    |> Enum.map(&{&1, Map.get(report_cards_by_cycle_map, &1.id)})
    |> Enum.filter(fn {_cycle, report_cards} -> not is_nil(report_cards) end)
  end

  @doc """
  Gets a single report_card.

  Returns `nil` if the Report card does not exist.

  ## Options:

      - `:preloads` – preloads associated data

  ## Examples

      iex> get_report_card(123)
      %ReportCard{}

      iex> get_report_card(456)
      nil

  """
  def get_report_card(id, opts \\ []) do
    ReportCard
    |> Repo.get(id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single report_card.

  Same as `get_report_card/2`, but raises `Ecto.NoResultsError` if the Report card does not exist.

  ## Examples

      iex> get_report_card!(123)
      %ReportCard{}

      iex> get_report_card!(456)
      ** (Ecto.NoResultsError)

  """
  def get_report_card!(id, opts \\ []) do
    ReportCard
    |> Repo.get!(id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a report_card.

  ## Examples

      iex> create_report_card(%{field: value})
      {:ok, %ReportCard{}}

      iex> create_report_card(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_report_card(attrs \\ %{}) do
    %ReportCard{}
    |> ReportCard.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a report_card.

  ## Examples

      iex> update_report_card(report_card, %{field: new_value})
      {:ok, %ReportCard{}}

      iex> update_report_card(report_card, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_report_card(%ReportCard{} = report_card, attrs) do
    report_card
    |> ReportCard.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a report_card.

  ## Examples

      iex> delete_report_card(report_card)
      {:ok, %ReportCard{}}

      iex> delete_report_card(report_card)
      {:error, %Ecto.Changeset{}}

  """
  def delete_report_card(%ReportCard{} = report_card) do
    Repo.delete(report_card)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking report_card changes.

  ## Examples

      iex> change_report_card(report_card)
      %Ecto.Changeset{data: %ReportCard{}}

  """
  def change_report_card(%ReportCard{} = report_card, attrs \\ %{}) do
    ReportCard.changeset(report_card, attrs)
  end

  @doc """
  Returns the list of strand reports.

  Reports are ordered by position.

  ## Options

  - `:preloads` – preloads associated data
  - `:report_card_id` - filter strand reports by report card

  ## Examples

      iex> list_strands_reports()
      [%StrandReport{}, ...]

  """
  @spec list_strands_reports(Keyword.t()) :: [StrandReport.t()]

  def list_strands_reports(opts \\ []) do
    from(sr in StrandReport,
      order_by: sr.position
    )
    |> apply_list_strands_reports_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_strands_reports_opts(queryable, []), do: queryable

  defp apply_list_strands_reports_opts(queryable, [{:report_card_id, report_card_id} | opts]) do
    from(
      sr in queryable,
      where: sr.report_card_id == ^report_card_id
    )
    |> apply_list_strands_reports_opts(opts)
  end

  defp apply_list_strands_reports_opts(queryable, [_opt | opts]),
    do: apply_list_strands_reports_opts(queryable, opts)

  @doc """
  Gets a single strand_report.

  Returns `nil` if the Strand report does not exist.

  ## Options:

  - `:preloads` – preloads associated data
  - `:check_if_has_moments` – when `true` will calculate `has_moments` virtual field

  ## Examples

      iex> get_strand_report(123)
      %StrandReport{}

      iex> get_strand_report(456)
      nil

  """
  def get_strand_report(id, opts \\ []) do
    from(
      sr in StrandReport,
      where: sr.id == ^id
    )
    |> apply_get_strand_report_opts(opts)
    |> Repo.one()
    |> maybe_preload(opts)
  end

  defp apply_get_strand_report_opts(queryable, []), do: queryable

  defp apply_get_strand_report_opts(queryable, [{:check_if_has_moments, true} | opts]) do
    from(
      sr in queryable,
      left_join: m in Moment,
      on: m.strand_id == sr.strand_id,
      group_by: sr.id,
      select: %{sr | has_moments: count(m) > 0}
    )
    |> apply_get_strand_report_opts(opts)
  end

  defp apply_get_strand_report_opts(queryable, [_ | opts]),
    do: apply_get_strand_report_opts(queryable, opts)

  @doc """
  Gets a single strand_report.

  Same as `get_strand_report/2`, but raises `Ecto.NoResultsError` if the Strand report does not exist.
  """
  def get_strand_report!(id, opts \\ []) do
    from(
      sr in StrandReport,
      where: sr.id == ^id
    )
    |> apply_get_strand_report_opts(opts)
    |> Repo.one!()
    |> maybe_preload(opts)
  end

  @doc """
  Creates a strand_report.

  ## Examples

      iex> create_strand_report(%{field: value})
      {:ok, %StrandReport{}}

      iex> create_strand_report(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_strand_report(attrs \\ %{}) do
    %StrandReport{}
    |> StrandReport.changeset(attrs)
    |> set_strand_report_position()
    |> Repo.insert()
  end

  # skip if not valid
  defp set_strand_report_position(%Ecto.Changeset{valid?: false} = changeset),
    do: changeset

  # skip if changeset already has position change
  defp set_strand_report_position(%Ecto.Changeset{changes: %{position: _position}} = changeset),
    do: changeset

  defp set_strand_report_position(%Ecto.Changeset{} = changeset) do
    report_card_id =
      Ecto.Changeset.get_field(changeset, :report_card_id)

    position =
      from(
        sr in StrandReport,
        where: sr.report_card_id == ^report_card_id,
        select: sr.position,
        order_by: [desc: sr.position],
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
  Updates a strand_report.

  ## Examples

      iex> update_strand_report(strand_report, %{field: new_value})
      {:ok, %StrandReport{}}

      iex> update_strand_report(strand_report, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_strand_report(%StrandReport{} = strand_report, attrs) do
    strand_report
    |> StrandReport.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Update strands reports positions based on ids list order.

  ## Examples

      iex> update_strands_reports_positions([3, 2, 1])
      :ok

  """
  @spec update_strands_reports_positions([integer()]) :: :ok | {:error, String.t()}
  def update_strands_reports_positions(strands_reports_ids),
    do: update_positions(StrandReport, strands_reports_ids)

  @doc """
  Deletes a strand_report.

  ## Examples

      iex> delete_strand_report(strand_report)
      {:ok, %StrandReport{}}

      iex> delete_strand_report(strand_report)
      {:error, %Ecto.Changeset{}}

  """
  def delete_strand_report(%StrandReport{} = strand_report) do
    Repo.delete(strand_report)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking strand_report changes.

  ## Examples

      iex> change_strand_report(strand_report)
      %Ecto.Changeset{data: %StrandReport{}}

  """
  def change_strand_report(%StrandReport{} = strand_report, attrs \\ %{}) do
    StrandReport.changeset(strand_report, attrs)
  end

  @doc """
  Returns the list of student_report_cards.

  ## Options

  - `:student_id` - filter results by student
  - `:ids` - filter results by given ids
  - `:preloads` – preloads associated data
  - `:parent_cycle_id` - filter results by given cycle

  ## Examples

      iex> list_student_report_cards()
      [%StudentReportCard{}, ...]

  """
  def list_student_report_cards(opts \\ []) do
    from(
      src in StudentReportCard,
      join: rc in assoc(src, :report_card),
      join: sc in assoc(rc, :school_cycle),
      as: :school_cycle,
      order_by: [desc: sc.end_at, asc: sc.start_at]
    )
    |> apply_list_student_report_cards_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_student_report_cards_opts(queryable, []), do: queryable

  defp apply_list_student_report_cards_opts(queryable, [{:student_id, student_id} | opts]) do
    from(
      src in queryable,
      where: src.student_id == ^student_id
    )
    |> apply_list_student_report_cards_opts(opts)
  end

  defp apply_list_student_report_cards_opts(queryable, [{:ids, ids} | opts]) do
    from(
      src in queryable,
      where: src.id in ^ids
    )
    |> apply_list_student_report_cards_opts(opts)
  end

  defp apply_list_student_report_cards_opts(queryable, [
         {:parent_cycle_id, parent_cycle_id} | opts
       ])
       when is_integer(parent_cycle_id) do
    from(
      [_src, school_cycle: sc] in queryable,
      where: sc.parent_cycle_id == ^parent_cycle_id
    )
    |> apply_list_student_report_cards_opts(opts)
  end

  defp apply_list_student_report_cards_opts(queryable, [_ | opts]),
    do: apply_list_student_report_cards_opts(queryable, opts)

  @doc """
  Returns the list of all students and their report cards linked to the
  given base report card.

  Students will have their classes preloaded and will be
  ordered by class name, and them by student name.

  Preloaded classes will be restricted to classes from the same
  report card's year and parent school cycle (if possible).

  Students' `profile_picture_url` will be loaded if report card parent cycle exists.

  Expect `school_cycle` preloads.

  ## Options

  - `:classes_ids` - filter results by given classes
  - `:active_students_only` – (boolean) remove deactivated students from results
  - `:students_only` - when `true`, will return only students

  ## Examples

      iex> list_students_linked_to_report_card()
      [{%Student{}, %StudentReportCard{}}, ...]

  """
  @spec list_students_linked_to_report_card(ReportCard.t(), opts :: Keyword.t()) :: [
          {Student.t(), StudentReportCard.t()} | Student.t()
        ]
  def list_students_linked_to_report_card(%ReportCard{} = report_card, opts \\ []) do
    %{school_cycle: %Cycle{} = cycle} = report_card

    allowed_classes_ids =
      build_list_students_linked_to_report_card_allowed_classes_ids(report_card)

    where =
      case Keyword.get(opts, :active_students_only) do
        true -> dynamic([s], is_nil(s.deactivated_at))
        _ -> true
      end

    from(
      s in Student,
      left_join: c in assoc(s, :classes),
      on: c.id in ^allowed_classes_ids,
      as: :classes,
      join: src in StudentReportCard,
      on: src.student_id == s.id and src.report_card_id == ^report_card.id,
      as: :student_report_card,
      where: ^where,
      order_by: [asc: c.name, asc: s.name],
      preload: [classes: c]
    )
    |> maybe_join_students_cycle_info(cycle)
    |> list_students_linked_to_report_card_select(opts)
    |> apply_list_students_linked_to_report_card_opts(opts)
    |> Repo.all()
  end

  defp build_list_students_linked_to_report_card_allowed_classes_ids(report_card) do
    # restrict classes to same report card year
    conditions =
      dynamic([_c, y], y.id == ^report_card.year_id)

    # restrict classes to same report card parent cycle if possible
    conditions =
      case report_card.school_cycle do
        %{parent_cycle_id: parent_cycle_id} when not is_nil(parent_cycle_id) ->
          dynamic([c], c.cycle_id == ^parent_cycle_id and ^conditions)

        _ ->
          conditions
      end

    from(
      c in Class,
      left_join: y in assoc(c, :years),
      where: ^conditions,
      select: c.id
    )
    |> Repo.all()
  end

  defp maybe_join_students_cycle_info(queryable, %{parent_cycle_id: cycle_id})
       when not is_nil(cycle_id) do
    from(
      s in queryable,
      left_join: sci in assoc(s, :cycles_info),
      on: sci.cycle_id == ^cycle_id,
      as: :students_cycle_info
      # select_merge: %{profile_picture_url: sci.profile_picture_url}
    )
  end

  defp maybe_join_students_cycle_info(queryable, _), do: queryable

  defp list_students_linked_to_report_card_select(queryable, opts) do
    is_student_only = Keyword.get(opts, :students_only)
    has_students_cycle_info = has_named_binding?(queryable, :students_cycle_info)

    case {is_student_only, has_students_cycle_info} do
      {true, true} ->
        from(
          [s, students_cycle_info: sci] in queryable,
          select: %{s | profile_picture_url: sci.profile_picture_url}
        )

      {true, _} ->
        queryable

      {_, true} ->
        from(
          [s, student_report_card: src, students_cycle_info: sci] in queryable,
          select: {%{s | profile_picture_url: sci.profile_picture_url}, src}
        )

      {_, _} ->
        from(
          [s, student_report_card: src] in queryable,
          select: {s, src}
        )
    end
  end

  defp apply_list_students_linked_to_report_card_opts(queryable, []), do: queryable

  defp apply_list_students_linked_to_report_card_opts(queryable, [
         {:classes_ids, classes_ids} | opts
       ])
       when is_list(classes_ids) and classes_ids != [] do
    from(
      [_s, classes: c] in queryable,
      where: c.id in ^classes_ids
    )
    |> apply_list_students_linked_to_report_card_opts(opts)
  end

  defp apply_list_students_linked_to_report_card_opts(queryable, [_opt | opts]),
    do: apply_list_students_linked_to_report_card_opts(queryable, opts)

  @doc """
  Returns the list of all students not linked to given base report card.

  Results are filtered by the report card year and parent cycle (if possible),
  and ordered by class name, and them by student name.

  Students' `profile_picture_url` will be loaded if report card parent cycle exists.

  Deactivated students are not included.

  Expect `school_cycle` and `year` preloads.

  ## Examples

      iex> list_students_not_linked_to_report_card(report_card)
      [%Student{}, ...]

  """
  @spec list_students_not_linked_to_report_card(ReportCard.t()) :: [
          Student.t()
        ]
  def list_students_not_linked_to_report_card(%ReportCard{} = report_card) do
    %{
      id: report_card_id,
      school_cycle: %Cycle{} = cycle,
      year: %Year{} = year
    } = report_card

    where_cycle_filter =
      if cycle.parent_cycle_id,
        do: dynamic([_s, _c, _y, cy], cy.id == ^cycle.parent_cycle_id),
        else: true

    from(
      s in Student,
      join: c in assoc(s, :classes),
      join: y in assoc(c, :years),
      join: cy in assoc(c, :cycle),
      left_join: sr in StudentReportCard,
      on: sr.student_id == s.id and sr.report_card_id == ^report_card_id,
      where: is_nil(sr),
      where: y.id == ^year.id,
      where: ^where_cycle_filter,
      where: is_nil(s.deactivated_at),
      order_by: [asc: c.name, asc: s.name],
      preload: [classes: c]
    )
    |> maybe_load_profile_picture_url(cycle)
    |> Repo.all()
  end

  defp maybe_load_profile_picture_url(queryable, %{parent_cycle_id: cycle_id})
       when not is_nil(cycle_id) do
    from(
      s in queryable,
      left_join: sci in assoc(s, :cycles_info),
      on: sci.cycle_id == ^cycle_id,
      select_merge: %{profile_picture_url: sci.profile_picture_url}
    )
  end

  defp maybe_load_profile_picture_url(queryable, _), do: queryable

  @doc """
  Returns the list of cycles related to student report cards.

  ## Options

  - `:parent_cycle_id` - filter

  ## Examples

      iex> list_student_report_cards_cycles(student_id)
      [%Cycle{}, ...]

  """
  @spec list_student_report_cards_cycles(student_id :: pos_integer(), opts :: Keyword.t()) :: [
          Cycle.t()
        ]
  def list_student_report_cards_cycles(student_id, opts \\ []) do
    from(
      c in Cycle,
      join: rc in ReportCard,
      on: rc.school_cycle_id == c.id,
      join: src in assoc(rc, :students_report_cards),
      where: src.student_id == ^student_id,
      order_by: [asc: c.end_at, desc: c.start_at],
      distinct: true
    )
    |> apply_list_student_report_cards_cycles_opts(opts)
    |> Repo.all()
  end

  defp apply_list_student_report_cards_cycles_opts(queryable, []), do: queryable

  defp apply_list_student_report_cards_cycles_opts(queryable, [
         {:parent_cycle_id, parent_cycle_id} | opts
       ])
       when is_integer(parent_cycle_id) do
    from(
      c in queryable,
      where: c.parent_cycle_id == ^parent_cycle_id
    )
    |> apply_list_student_report_cards_cycles_opts(opts)
  end

  defp apply_list_student_report_cards_cycles_opts(queryable, [_ | opts]),
    do: apply_list_student_report_cards_cycles_opts(queryable, opts)

  @doc """
  Returns the list of all student report cards
  and strand reports linked to a strand.

  `%StudentReportCard{}`s have `report_card` preloaded.

  Results are ordered by report card cycle.

  ## Examples

      iex> list_student_report_cards_linked_to_strand(student_id, strand_id)
      [{%StudentReportCard{}, %StrandReport{}}, ...]

  """
  @spec list_student_report_cards_linked_to_strand(
          student_id :: pos_integer(),
          strand_id :: pos_integer()
        ) :: [
          {StudentReportCard.t(), StrandReport.t()}
        ]
  def list_student_report_cards_linked_to_strand(student_id, strand_id) do
    from(
      src in StudentReportCard,
      join: rc in assoc(src, :report_card),
      join: c in assoc(rc, :school_cycle),
      join: sr in assoc(rc, :strand_reports),
      where: src.student_id == ^student_id,
      where: sr.strand_id == ^strand_id,
      select: {%{src | report_card: rc}, sr},
      order_by: [asc: c.end_at, desc: c.end_at]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single student report card.

  Returns `nil` if the Student report card does not exist.

  ## Options:

      - `:preloads` – preloads associated data

  ## Examples

      iex> get_student_report_card!(123)
      %StudentReportCard{}

      iex> get_student_report_card!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student_report_card(id, opts \\ []) do
    StudentReportCard
    |> Repo.get(id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single student report card.

  Same as `get_student_report_card/2`, but raises `Ecto.NoResultsError` if the student report card does not exist.
  """
  def get_student_report_card!(id, opts \\ []) do
    StudentReportCard
    |> Repo.get!(id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single student report card based on given student and children strand report.

  Returns `nil` if the Student report card does not exist.

  ## Options

  - `:preloads` – preloads associated data

  ## Examples

      iex> get_student_report_card_by_student_and_strand_report(123, 123)
      %StudentReportCard{}

      iex> get_student_report_card_by_student_and_strand_report(456, 456)
      nil

  """
  @spec get_student_report_card_by_student_and_strand_report(
          student_id :: pos_integer(),
          strand_report_id :: pos_integer(),
          opts :: Keyword.t()
        ) :: StudentReportCard.t() | nil
  def get_student_report_card_by_student_and_strand_report(
        student_id,
        strand_report_id,
        opts \\ []
      ) do
    from(
      src in StudentReportCard,
      join: rc in assoc(src, :report_card),
      join: sr in assoc(rc, :strand_reports),
      where: sr.id == ^strand_report_id,
      where: src.student_id == ^student_id
    )
    |> Repo.one()
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single student report card by student and report card id.

  Returns `nil` if the Student report card does not exist.

  ## Examples

      iex> get_student_report_card_by_student_and_parent_report(123, 123)
      %StudentReportCard{}

      iex> get_student_report_card_by_student_and_parent_report(456, 456)
      nil

  """
  @spec get_student_report_card_by_student_and_parent_report(
          student_id :: non_neg_integer(),
          report_card_id :: non_neg_integer()
        ) :: StudentReportCard.t() | nil
  def get_student_report_card_by_student_and_parent_report(student_id, report_card_id) do
    StudentReportCard
    |> Repo.get_by(student_id: student_id, report_card_id: report_card_id)
  end

  @doc """
  Creates a student_report_card.

  ## Examples

      iex> create_student_report_card(%{field: value})
      {:ok, %StudentReportCard{}}

      iex> create_student_report_card(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_report_card(attrs \\ %{}) do
    %StudentReportCard{}
    |> StudentReportCard.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a student_report_card.

  ## Examples

      iex> update_student_report_card(student_report_card, %{field: new_value})
      {:ok, %StudentReportCard{}}

      iex> update_student_report_card(student_report_card, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_report_card(%StudentReportCard{} = student_report_card, attrs) do
    student_report_card
    |> StudentReportCard.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates multiple student report cards.

  ## Examples

      iex> batch_update_student_report_card([student_report_card], %{field: new_value})
      {:ok, %{"1" => %StudentReportCard{}}}

      iex> batch_update_student_report_card([student_report_card], %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec batch_update_student_report_card([StudentReportCard.t()], map()) ::
          {:ok, %{pos_integer() => StudentReportCard.t()}}
          | {:error, Ecto.Multi.name(), any(), %{required(Ecto.Multi.name()) => any()}}
  def batch_update_student_report_card(student_report_cards, attrs) do
    Enum.reduce(student_report_cards, Ecto.Multi.new(), fn src, multi ->
      multi
      |> Ecto.Multi.update(
        src.id,
        StudentReportCard.changeset(src, attrs)
      )
    end)
    |> Repo.transaction()
  end

  @doc """
  Deletes a student_report_card.

  ## Examples

      iex> delete_student_report_card(student_report_card)
      {:ok, %StudentReportCard{}}

      iex> delete_student_report_card(student_report_card)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_report_card(%StudentReportCard{} = student_report_card) do
    Repo.delete(student_report_card)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_report_card changes.

  ## Examples

      iex> change_student_report_card(student_report_card)
      %Ecto.Changeset{data: %StudentReportCard{}}

  """
  def change_student_report_card(%StudentReportCard{} = student_report_card, attrs \\ %{}) do
    StudentReportCard.changeset(student_report_card, attrs)
  end

  @doc """
  Returns the list of strand reports linked to the report card, with assessment entries.

  **Preloaded data:**

  - strand reports: strand with subjects and years
  - assessment entries: assessment point, scale, and ordinal value

  ## Options

  - `:include_strands_without_entries` - `boolean`, false by "default"

  ## Examples

      iex> list_student_report_card_strand_reports_and_entries(student_report_card)
      [{%StrandReport{}, [%AssessmentPointEntry{}, ...]}, ...]

  """
  @spec list_student_report_card_strand_reports_and_entries(
          StudentReportCard.t(),
          opts :: Keyword.t()
        ) :: [
          {StrandReport.t(), [AssessmentPointEntry.t()]}
        ]

  def list_student_report_card_strand_reports_and_entries(
        %StudentReportCard{} = student_report_card,
        opts \\ []
      ) do
    %{
      report_card_id: report_card_id,
      student_id: student_id
    } = student_report_card

    strand_reports =
      from(sr in StrandReport,
        join: s in assoc(sr, :strand),
        left_join: sub in assoc(s, :subjects),
        left_join: y in assoc(s, :years),
        where: sr.report_card_id == ^report_card_id,
        order_by: sr.position,
        preload: [strand: {s, [subjects: sub, years: y]}]
      )
      |> Repo.all()

    ast_entries_map =
      from(e in AssessmentPointEntry,
        join: sc in assoc(e, :scale),
        left_join: ov in assoc(e, :ordinal_value),
        join: ap in assoc(e, :assessment_point),
        join: s in assoc(ap, :strand),
        join: sr in assoc(s, :strand_reports),
        where: sr.report_card_id == ^report_card_id and e.student_id == ^student_id,
        where: e.has_marking,
        order_by: ap.position,
        preload: [scale: sc, ordinal_value: ov],
        select: {sr.id, e}
      )
      |> Repo.all()
      |> Enum.group_by(
        fn {strand_report_id, _} -> strand_report_id end,
        fn {_, entry} -> entry end
      )

    strand_reports
    |> Enum.map(&{&1, Map.get(ast_entries_map, &1.id, [])})
    |> Enum.filter(fn {_strand_report, entries} ->
      Keyword.get(opts, :include_strands_without_entries) || entries != []
    end)
  end

  @doc """
  Returns the list of moments linked to the strand report, with assessment entries.

  Entries without marking are ignored.

  **Preloaded data:**

  - moments: subjects

  ## Examples

      iex> list_student_strand_report_moments_and_entries(strand_report, student_id)
      [{%StrandReport{}, [%AssessmentPointEntry{}, ...]}, ...]

  """
  @spec list_student_strand_report_moments_and_entries(
          StrandReport.t(),
          student_id :: pos_integer()
        ) :: [
          {Moment.t(), [AssessmentPointEntry.t()]}
        ]

  def list_student_strand_report_moments_and_entries(
        %StrandReport{} = strand_report,
        student_id
      ) do
    %{strand_id: strand_id} = strand_report

    moments =
      from(m in Moment,
        left_join: sub in assoc(m, :subjects),
        where: m.strand_id == ^strand_id,
        order_by: [asc: m.position, asc: sub.name],
        preload: [subjects: sub]
      )
      |> Repo.all()

    ast_entries_map =
      from(e in AssessmentPointEntry,
        join: ap in assoc(e, :assessment_point),
        join: m in assoc(ap, :moment),
        where: m.strand_id == ^strand_id and e.student_id == ^student_id,
        where: e.has_marking,
        order_by: ap.position,
        select: {m.id, e}
      )
      |> Repo.all()
      |> Enum.group_by(
        fn {moment_id, _} -> moment_id end,
        fn {_, entry} -> entry end
      )

    moments
    |> Enum.map(&{&1, Map.get(ast_entries_map, &1.id, [])})
  end

  @doc """
  Returns the list of student evidences linked to given strand,
  with goal id and moment name (if any) info.

  Ordered by moment then assessment point position.
  Goals evidences are shown last.

  ## Examples

      iex> list_student_strand_evidences(strand_id, student_id)
      [{%Attachment{}, 1, "Task 1"}, ...]

  """
  @spec list_student_strand_evidences(
          strand_id :: pos_integer(),
          student_id :: pos_integer()
        ) :: [
          {Attachment.t(), goal_id :: pos_integer(), moment_name :: binary() | nil}
        ]
  def list_student_strand_evidences(strand_id, student_id) do
    base_query =
      from(
        a in Attachment,
        join: e in assoc(a, :assessment_point_entry),
        on: e.student_id == ^student_id,
        join: ap in assoc(e, :assessment_point),
        as: :assessment_point
      )

    moments_evidences_and_name =
      from(
        [a, assessment_point: ap] in base_query,
        join: m in assoc(ap, :moment),
        # pg = parent_goal
        join: pg in AssessmentPoint,
        on: pg.curriculum_item_id == ap.curriculum_item_id and pg.strand_id == ^strand_id,
        where: m.strand_id == ^strand_id,
        order_by: [asc: m.position, asc: ap.position],
        select: {a, pg.id, m.name}
      )
      |> Repo.all()

    goals_evidences =
      from(
        [a, assessment_point: ap] in base_query,
        where: ap.strand_id == ^strand_id,
        order_by: ap.position,
        select: {a, ap.id, nil}
      )
      |> Repo.all()

    moments_evidences_and_name ++ goals_evidences
  end

  @doc """
  Returns the list of assessment points and entries linked to given moment and student.

  Assessment point without entries are not included (entries without marking are ignored).

  **Preloaded data:**

  - assessment_points: rubric
  - assessment entries: scale, ordinal value, differentiation rubric

  ## Examples

      iex> list_moment_assessment_points_and_student_entries(moment_id, student_id)
      [{%AssessmentPoint{}, %AssessmentPointEntry{}}, ...]

  """
  @spec list_moment_assessment_points_and_student_entries(
          moment_id :: pos_integer(),
          student_id :: pos_integer()
        ) :: [
          {AssessmentPoint.t(), AssessmentPointEntry.t()}
        ]

  def list_moment_assessment_points_and_student_entries(moment_id, student_id) do
    from(
      ap in AssessmentPoint,
      left_join: r in assoc(ap, :rubric),
      join: e in AssessmentPointEntry,
      on: e.assessment_point_id == ap.id and e.student_id == ^student_id,
      left_join: sc in assoc(e, :scale),
      left_join: ov in assoc(e, :ordinal_value),
      left_join: dr in assoc(e, :differentiation_rubric),
      left_join: apee in assoc(e, :assessment_point_entry_evidences),
      left_join: ev in assoc(apee, :attachment),
      select: {%{ap | rubric: r}, e, sc, ov, dr, ev},
      where: ap.moment_id == ^moment_id,
      where: e.has_marking,
      order_by: [ap.position, apee.position]
    )
    |> Repo.all()
    |> Enum.group_by(
      fn {ap, e, sc, ov, dr, _ev} -> {ap, e, sc, ov, dr} end,
      fn {_ap, _e, _sc, _ov, _dr, ev} -> ev end
    )
    |> Enum.map(fn {{ap, e, sc, ov, dr}, evidences} ->
      evidences = Enum.reject(evidences, &is_nil/1)

      entry =
        e &&
          %{
            e
            | scale: sc,
              ordinal_value: ov,
              differentiation_rubric: dr,
              evidences: evidences
          }

      {ap, entry}
    end)
    |> Enum.sort_by(fn {ap, _e} -> ap.position end)
  end

  @doc """
  Returns the list of moments with assessment points and entries
  linked to given strand goal (strand linked assessment point) and student.

  Moments without assessment points are not included,
  and assessment points without entries are not included
  (which means moments with linked assessment points but no entries are not included).

  **Preloaded data:**

  - assessment points: rubric
  - assessment entries: scale, ordinal value, evidences, diff rubric

  ## Examples

      iex> list_strand_goal_moments_and_student_entries(assessment_point_id, student_id)
      [{%Moment{}, [{%AssessmentPoint{}, %AssessmentPointEntry{}}, ...]}, ...]

  """
  @spec list_strand_goal_moments_and_student_entries(
          strand_goal :: AssessmentPoint.t(),
          student_id :: pos_integer()
        ) :: [
          {Moment.t(), [{AssessmentPoint.t(), AssessmentPointEntry.t()}]}
        ]

  def list_strand_goal_moments_and_student_entries(%AssessmentPoint{} = strand_goal, student_id) do
    %{
      curriculum_item_id: curriculum_item_id,
      strand_id: strand_id
    } = strand_goal

    moments_and_assessment_points =
      from(
        m in Moment,
        join: ap in assoc(m, :assessment_points),
        on: ap.curriculum_item_id == ^curriculum_item_id,
        left_join: r in assoc(ap, :rubric),
        select: {m, %{ap | rubric: r}},
        where: m.strand_id == ^strand_id,
        order_by: [asc: m.position, asc: ap.position]
      )
      |> Repo.all()

    ap_id_entries_map =
      from(
        e in AssessmentPointEntry,
        join: ap in assoc(e, :assessment_point),
        join: m in assoc(ap, :moment),
        left_join: sc in assoc(e, :scale),
        left_join: ov in assoc(e, :ordinal_value),
        left_join: apee in assoc(e, :assessment_point_entry_evidences),
        left_join: ev in assoc(apee, :attachment),
        left_join: dr in assoc(e, :differentiation_rubric),
        preload: [scale: sc, ordinal_value: ov, evidences: ev, differentiation_rubric: dr],
        where: m.strand_id == ^strand_id and e.student_id == ^student_id,
        where: e.has_marking,
        order_by: [asc: ap.position, asc: apee.position]
      )
      |> Repo.all()
      |> Enum.map(&{&1.assessment_point_id, &1})
      |> Enum.into(%{})

    m_id_assessment_points_and_entries_map =
      moments_and_assessment_points
      |> Enum.map(fn {_m, ap} -> {ap, ap_id_entries_map[ap.id]} end)
      |> Enum.filter(fn {_ap, entry} -> not is_nil(entry) end)
      |> Enum.group_by(fn {ap, _entries} -> ap.moment_id end)

    moments_and_assessment_points
    |> Enum.map(fn {m, _ap} -> m end)
    |> Enum.uniq()
    |> Enum.map(&{&1, m_id_assessment_points_and_entries_map[&1.id]})
    |> Enum.filter(fn {_moment, assessment_points} -> not is_nil(assessment_points) end)
  end

  @doc """
  Returns a list of all assessment points linked to the report card.

  Results are ordered by strand report card and strand goals position.

  Preloads `:strand` and `curriculum_item: :curriculum_component`.

  ## Examples

      iex> list_report_card_assessment_points(report_card_id)
      [%AssessmentPoint{}, ...]

  """
  @spec list_report_card_assessment_points(integer()) :: [AssessmentPoint.t()]
  def list_report_card_assessment_points(report_card_id) do
    from(ap in AssessmentPoint,
      join: s in assoc(ap, :strand),
      join: sr in assoc(s, :strand_reports),
      join: ci in assoc(ap, :curriculum_item),
      join: cc in assoc(ci, :curriculum_component),
      where: sr.report_card_id == ^report_card_id,
      order_by: [asc: sr.position, asc: ap.position],
      preload: [strand: s, curriculum_item: {ci, curriculum_component: cc}]
    )
    |> Repo.all()
  end

  @doc """
  Returns a list of all classes from students linked to given report card.

  Useful for building report card linked students class filter.

  Will list only classes from the same report card's year and parent cycle (if possible).

  ## Examples

      iex> list_report_card_linked_students_classes(report_card_id)
      [%Class{}, ...]

  """
  @spec list_report_card_linked_students_classes(report_card :: ReportCard.t()) :: [Class.t()]
  def list_report_card_linked_students_classes(%ReportCard{} = report_card) do
    from(c in Class,
      left_join: y in assoc(c, :years),
      join: s in assoc(c, :students),
      join: src in assoc(s, :student_report_cards),
      where: src.report_card_id == ^report_card.id,
      where: y.id == ^report_card.year_id,
      group_by: c.id,
      order_by: [asc: min(y.id), asc: c.name]
    )
    |> maybe_filter_classes_by_cycle(report_card)
    |> Repo.all()
  end

  defp maybe_filter_classes_by_cycle(queryable, %ReportCard{
         school_cycle: %Cycle{parent_cycle_id: parent_cycle_id}
       })
       when not is_nil(parent_cycle_id) do
    from(
      c in queryable,
      where: c.cycle_id == ^parent_cycle_id
    )
  end

  defp maybe_filter_classes_by_cycle(queryable, _), do: queryable

  @doc """
  Returns a map in the format

      %{
        student_id: %{
          strand_id: [
            {moment_id, assessment_point_id, %AssessmentPointEntry{}},
            # other moment assessment entry tuples...
          ],
          # other strands ids...
        },
        # other students ids...
      }

  for given report card and students.

  Moment/assessment point/entry tuples are ordered by moment and then by assessment point position.

  When there's no entry, `nil` is returned in place. Moments and assessment points ids are included
  to help building the element dom id in the frontend and link to the moment assessment page.

  """
  @spec build_students_moments_entries_map_for_report_card(
          report_card_id :: pos_integer(),
          students_ids :: [pos_integer()]
        ) :: %{}
  def build_students_moments_entries_map_for_report_card(report_card_id, students_ids) do
    strands_moments_assessment_points =
      from(
        s in Strand,
        join: sr in assoc(s, :strand_reports),
        join: m in assoc(s, :moments),
        join: ap in assoc(m, :assessment_points),
        where: sr.report_card_id == ^report_card_id,
        select: {s.id, m.id, ap.id},
        order_by: [asc: m.position, asc: ap.position]
      )
      |> Repo.all()

    assessment_points_ids =
      strands_moments_assessment_points
      |> Enum.map(fn {_s_id, _m_id, ap_id} -> ap_id end)

    students_assessment_points_entry_map =
      from(
        e in AssessmentPointEntry,
        where: e.assessment_point_id in ^assessment_points_ids,
        where: e.student_id in ^students_ids
      )
      |> Repo.all()
      |> Enum.map(&{"#{&1.student_id}_#{&1.assessment_point_id}", &1})
      |> Enum.into(%{})

    students_ids
    |> Enum.map(fn std_id ->
      {
        std_id,
        build_strands_moments_assessment_points_entries_map(
          std_id,
          strands_moments_assessment_points,
          students_assessment_points_entry_map
        )
      }
    end)
    |> Enum.into(%{})
  end

  defp build_strands_moments_assessment_points_entries_map(
         student_id,
         strands_moments_assessment_points,
         students_assessment_points_entry_map
       ) do
    strands_moments_assessment_points
    |> Enum.group_by(
      fn {s_id, _m_id, _ap_id} -> s_id end,
      fn {_s_id, m_id, ap_id} ->
        {
          m_id,
          ap_id,
          students_assessment_points_entry_map["#{student_id}_#{ap_id}"]
        }
      end
    )
  end

  @doc """
  Returns the list of moment cards shared with student and linked to given moment.

  **Preloaded data:**

  - attachments: list of linked attachments

  ## Options

  - `:school_id` - filter moment cards by school

  ## Examples

      iex> list_moment_cards_and_attachments_shared_with_students(moment_id)
      [%MomentCard{}, ...]

  """
  @spec list_moment_cards_and_attachments_shared_with_students(
          moment_id :: pos_integer(),
          opts :: Keyword.t()
        ) :: [
          MomentCard.t()
        ]

  def list_moment_cards_and_attachments_shared_with_students(moment_id, opts \\ []) do
    from(
      mc in MomentCard,
      left_join: mca in assoc(mc, :moment_card_attachments),
      on: mca.shared_with_students,
      left_join: a in assoc(mca, :attachment),
      where: mc.moment_id == ^moment_id,
      where: mc.shared_with_students,
      order_by: [asc: mc.position, asc: mca.position],
      preload: [attachments: a]
    )
    |> apply_list_moment_cards_and_attachments_shared_with_students_opts(opts)
    |> Repo.all()
  end

  defp apply_list_moment_cards_and_attachments_shared_with_students_opts(queryable, []),
    do: queryable

  defp apply_list_moment_cards_and_attachments_shared_with_students_opts(queryable, [
         {:school_id, id} | opts
       ]) do
    from(
      mc in queryable,
      where: mc.school_id == ^id
    )
    |> apply_list_moment_cards_and_attachments_shared_with_students_opts(opts)
  end

  defp apply_list_moment_cards_and_attachments_shared_with_students_opts(queryable, [_ | opts]),
    do: apply_list_moment_cards_and_attachments_shared_with_students_opts(queryable, opts)
end
