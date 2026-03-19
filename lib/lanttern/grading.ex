defmodule Lanttern.Grading do
  @moduledoc """
  The Grading context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo
  import Lanttern.RepoHelpers

  alias Lanttern.Grading.GradeComponent
  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Grading.Scale
  alias Lanttern.Identity.Scope

  @doc """
  Returns the list of grade_components.

  ## Examples

      iex> list_grade_components()
      [%GradeComponent{}, ...]

  """
  def list_grade_components do
    Repo.all(GradeComponent)
  end

  @doc """
  Gets a single grade_component.

  Raises `Ecto.NoResultsError` if the Grade component does not exist.

  ## Examples

      iex> get_grade_component!(123)
      %GradeComponent{}

      iex> get_grade_component!(456)
      ** (Ecto.NoResultsError)

  """
  def get_grade_component!(id), do: Repo.get!(GradeComponent, id)

  @doc """
  Creates a grade_component.

  ## Examples

      iex> create_grade_component(%{field: value})
      {:ok, %GradeComponent{}}

      iex> create_grade_component(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_grade_component(attrs \\ %{}) do
    queryable =
      case attrs do
        %{report_card_id: report_card_id, subject_id: subject_id} ->
          from(gc in GradeComponent,
            where: gc.report_card_id == ^report_card_id and gc.subject_id == ^subject_id
          )

        %{"report_card_id" => report_card_id, "subject_id" => subject_id} ->
          from(gc in GradeComponent,
            where: gc.report_card_id == ^report_card_id and gc.subject_id == ^subject_id
          )

        _ ->
          GradeComponent
      end

    attrs = set_position_in_attrs(queryable, attrs)

    %GradeComponent{}
    |> GradeComponent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a grade_component.

  ## Examples

      iex> update_grade_component(grade_component, %{field: new_value})
      {:ok, %GradeComponent{}}

      iex> update_grade_component(grade_component, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_grade_component(%GradeComponent{} = grade_component, attrs) do
    grade_component
    |> GradeComponent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Update grade components positions based on ids list order.

  ## Examples

      iex> update_grade_components_positions([3, 2, 1])
      :ok

  """
  @spec update_grade_components_positions([integer()]) :: :ok | {:error, String.t()}
  def update_grade_components_positions(grade_components_ids),
    do: update_positions(GradeComponent, grade_components_ids)

  @doc """
  Deletes a grade_component.

  ## Examples

      iex> delete_grade_component(grade_component)
      {:ok, %GradeComponent{}}

      iex> delete_grade_component(grade_component)
      {:error, %Ecto.Changeset{}}

  """
  def delete_grade_component(%GradeComponent{} = grade_component) do
    Repo.delete(grade_component)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking grade_component changes.

  ## Examples

      iex> change_grade_component(grade_component)
      %Ecto.Changeset{data: %GradeComponent{}}

  """
  def change_grade_component(%GradeComponent{} = grade_component, attrs \\ %{}) do
    GradeComponent.changeset(grade_component, attrs)
  end

  @doc """
  Returns the list of ordinal_values.

  ### Options:

  `:preloads` – preloads associated data
  `:scale_id` – filter ordinal values by scale and order results by `normalized_value`
  `:ids` – filter ordinal values by given ids

  ## Examples

      iex> list_ordinal_values()
      [%OrdinalValue{}, ...]

  """
  def list_ordinal_values(opts \\ []) do
    from(
      ov in OrdinalValue,
      order_by: ov.normalized_value
    )
    |> apply_list_ordinal_values_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_ordinal_values_opts(queryable, []), do: queryable

  defp apply_list_ordinal_values_opts(queryable, [{:scale_id, scale_id} | opts]) do
    from(ov in queryable, where: ov.scale_id == ^scale_id)
    |> apply_list_ordinal_values_opts(opts)
  end

  defp apply_list_ordinal_values_opts(queryable, [{:ids, ids} | opts]) do
    from(ov in queryable, where: ov.id in ^ids)
    |> apply_list_ordinal_values_opts(opts)
  end

  defp apply_list_ordinal_values_opts(queryable, [_ | opts]),
    do: apply_list_ordinal_values_opts(queryable, opts)

  @doc """
  Gets a single ordinal_value.
  Optionally preloads associated data.

  Raises `Ecto.NoResultsError` if the Ordinal value does not exist.

  ## Examples

      iex> get_ordinal_value!(123)
      %OrdinalValue{}

      iex> get_ordinal_value!(456)
      ** (Ecto.NoResultsError)

  """
  def get_ordinal_value!(id, preloads \\ []) do
    Repo.get!(OrdinalValue, id)
    |> Repo.preload(preloads)
  end

  @doc """
  Creates an ordinal_value for the current scope's school.

  Validates that scope's school matches the scale's school.

  ## Examples

      iex> create_ordinal_value(scope, %{field: value})
      {:ok, %OrdinalValue{}}

      iex> create_ordinal_value(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ordinal_value(%Scope{} = scope, attrs) do
    with :ok <- check_ordinal_value_school_access(scope, attrs) do
      %OrdinalValue{}
      |> OrdinalValue.changeset(attrs)
      |> Repo.insert()
    end
  end

  @doc """
  Updates an ordinal_value for the current scope's school.

  Validates that scope's school matches the ordinal_value and scale's school.

  ## Examples

      iex> update_ordinal_value(scope, ordinal_value, %{field: new_value})
      {:ok, %OrdinalValue{}}

      iex> update_ordinal_value(scope, ordinal_value, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ordinal_value(%Scope{} = scope, %OrdinalValue{} = ordinal_value, attrs) do
    with :ok <- check_ordinal_value_school_access(scope, ordinal_value),
         :ok <- check_ordinal_value_school_access(scope, attrs) do
      ordinal_value
      |> OrdinalValue.changeset(attrs)
      |> Repo.update()
    end
  end

  defp check_ordinal_value_school_access(
         %Scope{school_id: school_id} = _scope,
         %OrdinalValue{} = ordinal_value
       ) do
    scale = Repo.get!(Scale, ordinal_value.scale_id)
    if scale.school_id == school_id, do: :ok, else: {:error, :unauthorized}
  end

  defp check_ordinal_value_school_access(
         %Scope{school_id: school_id} = _scope,
         %{"scale_id" => scale_id} = _attrs
       ) do
    scale = Repo.get!(Scale, scale_id)
    if scale.school_id == school_id, do: :ok, else: {:error, :unauthorized}
  end

  defp check_ordinal_value_school_access(
         %Scope{school_id: school_id} = _scope,
         %{scale_id: scale_id} = _attrs
       ) do
    scale = Repo.get!(Scale, scale_id)
    if scale.school_id == school_id, do: :ok, else: {:error, :unauthorized}
  end

  @doc """
  Creates a ordinal_value.

  ## Examples

      iex> create_ordinal_value(%{field: value})
      {:ok, %OrdinalValue{}}

      iex> create_ordinal_value(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ordinal_value(attrs \\ %{}) do
    %OrdinalValue{}
    |> OrdinalValue.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a ordinal_value.

  ## Examples

      iex> update_ordinal_value(ordinal_value, %{field: new_value})
      {:ok, %OrdinalValue{}}

      iex> update_ordinal_value(ordinal_value, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_ordinal_value(%OrdinalValue{} = ordinal_value, attrs) do
    ordinal_value
    |> OrdinalValue.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ordinal_value.

  ## Examples

      iex> delete_ordinal_value(ordinal_value)
      {:ok, %OrdinalValue{}}

      iex> delete_ordinal_value(ordinal_value)
      {:error, %Ecto.Changeset{}}

  """
  def delete_ordinal_value(%OrdinalValue{} = ordinal_value) do
    Repo.delete(ordinal_value)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ordinal_value changes.

  ## Examples

      iex> change_ordinal_value(ordinal_value)
      %Ecto.Changeset{data: %OrdinalValue{}}

  """
  def change_ordinal_value(%OrdinalValue{} = ordinal_value, attrs \\ %{}) do
    OrdinalValue.changeset(ordinal_value, attrs)
  end

  @doc """
  Returns the list of scales.

  Accepts `:type` opts.

  ## Examples

      iex> list_scales([])
      [%Scale{}, ...]

  """
  def list_scales(opts) when is_list(opts) do
    Scale
    |> apply_list_scales_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  @doc """
  Returns the list of scales for the current scope's school.

  Accepts `:type` opts.

  ## Examples

      iex> list_scales(scope)
      [%Scale{}, ...]

      iex> list_scales(scope, [type: "ordinal"])
      [%Scale{}, ...]

  """
  def list_scales(%Scope{school_id: school_id} = _scope, opts \\ []) do
    Scale
    |> from(where: [school_id: ^school_id])
    |> apply_list_scales_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_scales_opts(queryable, []), do: queryable

  defp apply_list_scales_opts(queryable, [{:type, type} | opts]) do
    from(
      s in queryable,
      where: s.type == ^type
    )
    |> apply_list_scales_opts(opts)
  end

  defp apply_list_scales_opts(queryable, [{:ids, ids} | opts]) when is_list(ids) do
    from(
      s in queryable,
      where: s.id in ^ids
    )
    |> apply_list_scales_opts(opts)
  end

  defp apply_list_scales_opts(queryable, [_ | opts]),
    do: apply_list_scales_opts(queryable, opts)

  @doc """
  Gets a single scale.

  Raises `Ecto.NoResultsError` if the Scale does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_scale!(scope, 123)
      %Scale{}

      iex> get_scale!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_scale!(%Scope{} = scope, id, opts \\ []) do
    Scale
    |> Repo.get_by!(id: id, school_id: scope.school_id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a scale for the current scope's school.

  Automatically sets the school from scope.

  ## Examples

      iex> create_scale(scope, %{name: "Scale A"})
      {:ok, %Scale{}}

      iex> create_scale(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_scale(%Scope{} = scope, attrs \\ %{}) do
    true = Scope.has_permission?(scope, "assessment_management")

    %Scale{}
    |> Scale.changeset(attrs, scope)
    |> Repo.insert()
  end

  @doc """
  Updates a scale with scope check.

  Validates that scope's school matches the scale's school.

  ## Examples

      iex> update_scale(scope, scale, %{name: "New name"})
      {:ok, %Scale{}}

      iex> update_scale(scope, scale, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_scale(
        %Scope{school_id: school_id} = scope,
        %Scale{school_id: school_id} = scale,
        attrs
      ) do
    true = Scope.has_permission?(scope, "assessment_management")

    scale
    |> Scale.changeset(attrs, scope)
    |> Repo.update()
  end

  @doc """
  Deletes a scale.

  ## Examples

      iex> delete_scale(scale)
      {:ok, %Scale{}}

      iex> delete_scale(scale)
      {:error, %Ecto.Changeset{}}

  """
  def delete_scale(%Scope{} = scope, %Scale{} = scale) do
    true = Scope.has_permission?(scope, "assessment_management")

    Repo.delete(scale)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking scale changes.

  ## Examples

      iex> change_scale(scale)
      %Ecto.Changeset{data: %Scale{}}

  """
  def change_scale(%Scope{} = scope, %Scale{} = scale, attrs \\ %{}) do
    true = Scope.has_permission?(scope, "assessment_management")
    Scale.changeset(scale, attrs, scope)
  end

  @doc """
  Converts a normalized value to a scale's score (float) or `OrdinalValue`.
  """
  @spec convert_normalized_value_to_scale_value(float(), Scale.t()) :: float() | OrdinalValue.t()

  def convert_normalized_value_to_scale_value(normalized_value, %Scale{type: "ordinal"} = scale) do
    ordinal_values = list_ordinal_values(scale_id: scale.id)

    # get index of ordinal value
    # use sort to ensure scale breakpoints are sorted
    i =
      scale.breakpoints
      |> Enum.sort()
      |> get_normalized_value_breakpoint_index(normalized_value)

    Enum.at(ordinal_values, i)
  end

  def convert_normalized_value_to_scale_value(normalized_value, %Scale{type: "numeric"} = scale) do
    normalized_value * (scale.stop - scale.start) + scale.start
  end

  defp get_normalized_value_breakpoint_index(breakpoints, normalized_value, i \\ 0)

  defp get_normalized_value_breakpoint_index([], _n_value, i), do: i

  defp get_normalized_value_breakpoint_index([breakpoint | _breakpoints], n_value, i)
       when n_value < breakpoint,
       do: i

  defp get_normalized_value_breakpoint_index([_breakpoint | breakpoints], n_value, i),
    do: get_normalized_value_breakpoint_index(breakpoints, n_value, i + 1)
end
