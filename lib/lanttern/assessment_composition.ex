defmodule Lanttern.AssessmentComposition do
  @moduledoc """
  The AssessmentComposition context.

  Manages `Component` records that link child assessment points into a
  composed (parent) assessment point for sum or average grading.
  """

  import Ecto.Query

  require Logger

  alias Lanttern.Repo

  alias Lanttern.AssessmentComposition.Component
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.AssessmentsLog
  alias Lanttern.Grading
  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Identity.Scope

  @doc """
  Returns the list of composition components for the given parent assessment point id.

  Child assessment points are preloaded with scale and curriculum item.
  """
  def list_assessment_point_components(%Scope{} = _scope, parent_id) do
    from(c in Component,
      join: ap in AssessmentPoint,
      on: c.component_id == ap.id,
      where: c.parent_id == ^parent_id,
      order_by: [asc_nulls_last: ap.moment_id, asc: ap.position],
      preload: [component: {ap, [:scale, curriculum_item: :curriculum_component]}]
    )
    |> Repo.all()
  end

  @doc """
  Lists the component assessment point ids for the given parent assessment point ids.

  Returns the de-duplicated `component_id`s across all parents in a single query —
  useful for expanding a set of composed goals into the assessment points that
  feed them without an N+1.
  """
  @spec list_component_ids_for_parents(Scope.t(), [pos_integer()]) :: [pos_integer()]
  def list_component_ids_for_parents(%Scope{} = _scope, parent_ids) do
    from(c in Component,
      where: c.parent_id in ^parent_ids,
      distinct: true,
      select: c.component_id
    )
    |> Repo.all()
  end

  @doc """
  Lists `{parent_id, component_id}` pairs for the given parent assessment point ids.

  Joins the component assessment point to order pairs by the component's `moment_id`
  (nulls last) then `position` — matching `list_assessment_point_components/2` — so
  callers can render component particles in a stable order without an N+1.
  """
  @spec list_parent_component_pairs(Scope.t(), [pos_integer()]) :: [
          {pos_integer(), pos_integer()}
        ]
  def list_parent_component_pairs(%Scope{} = _scope, parent_ids) do
    from(c in Component,
      join: ap in AssessmentPoint,
      on: c.component_id == ap.id,
      where: c.parent_id in ^parent_ids,
      order_by: [asc: c.parent_id, asc_nulls_last: ap.moment_id, asc: ap.position],
      select: {c.parent_id, c.component_id}
    )
    |> Repo.all()
  end

  @doc """
  Returns a map of `parent_id => [%AssessmentPointEntry{}, ...]` with each composed parent's
  component student entries, ordered for display (matching `list_parent_component_pairs/2`).

  Components without a student entry are omitted, as are components flagged `is_hidden`
  (their marking must not leak through the parent's particles). Entries have `ordinal_value`/
  `student_ordinal_value` preloaded. Resolved in two queries (no N+1), regardless of the
  number of parents.
  """
  @spec list_component_entries_by_parent(Scope.t(), [pos_integer()], pos_integer()) ::
          %{pos_integer() => [AssessmentPointEntry.t()]}
  def list_component_entries_by_parent(%Scope{} = scope, parent_ids, student_id) do
    pairs = list_parent_component_pairs(scope, parent_ids)
    component_ids = pairs |> Enum.map(&elem(&1, 1)) |> Enum.uniq()

    entries_by_ap =
      from(e in AssessmentPointEntry,
        join: ap in assoc(e, :assessment_point),
        left_join: ov in assoc(e, :ordinal_value),
        left_join: s_ov in assoc(e, :student_ordinal_value),
        where: e.assessment_point_id in ^component_ids and e.student_id == ^student_id,
        where: ap.is_hidden == false,
        preload: [ordinal_value: ov, student_ordinal_value: s_ov]
      )
      |> Repo.all()
      |> Map.new(&{&1.assessment_point_id, &1})

    Enum.reduce(pairs, %{}, fn {parent_id, component_id}, acc ->
      case Map.get(entries_by_ap, component_id) do
        nil -> acc
        entry -> Map.update(acc, parent_id, [entry], &(&1 ++ [entry]))
      end
    end)
  end

  @doc """
  Creates an assessment point composition component.

  ## Examples

      iex> create_assessment_point_component(scope, %{parent_id: 1, component_id: 2})
      {:ok, %Component{}}

      iex> create_assessment_point_component(scope, %{})
      {:error, %Ecto.Changeset{}}

  """
  def create_assessment_point_component(%Scope{} = scope, attrs \\ %{}) do
    true = Scope.profile_type?(scope, "staff")

    component_id = Map.get(attrs, :component_id, Map.get(attrs, "component_id"))

    %Component{}
    |> Component.changeset(attrs, composed_component_ids(List.wrap(component_id)))
    |> Repo.insert()
  end

  @doc """
  Updates an assessment point composition component.

  ## Examples

      iex> update_assessment_point_component(scope, component, %{weight: 2.0})
      {:ok, %Component{}}

      iex> update_assessment_point_component(scope, component, %{weight: -1.0})
      {:error, %Ecto.Changeset{}}

  """
  def update_assessment_point_component(%Scope{} = scope, %Component{} = component, attrs) do
    true = Scope.profile_type?(scope, "staff")

    component_id =
      Map.get(attrs, :component_id, Map.get(attrs, "component_id")) || component.component_id

    component
    |> Component.changeset(attrs, composed_component_ids(List.wrap(component_id)))
    |> Repo.update()
  end

  @doc """
  Deletes an assessment point composition component.
  """
  def delete_assessment_point_component(%Scope{} = scope, %Component{} = component) do
    true = Scope.profile_type?(scope, "staff")

    Repo.delete(component)
  end

  @doc """
  Deletes all composition components for the given parent assessment point id.
  """
  def delete_all_assessment_point_components(%Scope{} = scope, parent_id) do
    true = Scope.profile_type?(scope, "staff")

    from(c in Component, where: c.parent_id == ^parent_id)
    |> Repo.delete_all()

    :ok
  end

  @doc """
  Atomically replaces all composition components for the given parent assessment point.

  Deletes existing components and inserts the new ones within a single transaction.
  `components` is a list of maps with `:component_id` and `:weight` keys.

  Returns `{:ok, :replaced}` on success or `{:error, changeset}` on validation failure.
  """
  def replace_assessment_point_components(%Scope{} = scope, parent_id, components) do
    true = Scope.profile_type?(scope, "staff")

    composed_ids = composed_component_ids(Enum.map(components, & &1.component_id))

    delete_query = from(c in Component, where: c.parent_id == ^parent_id)

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.delete_all(:delete_existing, delete_query)

    multi =
      components
      |> Enum.with_index()
      |> Enum.reduce(multi, fn {%{component_id: component_id, weight: weight}, index}, multi ->
        changeset =
          Component.changeset(
            %Component{},
            %{parent_id: parent_id, component_id: component_id, weight: weight},
            composed_ids
          )

        Ecto.Multi.insert(multi, {:insert, index}, changeset)
      end)

    # enqueue the recalc inside the transaction so a saved composition always has
    # a scheduled recalc (and a rolled-back save never enqueues a stale one)
    multi =
      Oban.insert(
        multi,
        :recalc_job,
        Lanttern.Workers.CompositionRecalcWorker.new(%{
          parent_id: parent_id,
          profile_id: scope.profile_id
        })
      )

    case Repo.transaction(multi) do
      {:ok, _} -> {:ok, :replaced}
      {:error, _op, changeset, _changes} -> {:error, changeset}
    end
  end

  defp composed_component_ids([]), do: []

  defp composed_component_ids(component_ids) do
    from(ap in AssessmentPoint,
      where: ap.id in ^component_ids and ap.uses_composition == true,
      select: ap.id
    )
    |> Repo.all()
  end

  @doc """
  Given a list of `{component_ap_id, student_id}` tuples corresponding to
  assessment point entries that were just saved, returns the distinct
  `{parent_ap_id, student_id}` tuples whose parent assessment point uses
  composition (sum- or average-based).

  Used to determine which composed assessment point entries need to be
  recalculated after a batch save.
  """
  @spec list_composed_parent_pairs([{pos_integer(), pos_integer()}]) ::
          [{pos_integer(), pos_integer()}]
  def list_composed_parent_pairs([]), do: []

  def list_composed_parent_pairs(component_student_pairs) do
    component_ids =
      component_student_pairs
      |> Enum.map(fn {component_id, _student_id} -> component_id end)
      |> Enum.uniq()

    parent_to_components =
      from(c in Component,
        join: parent in AssessmentPoint,
        on: parent.id == c.parent_id,
        where: c.component_id in ^component_ids and parent.uses_composition == true,
        select: {c.parent_id, c.component_id}
      )
      |> Repo.all()

    for {parent_id, component_id} <- parent_to_components,
        {^component_id, student_id} <- component_student_pairs,
        uniq: true,
        do: {parent_id, student_id}
  end

  @doc """
  Returns the parent assessment point ids for which the given assessment point
  is a composition component.

  Used to recalculate the affected parents when a component assessment point is
  deleted (its `Component` rows cascade away, so callers must capture this
  before the deletion).
  """
  @spec list_composition_parent_ids(pos_integer()) :: [pos_integer()]
  def list_composition_parent_ids(component_ap_id) do
    from(c in Component, where: c.component_id == ^component_ap_id, select: c.parent_id)
    |> Repo.all()
  end

  @doc """
  Returns the composed (parent) assessment points that use the given assessment
  point as a composition component.

  Ordered for display and preloaded with `curriculum_item: :curriculum_component`
  so callers can render a name/curriculum label. Used by the UI to explain why a
  component assessment point can't have its own grade composition.
  """
  @spec list_compositions_using_component(Scope.t(), pos_integer()) :: [AssessmentPoint.t()]
  # `scope` is intentionally unused for now: callers already operate on an
  # assessment point loaded within the current user's context, so no extra
  # school-level filtering is applied here.
  def list_compositions_using_component(%Scope{} = _scope, component_ap_id) do
    from(c in Component,
      join: parent in AssessmentPoint,
      on: parent.id == c.parent_id,
      where: c.component_id == ^component_ap_id,
      order_by: [asc_nulls_last: parent.moment_id, asc: parent.position],
      select: parent
    )
    |> Repo.all()
    |> Repo.preload(curriculum_item: :curriculum_component)
  end

  @doc """
  Returns the teacher-domain composition breakdown for a composed (parent)
  assessment point and student, for display in the UI.

  The returned map contains:

    * `:scale_type` — the parent scale type (`"numeric"` for sum-based,
      `"ordinal"` for average-based compositions)
    * `:components` — one row per composition component, each a map with
      `:assessment_point`, `:weight`, `:ordinal_value`, `:score`,
      `:normalized_value` (0–1, or `nil` when the component has no value),
      `:is_missing` and `:has_marking`
    * `:total_weight` — the sum of the weights that actually contribute to the
      average (components with a numeric normalized value), mirroring the
      denominator used by the average composition calculation
    * `:composed` — the composed (parent) entry summary: `:ordinal_value`,
      `:score`, `:normalized_value` and the parent scale `:max_score`

  Only the teacher edit domain is currently supported (the student domain is a
  straightforward extension following the same field mapping used by
  `recalculate_composed_entries/3`).
  """
  @spec get_composition_breakdown(Scope.t(), pos_integer(), pos_integer()) :: %{
          scale_type: String.t(),
          components: [map()],
          total_weight: float(),
          composed: map()
        }
  def get_composition_breakdown(%Scope{} = scope, parent_id, student_id) do
    parent =
      AssessmentPoint
      |> Repo.get(parent_id)
      |> Repo.preload(:scale)

    components = list_assessment_point_components(scope, parent_id)
    component_ids = Enum.map(components, & &1.component_id)

    entries_by_ap =
      from(e in AssessmentPointEntry,
        where: e.assessment_point_id in ^component_ids and e.student_id == ^student_id,
        preload: [:scale, :ordinal_value]
      )
      |> Repo.all()
      |> Map.new(&{&1.assessment_point_id, &1})

    rows = Enum.map(components, &build_breakdown_row(&1, entries_by_ap))

    total_weight =
      rows
      |> Enum.filter(&is_number(&1.normalized_value))
      |> Enum.reduce(0.0, fn row, acc -> acc + row.weight end)

    %{
      scale_type: parent.scale.type,
      components: rows,
      total_weight: total_weight,
      composed: build_composed_summary(parent, parent_id, student_id)
    }
  end

  defp build_breakdown_row(component, entries_by_ap) do
    case Map.get(entries_by_ap, component.component_id) do
      nil ->
        %{
          assessment_point: component.component,
          weight: component.weight,
          ordinal_value: nil,
          score: nil,
          normalized_value: nil,
          is_missing: false,
          has_marking: false
        }

      entry ->
        %{
          assessment_point: component.component,
          weight: component.weight,
          ordinal_value: entry.ordinal_value,
          score: entry.score,
          normalized_value: normalized_value(entry, :teacher_entry),
          is_missing: entry.is_missing,
          has_marking: entry.has_marking
        }
    end
  end

  defp build_composed_summary(parent, parent_id, student_id) do
    case get_existing_parent_entry(parent_id, student_id) do
      nil ->
        %{
          ordinal_value: nil,
          score: nil,
          normalized_value: nil,
          max_score: parent.scale.max_score
        }

      entry ->
        entry = Repo.preload(entry, :ordinal_value)

        %{
          ordinal_value: entry.ordinal_value,
          score: entry.score,
          normalized_value: entry.normalized_value,
          max_score: parent.scale.max_score
        }
    end
  end

  @doc """
  Recalculates composed assessment point entries for the given `{parent_id, student_id}` pairs.

  The `domain` argument selects the edit domain — teacher entries
  (`:teacher_entry`) or student entries (`:student_entry`). The actual
  parent field that gets written depends on the parent's scale type:

  | domain           | numeric parent (sum)  | ordinal parent (average)    |
  |------------------|-----------------------|-----------------------------|
  | `:teacher_entry` | `:score`              | `:ordinal_value_id`         |
  | `:student_entry` | `:student_score`      | `:student_ordinal_value_id` |

  Pairs whose parent does not use composition are silently skipped.

  **Sum (numeric parent):** sums the domain's score field across the
  parent's component entries. When the recomputed value exceeds the
  parent's `scale.max_score`, the composed entry's `calculation_error` is
  set to `"max_score_overflow"` and the target field is left untouched.

  **Average (ordinal parent):** computes a weighted mean of each child's
  normalized value (0–1) using the component weights, then converts the
  result back to an `OrdinalValue` via the parent scale's breakpoints.
  When the conversion fails (misconfigured breakpoints / ordinal values),
  `calculation_error` is set to `"scale_conversion_failed"` and the
  target field is left untouched.

  Audit log rows are created via `Lanttern.AssessmentsLog` using the
  `scope.profile_id` as the actor.
  """
  @spec recalculate_composed_entries(
          Scope.t(),
          [{pos_integer(), pos_integer()}],
          :teacher_entry | :student_entry
        ) :: :ok
  def recalculate_composed_entries(%Scope{} = scope, pairs, domain)
      when domain in [:teacher_entry, :student_entry] do
    pairs
    |> Enum.uniq()
    |> Enum.group_by(
      fn {parent_id, _student_id} -> parent_id end,
      fn {_parent_id, student_id} -> student_id end
    )
    |> Enum.each(fn {parent_id, student_ids} ->
      recalculate_parent_composed_entries(scope, parent_id, student_ids, domain)
    end)

    :ok
  end

  @doc """
  Recalculates every composed entry for the given parent assessment point,
  in the teacher edit domain.

  Only the teacher domain is auto-recalculated: composed student entries are no
  longer derived automatically (they surfaced in the student/guardian view as a
  self-assessment), pending a redesign of student self-assessment. The engine
  still supports the `:student_entry` domain via `recalculate_composed_entries/3`
  for when that redesign lands.

  Resolves the affected students from the parent's component entries (the
  composition inputs) and from any existing entries on the parent itself — the
  latter ensures stale entries are recomputed (or cleared) when components are
  removed during an update. Delegates the actual calculation to
  `recalculate_composed_entries/3`.
  """
  @spec recalculate_all_composed_entries(Scope.t(), pos_integer()) :: :ok
  def recalculate_all_composed_entries(%Scope{} = scope, parent_id) do
    pairs = composed_pairs_for_parent(parent_id)
    recalculate_composed_entries(scope, pairs, :teacher_entry)
    :ok
  end

  @doc """
  Returns the composition sync status for every composed assessment point in a
  strand, comparing each stored composed entry against the value recomputed from
  its components — without writing anything.

  Admin only (`scope.is_root_admin` must be true).

  Only the teacher edit domain is checked, mirroring what the recalculation
  actually maintains (see `recalculate_all_composed_entries/2`).

  The returned map contains entry-level counts and a list of the out-of-sync
  entries:

    * `:total_count` — relevant composed entries (`{parent, student}` pairs that
      the recalculation would consider)
    * `:in_sync_count` / `:out_of_sync_count` / `:manual_input_count` — split of
      `:total_count`; a pair is out of sync when its teacher composed value has
      drifted, and counted under `:manual_input_count` when the composed entry
      was switched to manual input (which the sync leaves untouched, mirroring
      `recalculate_student/8`) — those never count as in or out of sync
    * `:out_of_sync` — one row per drifted entry. Each row is a map with
      `:student`, `:assessment_point` (the composed parent), `:scale_type`,
      `:domain` (always `:teacher_entry`) and `:stored` / `:expected` value
      summaries (`%{score, normalized_value, ordinal_value}`)

  This mirrors exactly what `sync_strand_composed_entries/2` would change, so the
  counts stay consistent across a check → sync → re-check cycle.
  """
  @spec list_strand_composition_sync_status(Scope.t(), pos_integer()) :: %{
          total_count: non_neg_integer(),
          in_sync_count: non_neg_integer(),
          out_of_sync_count: non_neg_integer(),
          manual_input_count: non_neg_integer(),
          out_of_sync: [map()]
        }
  def list_strand_composition_sync_status(%Scope{} = scope, strand_id) do
    true = scope.is_root_admin

    parents =
      from(ap in AssessmentPoint,
        where: ap.strand_id == ^strand_id and ap.uses_composition == true,
        order_by: [asc_nulls_last: ap.moment_id, asc: ap.position],
        preload: [scale: :ordinal_values, curriculum_item: :curriculum_component]
      )
      |> Repo.all()

    results = Enum.map(parents, &parent_sync_status/1)

    total_count = Enum.sum(Enum.map(results, & &1.total))
    out_of_sync_count = Enum.sum(Enum.map(results, & &1.out_of_sync_count))
    manual_input_count = Enum.sum(Enum.map(results, & &1.manual_count))

    %{
      total_count: total_count,
      in_sync_count: total_count - out_of_sync_count - manual_input_count,
      out_of_sync_count: out_of_sync_count,
      manual_input_count: manual_input_count,
      out_of_sync: Enum.flat_map(results, & &1.rows)
    }
  end

  @doc """
  Recalculates every composed entry of every composed assessment point in a
  strand, in the teacher edit domain (see `recalculate_all_composed_entries/2`).

  Admin only (`scope.is_root_admin` must be true). Delegates to the idempotent
  `recalculate_all_composed_entries/2`, so in-sync entries are left untouched
  (no DB write, no audit-log row).
  """
  @spec sync_strand_composed_entries(Scope.t(), pos_integer()) :: :ok
  def sync_strand_composed_entries(%Scope{} = scope, strand_id) do
    true = scope.is_root_admin

    from(ap in AssessmentPoint,
      where: ap.strand_id == ^strand_id and ap.uses_composition == true,
      select: ap.id
    )
    |> Repo.all()
    |> Enum.each(&recalculate_all_composed_entries(scope, &1))

    :ok
  end

  defp parent_sync_status(parent) do
    student_ids =
      parent.id
      |> composed_pairs_for_parent()
      |> Enum.map(fn {_parent_id, student_id} -> student_id end)

    case {composition_mode(parent), student_ids} do
      {nil, _} ->
        %{total: 0, out_of_sync_count: 0, manual_count: 0, rows: []}

      {_mode, []} ->
        %{total: 0, out_of_sync_count: 0, manual_count: 0, rows: []}

      {mode, student_ids} ->
        compute_parent_sync_status(parent, mode, student_ids)
    end
  end

  defp composition_mode(%AssessmentPoint{uses_composition: true, scale: %{type: "numeric"}}),
    do: :sum

  defp composition_mode(%AssessmentPoint{uses_composition: true, scale: %{type: "ordinal"}}),
    do: :avg

  defp composition_mode(_parent), do: nil

  # Runs a handful of queries *per composed parent* (components, component
  # entries, existing parent entries, students). That's fine for the admin check
  # over a single strand — composed assessment points per strand are few — but
  # it is not meant to be run across many strands at once.
  defp compute_parent_sync_status(parent, mode, student_ids) do
    components = Repo.all(from c in Component, where: c.parent_id == ^parent.id)
    component_ids = Enum.map(components, & &1.component_id)
    weight_by_component = Map.new(components, &{&1.component_id, &1.weight})

    entries_by_student =
      from(e in AssessmentPointEntry,
        where: e.assessment_point_id in ^component_ids and e.student_id in ^student_ids,
        preload: [:scale, :ordinal_value, :student_ordinal_value]
      )
      |> Repo.all()
      |> Enum.group_by(& &1.student_id)

    existing_by_student =
      from(e in AssessmentPointEntry,
        where: e.assessment_point_id == ^parent.id and e.student_id in ^student_ids
      )
      |> Repo.all()
      |> Map.new(&{&1.student_id, &1})

    students_by_id =
      from(s in Lanttern.Schools.Student, where: s.id in ^student_ids)
      |> Repo.all()
      |> Map.new(&{&1.id, &1})

    ordinal_values_by_id = Map.new(parent.scale.ordinal_values, &{&1.id, &1})

    {rows, out_of_sync_count, manual_count} =
      Enum.reduce(student_ids, {[], 0, 0}, fn student_id, acc ->
        classify_student_sync(
          parent,
          mode,
          Map.get(students_by_id, student_id),
          Map.get(entries_by_student, student_id, []),
          weight_by_component,
          Map.get(existing_by_student, student_id),
          ordinal_values_by_id,
          acc
        )
      end)

    %{
      total: Enum.count(student_ids),
      out_of_sync_count: out_of_sync_count,
      manual_count: manual_count,
      rows: rows
    }
  end

  # manual-input entries are left untouched by the sync (mirrors
  # `recalculate_student/8`), so they count toward neither in nor out of sync
  defp classify_student_sync(
         _parent,
         _mode,
         _student,
         _entries,
         _weights,
         %{use_manual_input: true},
         _ordinal_values_by_id,
         {rows, out_of_sync_count, manual_count}
       ),
       do: {rows, out_of_sync_count, manual_count + 1}

  defp classify_student_sync(
         parent,
         mode,
         student,
         entries,
         weights,
         existing,
         ordinal_values_by_id,
         {rows, out_of_sync_count, manual_count}
       ) do
    {student_rows, is_out_of_sync} =
      student_sync_rows(parent, mode, student, entries, weights, existing, ordinal_values_by_id)

    {rows ++ student_rows, out_of_sync_count + if(is_out_of_sync, do: 1, else: 0), manual_count}
  end

  # Only the teacher domain is checked: composed student entries are no longer
  # maintained automatically (see `recalculate_all_composed_entries/2`), so the
  # sync must not report drift on student fields it would never write.
  defp student_sync_rows(parent, mode, student, entries, weights, existing, ordinal_values_by_id) do
    domain = :teacher_entry

    {attrs, target_error} =
      case mode do
        :sum -> compute_sum_target(parent, domain, entries, existing)
        :avg -> compute_avg_target(parent, domain, entries, weights, existing)
      end

    case domain_sync_row(parent, mode, student, domain, attrs, target_error, existing,
           ordinal_values_by_id: ordinal_values_by_id
         ) do
      :in_sync -> {[], false}
      {:out_of_sync, row} -> {[row], true}
    end
  end

  defp domain_sync_row(parent, mode, student, domain, attrs, target_error, existing, opts) do
    ordinal_values_by_id = Keyword.fetch!(opts, :ordinal_values_by_id)
    primary = primary_target_field(mode, domain)
    expected_primary = Map.get(attrs, primary)
    stored_primary = existing && Map.get(existing, primary)

    has_value = not is_nil(expected_primary) or not is_nil(stored_primary)

    in_sync? =
      not is_nil(existing) and
        Enum.all?(attrs, fn {field, value} -> Map.get(existing, field) == value end) and
        target_error == existing.calculation_error

    if not has_value or in_sync? do
      :in_sync
    else
      {:out_of_sync,
       %{
         student: student,
         assessment_point: parent,
         scale_type: parent.scale.type,
         domain: domain,
         stored: build_value_summary(mode, domain, existing, ordinal_values_by_id),
         expected: build_value_summary(mode, domain, attrs, ordinal_values_by_id)
       }}
    end
  end

  defp primary_target_field(:sum, domain), do: sum_target_field(domain)
  defp primary_target_field(:avg, domain), do: avg_target_field(domain)

  # `source` is either the existing entry struct or the computed attrs map; both
  # respond to `Map.get/2` for the relevant fields.
  defp build_value_summary(:sum, domain, source, _ordinal_values_by_id) do
    %{
      score: read_field(source, sum_target_field(domain)),
      normalized_value: nil,
      ordinal_value: nil
    }
  end

  defp build_value_summary(:avg, domain, source, ordinal_values_by_id) do
    ordinal_value_id = read_field(source, avg_target_field(domain))

    %{
      score: nil,
      normalized_value: read_field(source, normalized_target_field(domain)),
      ordinal_value: ordinal_value_id && Map.get(ordinal_values_by_id, ordinal_value_id)
    }
  end

  defp read_field(nil, _field), do: nil
  defp read_field(source, field), do: Map.get(source, field)

  defp composed_pairs_for_parent(parent_id) do
    component_ids =
      from(c in Component, where: c.parent_id == ^parent_id, select: c.component_id)
      |> Repo.all()

    ap_ids = [parent_id | component_ids]

    from(e in AssessmentPointEntry,
      where: e.assessment_point_id in ^ap_ids and e.has_marking,
      distinct: true,
      select: e.student_id
    )
    |> Repo.all()
    |> Enum.map(&{parent_id, &1})
  end

  defp recalculate_parent_composed_entries(scope, parent_id, student_ids, domain) do
    parent =
      AssessmentPoint
      |> Repo.get(parent_id)
      |> Repo.preload(:scale)

    case composition_mode(parent) do
      nil ->
        :ok

      mode ->
        maybe_warn_cascading_composition(parent_id)
        do_recalculate_parent(scope, parent, student_ids, domain, mode)
    end
  end

  # Loads the parent's components and every relevant entry once (instead of
  # per student) and recomputes each student's composed entry in memory.
  defp do_recalculate_parent(scope, parent, student_ids, domain, mode) do
    components = Repo.all(from c in Component, where: c.parent_id == ^parent.id)
    component_ids = Enum.map(components, & &1.component_id)
    weight_by_component = Map.new(components, &{&1.component_id, &1.weight})

    entries_by_student =
      from(e in AssessmentPointEntry,
        where: e.assessment_point_id in ^component_ids and e.student_id in ^student_ids,
        preload: [:scale, :ordinal_value, :student_ordinal_value]
      )
      |> Repo.all()
      |> Enum.group_by(& &1.student_id)

    existing_by_student =
      from(e in AssessmentPointEntry,
        where: e.assessment_point_id == ^parent.id and e.student_id in ^student_ids
      )
      |> Repo.all()
      |> Map.new(&{&1.student_id, &1})

    Enum.each(student_ids, fn student_id ->
      recalculate_student(
        scope,
        parent,
        student_id,
        domain,
        mode,
        Map.get(entries_by_student, student_id, []),
        weight_by_component,
        Map.get(existing_by_student, student_id)
      )
    end)
  end

  defp recalculate_student(scope, parent, student_id, domain, mode, entries, weights, existing) do
    cond do
      # the composed entry was switched to manual input — leave it untouched
      match?(%AssessmentPointEntry{use_manual_input: true}, existing) ->
        :ok

      mode == :sum ->
        recalculate_sum(scope, parent, student_id, domain, entries, existing)

      mode == :avg ->
        recalculate_avg(scope, parent, student_id, domain, entries, weights, existing)
    end
  end

  defp recalculate_sum(scope, parent, student_id, domain, entries, existing) do
    {attrs, target_error} = compute_sum_target(parent, domain, entries, existing)
    do_upsert(scope, parent, student_id, attrs, target_error, existing)
  end

  defp recalculate_avg(scope, parent, student_id, domain, entries, weight_by_component, existing) do
    {attrs, target_error} =
      compute_avg_target(parent, domain, entries, weight_by_component, existing)

    do_upsert(scope, parent, student_id, attrs, target_error, existing)
  end

  # Pure computation of a sum-composed entry's target attrs — shared by the
  # recalculation pipeline and the read-only sync-status check so both derive
  # the expected value the same way.
  defp compute_sum_target(parent, domain, entries, existing) do
    field = sum_target_field(domain)
    recomputed = compute_sum(entries, field)
    max_score = parent.scale.max_score

    overflow? = is_number(recomputed) and is_number(max_score) and recomputed > max_score

    {target_value, target_error} =
      if overflow? do
        {existing && Map.get(existing, field), "max_score_overflow"}
      else
        {recomputed, nil}
      end

    {%{field => target_value}, target_error}
  end

  # Pure computation of an average-composed entry's target attrs — shared by the
  # recalculation pipeline and the read-only sync-status check.
  defp compute_avg_target(parent, domain, entries, weight_by_component, existing) do
    field = avg_target_field(domain)
    normalized_field = normalized_target_field(domain)

    normalized_avg = compute_weighted_avg(entries, weight_by_component, domain)

    resolve_avg_target(normalized_avg, parent.scale, existing, field, normalized_field)
  end

  defp sum_target_field(:teacher_entry), do: :score
  defp sum_target_field(:student_entry), do: :student_score

  defp avg_target_field(:teacher_entry), do: :ordinal_value_id
  defp avg_target_field(:student_entry), do: :student_ordinal_value_id

  defp normalized_target_field(:teacher_entry), do: :normalized_value
  defp normalized_target_field(:student_entry), do: :student_normalized_value

  defp get_existing_parent_entry(parent_id, student_id) do
    Repo.one(
      from e in AssessmentPointEntry,
        where: e.assessment_point_id == ^parent_id and e.student_id == ^student_id
    )
  end

  defp compute_sum(entries, field) do
    values =
      entries
      |> Enum.map(fn
        %AssessmentPointEntry{is_missing: true} -> 0
        entry -> Map.get(entry, field)
      end)
      |> Enum.reject(&is_nil/1)

    case values do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp compute_weighted_avg(entries, weight_by_component, domain) do
    {sumprod, sumweight} =
      Enum.reduce(entries, {0.0, 0.0}, fn entry, {sumprod, sumweight} ->
        with normalized when is_number(normalized) <- normalized_value(entry, domain),
             weight when is_number(weight) <-
               Map.get(weight_by_component, entry.assessment_point_id) do
          {sumprod + normalized * weight, sumweight + weight}
        else
          _ -> {sumprod, sumweight}
        end
      end)

    # round to 5 decimals to avoid float-representation noise in the stored
    # normalized value, mirroring the grades-report composition convention
    if sumweight > 0, do: Float.round(sumprod / sumweight, 5), else: nil
  end

  defp normalized_value(%AssessmentPointEntry{is_missing: true}, _domain), do: 0.0

  defp normalized_value(%AssessmentPointEntry{scale_type: "ordinal"} = entry, :teacher_entry),
    do: entry.ordinal_value && entry.ordinal_value.normalized_value

  defp normalized_value(%AssessmentPointEntry{scale_type: "numeric"} = entry, :teacher_entry) do
    if is_number(entry.score) and entry.scale, do: entry.score / entry.scale.max_score
  end

  defp normalized_value(%AssessmentPointEntry{scale_type: "ordinal"} = entry, :student_entry),
    do: entry.student_ordinal_value && entry.student_ordinal_value.normalized_value

  defp normalized_value(%AssessmentPointEntry{scale_type: "numeric"} = entry, :student_entry) do
    if is_number(entry.student_score) and entry.scale,
      do: entry.student_score / entry.scale.max_score
  end

  defp resolve_avg_target(nil, _scale, _existing, field, normalized_field),
    do: {%{field => nil, normalized_field => nil}, nil}

  defp resolve_avg_target(normalized_avg, scale, existing, field, normalized_field) do
    case Grading.convert_normalized_value_to_scale_value(normalized_avg, scale) do
      %OrdinalValue{id: id} ->
        {%{field => id, normalized_field => normalized_avg}, nil}

      nil ->
        # conversion failed — leave both the ordinal value and the stored
        # normalized value untouched
        attrs = %{
          field => existing && Map.get(existing, field),
          normalized_field => existing && Map.get(existing, normalized_field)
        }

        {attrs, "scale_conversion_failed"}
    end
  end

  defp do_upsert(scope, _parent, _student_id, attrs, target_error, existing)
       when not is_nil(existing) do
    update_existing_parent_entry(scope, existing, attrs, target_error)
  end

  defp do_upsert(scope, parent, student_id, attrs, target_error, nil) do
    base = %{
      assessment_point_id: parent.id,
      student_id: student_id,
      scale_id: parent.scale_id,
      scale_type: parent.scale.type,
      calculation_error: target_error
    }

    %AssessmentPointEntry{}
    |> AssessmentPointEntry.changeset(Map.merge(base, attrs))
    |> Repo.insert()
    |> case do
      {:ok, %AssessmentPointEntry{} = entry} ->
        log_upsert({:ok, entry}, scope, "CREATE")

      {:error, %Ecto.Changeset{} = changeset} ->
        recover_from_insert_conflict(changeset, scope, parent, student_id, attrs, target_error)
    end
  end

  # a concurrent recalc (e.g. the other edit domain) may have inserted the parent
  # entry between our existence check and this insert — recover by reloading and
  # applying this domain's values as an update; otherwise surface the error
  defp recover_from_insert_conflict(changeset, scope, parent, student_id, attrs, target_error) do
    with true <- unique_conflict?(changeset),
         %AssessmentPointEntry{} = existing <- get_existing_parent_entry(parent.id, student_id) do
      update_existing_parent_entry(scope, existing, attrs, target_error)
    else
      _ -> {:error, changeset}
    end
  end

  defp update_existing_parent_entry(scope, existing, attrs, target_error) do
    unchanged? =
      Enum.all?(attrs, fn {field, value} -> Map.get(existing, field) == value end) and
        target_error == existing.calculation_error

    if unchanged? do
      :noop
    else
      existing
      |> AssessmentPointEntry.changeset(Map.put(attrs, :calculation_error, target_error))
      |> Repo.update()
      |> log_upsert(scope, "UPDATE")
    end
  end

  defp unique_conflict?(%Ecto.Changeset{errors: errors}) do
    Enum.any?(errors, fn
      {_field, {_msg, opts}} -> Keyword.get(opts, :constraint) == :unique
      _ -> false
    end)
  end

  defp log_upsert(
         {:ok, %AssessmentPointEntry{} = entry},
         %Scope{profile_id: profile_id},
         operation
       ) do
    AssessmentsLog.prepare_and_create_assessment_point_entry_log(entry, operation, profile_id)
    :ok
  end

  defp log_upsert({:error, _changeset} = error, _scope, _operation), do: error

  defp maybe_warn_cascading_composition(parent_id) do
    exists? =
      Repo.exists?(from c in Component, where: c.component_id == ^parent_id)

    if exists? do
      Logger.warning(
        "Composed assessment point #{parent_id} is itself a component of another composed assessment point — cascading recalculation is not yet supported."
      )
    end
  end
end
