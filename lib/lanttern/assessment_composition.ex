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
  Creates an assessment point composition component.

  ## Examples

      iex> create_assessment_point_component(scope, %{parent_id: 1, component_id: 2})
      {:ok, %Component{}}

      iex> create_assessment_point_component(scope, %{})
      {:error, %Ecto.Changeset{}}

  """
  def create_assessment_point_component(%Scope{} = scope, attrs \\ %{}) do
    true = Scope.profile_type?(scope, "staff")

    %Component{}
    |> Component.changeset(attrs)
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

    component
    |> Component.changeset(attrs)
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

    delete_query = from(c in Component, where: c.parent_id == ^parent_id)

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.delete_all(:delete_existing, delete_query)

    multi =
      components
      |> Enum.with_index()
      |> Enum.reduce(multi, fn {%{component_id: component_id, weight: weight}, index}, multi ->
        changeset =
          Component.changeset(%Component{}, %{
            parent_id: parent_id,
            component_id: component_id,
            weight: weight
          })

        Ecto.Multi.insert(multi, {:insert, index}, changeset)
      end)

    case Repo.transaction(multi) do
      {:ok, _} ->
        %{parent_id: parent_id, profile_id: scope.profile_id}
        |> Lanttern.Workers.CompositionRecalcWorker.new()
        |> Oban.insert()

        {:ok, :replaced}

      {:error, _op, changeset, _changes} ->
        {:error, changeset}
    end
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
    |> Enum.each(&recalculate_composed_entry(scope, &1, domain))

    :ok
  end

  @doc """
  Recalculates every composed entry for the given parent assessment point,
  across both edit domains.

  Resolves the affected students from the parent's component entries (the
  composition inputs) and from any existing entries on the parent itself — the
  latter ensures stale entries are recomputed (or cleared) when components are
  removed during an update. Delegates the actual calculation to
  `recalculate_composed_entries/3`.
  """
  @spec recalculate_all_composed_entries(Scope.t(), pos_integer()) :: :ok
  def recalculate_all_composed_entries(%Scope{} = scope, parent_id) do
    pairs = composed_pairs_for_parent(parent_id)

    Enum.each([:teacher_entry, :student_entry], fn domain ->
      recalculate_composed_entries(scope, pairs, domain)
    end)

    :ok
  end

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

  defp recalculate_composed_entry(%Scope{} = scope, {parent_id, student_id}, domain) do
    parent =
      AssessmentPoint
      |> Repo.get(parent_id)
      |> Repo.preload(:scale)

    existing = get_existing_parent_entry(parent_id, student_id)

    cond do
      # the composed entry was switched to manual input — leave it untouched
      match?(%AssessmentPointEntry{use_manual_input: true}, existing) ->
        :ok

      match?(%AssessmentPoint{uses_composition: true, scale: %{type: "numeric"}}, parent) ->
        maybe_warn_cascading_composition(parent_id)
        recalculate_sum(scope, parent, student_id, domain, existing)

      match?(%AssessmentPoint{uses_composition: true, scale: %{type: "ordinal"}}, parent) ->
        maybe_warn_cascading_composition(parent_id)
        recalculate_avg(scope, parent, student_id, domain, existing)

      true ->
        :ok
    end
  end

  defp recalculate_sum(scope, parent, student_id, domain, existing) do
    field = sum_target_field(domain)

    components = Repo.all(from c in Component, where: c.parent_id == ^parent.id)
    component_ids = Enum.map(components, & &1.component_id)

    entries =
      Repo.all(
        from e in AssessmentPointEntry,
          where: e.assessment_point_id in ^component_ids and e.student_id == ^student_id
      )

    recomputed = compute_sum(entries, field)

    overflow? = is_number(recomputed) and recomputed > parent.scale.max_score

    {target_value, target_error} =
      if overflow? do
        {existing && Map.get(existing, field), "max_score_overflow"}
      else
        {recomputed, nil}
      end

    do_upsert(scope, parent, student_id, field, target_value, target_error, existing)
  end

  defp recalculate_avg(scope, parent, student_id, domain, existing) do
    field = avg_target_field(domain)

    components = Repo.all(from c in Component, where: c.parent_id == ^parent.id)
    component_ids = Enum.map(components, & &1.component_id)
    weight_by_component = Map.new(components, &{&1.component_id, &1.weight})

    entries =
      Repo.all(
        from e in AssessmentPointEntry,
          where: e.assessment_point_id in ^component_ids and e.student_id == ^student_id,
          preload: [:scale, :ordinal_value, :student_ordinal_value]
      )

    normalized_avg = compute_weighted_avg(entries, weight_by_component, domain)

    {target_value, target_error} =
      resolve_avg_target(normalized_avg, parent.scale, existing, field)

    do_upsert(scope, parent, student_id, field, target_value, target_error, existing)
  end

  defp sum_target_field(:teacher_entry), do: :score
  defp sum_target_field(:student_entry), do: :student_score

  defp avg_target_field(:teacher_entry), do: :ordinal_value_id
  defp avg_target_field(:student_entry), do: :student_ordinal_value_id

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

    if sumweight > 0, do: sumprod / sumweight, else: nil
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

  defp resolve_avg_target(nil, _scale, _existing, _field), do: {nil, nil}

  defp resolve_avg_target(normalized_avg, scale, existing, field) do
    case Grading.convert_normalized_value_to_scale_value(normalized_avg, scale) do
      %OrdinalValue{id: id} ->
        {id, nil}

      nil ->
        {existing && Map.get(existing, field), "scale_conversion_failed"}
    end
  end

  defp do_upsert(scope, _parent, _student_id, field, target_value, target_error, existing)
       when not is_nil(existing) do
    current_value = Map.get(existing, field)

    if target_value == current_value and target_error == existing.calculation_error do
      :noop
    else
      existing
      |> AssessmentPointEntry.changeset(%{
        field => target_value,
        :calculation_error => target_error
      })
      |> Repo.update()
      |> log_upsert(scope, "UPDATE")
    end
  end

  defp do_upsert(scope, parent, student_id, field, target_value, target_error, _existing) do
    %AssessmentPointEntry{}
    |> AssessmentPointEntry.changeset(%{
      :assessment_point_id => parent.id,
      :student_id => student_id,
      :scale_id => parent.scale_id,
      :scale_type => parent.scale.type,
      field => target_value,
      :calculation_error => target_error
    })
    |> Repo.insert()
    |> log_upsert(scope, "CREATE")
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
