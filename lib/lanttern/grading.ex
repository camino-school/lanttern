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

  ## Examples

      iex> list_ordinal_values()
      [%OrdinalValue{}, ...]

  """
  def list_ordinal_values(opts \\ []) do
    OrdinalValue
    |> maybe_filter_ordinal_values_by_scale(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp maybe_filter_ordinal_values_by_scale(ordinal_value_query, opts) do
    case Keyword.get(opts, :scale_id) do
      nil ->
        ordinal_value_query

      scale_id ->
        from(
          ov in ordinal_value_query,
          where: ov.scale_id == ^scale_id,
          order_by: ov.normalized_value
        )
    end
  end

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

      iex> list_scales()
      [%Scale{}, ...]

  """

  def list_scales(opts \\ [])

  def list_scales(type: type) do
    from(s in Scale, where: s.type == ^type)
    |> Repo.all()
  end

  def list_scales(_opts) do
    Repo.all(Scale)
  end

  @doc """
  Gets a single scale.

  Raises `Ecto.NoResultsError` if the Scale does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_scale!(123)
      %Scale{}

      iex> get_scale!(456)
      ** (Ecto.NoResultsError)

  """
  def get_scale!(id, opts \\ []) do
    Repo.get!(Scale, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a scale.

  ## Examples

      iex> create_scale(%{field: value})
      {:ok, %Scale{}}

      iex> create_scale(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_scale(attrs \\ %{}) do
    %Scale{}
    |> Scale.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a scale.

  ## Examples

      iex> update_scale(scale, %{field: new_value})
      {:ok, %Scale{}}

      iex> update_scale(scale, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_scale(%Scale{} = scale, attrs) do
    scale
    |> Scale.changeset(attrs)
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
  def delete_scale(%Scale{} = scale) do
    Repo.delete(scale)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking scale changes.

  ## Examples

      iex> change_scale(scale)
      %Ecto.Changeset{data: %Scale{}}

  """
  def change_scale(%Scale{} = scale, attrs \\ %{}) do
    Scale.changeset(scale, attrs)
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
