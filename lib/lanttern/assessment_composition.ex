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
      {:ok, _} -> {:ok, :replaced}
      {:error, _op, changeset, _changes} -> {:error, changeset}
    end
  end

  @doc """
  Given a list of `{component_ap_id, student_id}` tuples corresponding to
  assessment point entries that were just saved, returns the distinct
  `{parent_ap_id, student_id}` tuples whose parent assessment point uses
  `composition_type: :sum`.

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
        where: c.component_id in ^component_ids and parent.composition_type == :sum,
        select: {c.parent_id, c.component_id}
      )
      |> Repo.all()

    for {parent_id, component_id} <- parent_to_components,
        {^component_id, student_id} <- component_student_pairs,
        uniq: true,
        do: {parent_id, student_id}
  end

  @doc """
  Recalculates composed assessment point entries for the given `{parent_id, student_id}` pairs.

  Only sum-based compositions are processed; pairs whose parent is not
  `composition_type: :sum` are silently skipped. For each pair, the function
  sums the requested `field` (`:score` or `:student_score`) across the
  parent's component entries for the student.

  When the recomputed value exceeds the parent's `scale.max_score`, the
  composed entry's `calculation_error` is set to `"max_score_overflow"` and
  the target field is left untouched. Otherwise the recomputed value is
  written and `calculation_error` is cleared.

  Audit log rows are created via `Lanttern.AssessmentsLog` using the
  `scope.profile_id` as the actor.
  """
  @spec recalculate_composed_entries(
          Scope.t(),
          [{pos_integer(), pos_integer()}],
          :score | :student_score
        ) :: :ok
  def recalculate_composed_entries(%Scope{} = scope, pairs, field)
      when field in [:score, :student_score] do
    pairs
    |> Enum.uniq()
    |> Enum.each(&recalculate_composed_entry(scope, &1, field))

    :ok
  end

  defp recalculate_composed_entry(%Scope{} = scope, {parent_id, student_id}, field) do
    parent =
      AssessmentPoint
      |> Repo.get(parent_id)
      |> Repo.preload(:scale)

    with %AssessmentPoint{composition_type: :sum} <- parent do
      maybe_warn_cascading_composition(parent_id)

      components = Repo.all(from c in Component, where: c.parent_id == ^parent_id)
      component_ids = Enum.map(components, & &1.component_id)

      entries =
        Repo.all(
          from e in AssessmentPointEntry,
            where: e.assessment_point_id in ^component_ids and e.student_id == ^student_id
        )

      recomputed = compute_sum(entries, field)

      existing =
        Repo.one(
          from e in AssessmentPointEntry,
            where: e.assessment_point_id == ^parent_id and e.student_id == ^student_id
        )

      apply_recalculation(scope, parent, student_id, field, recomputed, existing)
    end
  end

  defp compute_sum(entries, field) do
    values = entries |> Enum.map(&Map.get(&1, field)) |> Enum.reject(&is_nil/1)

    case values do
      [] -> nil
      values -> Enum.sum(values)
    end
  end

  defp apply_recalculation(scope, parent, student_id, field, recomputed, existing) do
    overflow? = is_number(recomputed) and recomputed > parent.scale.max_score

    {target_value, target_error} =
      if overflow? do
        {existing && Map.get(existing, field), "max_score_overflow"}
      else
        {recomputed, nil}
      end

    do_upsert(scope, parent, student_id, field, target_value, target_error, existing)
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
