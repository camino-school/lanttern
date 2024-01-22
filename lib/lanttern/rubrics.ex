defmodule Lanttern.Rubrics do
  @moduledoc """
  The Rubrics context.
  """

  import Ecto.Query, warn: false

  import Lanttern.RepoHelpers
  alias Lanttern.Repo

  alias Lanttern.Rubrics.Rubric
  alias Lanttern.Rubrics.RubricDescriptor

  @doc """
  Returns the list of rubrics.

  ### Options:

  `:preloads` – preloads associated data
  `:is_differentiation` – filter results by differentiation flag
  `:scale_id` – filter results by scale

  ## Examples

      iex> list_rubrics()
      [%Rubric{}, ...]

  """
  def list_rubrics(opts \\ []) do
    Rubric
    |> apply_filters(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  @doc """
  Returns the list of rubrics with scale, descriptors, and descriptors ordinal values preloaded.

  View `get_full_rubric!/1` for more details on descriptors sorting.

  ## Options

      - `assessment_points_ids` - filter rubrics by linked assessment points
      - `parent_rubrics_ids` - filter differentiation rubrics by parent rubrics
      - `students_ids` - filter rubrics by linked students

  ## Examples

      iex> list_full_rubrics()
      [%Rubric{}, ...]

  """
  def list_full_rubrics(opts \\ []) do
    full_rubric_query()
    |> filter_rubrics(opts)
    |> Repo.all()
  end

  defp filter_rubrics(queryable, opts) do
    Enum.reduce(opts, queryable, &apply_rubrics_filter/2)
  end

  defp apply_rubrics_filter({:rubrics_ids, ids}, queryable),
    do: from(ap in queryable, where: ap.id in ^ids)

  defp apply_rubrics_filter({:parent_rubrics_ids, ids}, queryable),
    do: from(ap in queryable, where: ap.diff_for_rubric_id in ^ids)

  defp apply_rubrics_filter({:assessment_points_ids, ids}, queryable) do
    from(
      r in queryable,
      join: ap in assoc(r, :assessment_points),
      where: ap.id in ^ids
    )
  end

  defp apply_rubrics_filter({:students_ids, ids}, queryable) do
    from(
      r in queryable,
      join: s in assoc(r, :students),
      where: s.id in ^ids
    )
  end

  defp apply_rubrics_filter(_, queryable), do: queryable

  @doc """
  Search rubrics by criteria.

  User can search by id by adding `#` before the id `#123`.

  ### Options:

  `:is_differentiation` – filter results by differentiation flag
  `:scale_id` – filter results by scale

  ## Examples

      iex> search_rubrics("understanding")
      [%Rubric{}, ...]

  """
  def search_rubrics(search_term, opts \\ [])

  def search_rubrics("#" <> search_term, opts) do
    if search_term =~ ~r/[0-9]+\z/ do
      from(
        r in Rubric,
        where: r.id == ^search_term
      )
      |> apply_filters(opts)
      |> Repo.all()
    else
      search_rubrics(search_term, opts)
    end
  end

  def search_rubrics(search_term, opts) do
    ilike_search_term = "%#{search_term}%"

    from(
      r in Rubric,
      where: ilike(r.criteria, ^ilike_search_term),
      order_by: {:asc, fragment("? <<-> ?", ^search_term, r.criteria)}
    )
    |> apply_filters(opts)
    |> Repo.all()
  end

  @doc """
  Gets a single rubric.

  Raises `Ecto.NoResultsError` if the Rubric does not exist.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> get_rubric!(123)
      %Rubric{}

      iex> get_rubric!(456)
      ** (Ecto.NoResultsError)

  """
  def get_rubric!(id, opts \\ []) do
    Rubric
    |> Repo.get!(id)
    |> maybe_preload(opts)
  end

  @doc """
  Returns the rubric with scale, descriptors, and descriptors ordinal values preloaded.

  Descriptors are ordered using the following rules:

  - when scale type is "ordinal", we use ordinal value's normalized value
  - when scale type is "numeric", we use descriptor's score

  ## Examples

      iex> get_full_rubric!(id)
      %Rubric{}

  """
  def get_full_rubric!(id) do
    full_rubric_query()
    |> Repo.get!(id)
  end

  @doc """
  Query used to load rubrics with descriptors
  ordered using the following rules:

  - when scale type is "ordinal", we use ordinal value's normalized value
  - when scale type is "numeric", we use descriptor's score
  """
  def full_rubric_query() do
    descriptors_query =
      from(
        d in RubricDescriptor,
        left_join: ov in assoc(d, :ordinal_value),
        order_by: [d.score, ov.normalized_value],
        preload: [ordinal_value: ov]
      )

    from(r in Rubric,
      join: s in assoc(r, :scale),
      preload: [scale: s, descriptors: ^descriptors_query],
      order_by: r.id
    )
  end

  @doc """
  Creates a rubric.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> create_rubric(%{field: value})
      {:ok, %Rubric{}}

      iex> create_rubric(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_rubric(attrs \\ %{}, opts \\ []) do
    %Rubric{}
    |> Rubric.changeset(attrs)
    |> Repo.insert()
    |> maybe_preload(opts)
  end

  @doc """
  Updates a rubric.

  We need to handle rubric scale updates manually to prevent foreign key errors.

  This is because we use overlapping FKs in rubric descriptors to enforce same
  `scale_id`s in rubric and descriptors, which will raise a DB error if we simply
  pass the changeset to `Repo.update/2`. To solve this problem, in a multi transaction we:

  1. delete the descriptors that should be deleted
  2. update only the rubric, changing it's scale id
  3. finally, update the rubric again casting the descriptors linked to the new scale id

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> update_rubric(rubric, %{field: new_value})
      {:ok, %Rubric{}}

      iex> update_rubric(rubric, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_rubric(%Rubric{} = rubric, attrs, opts \\ []) do
    rubric
    |> Rubric.changeset(attrs)
    |> internal_update_rubric(opts)
  end

  defp internal_update_rubric(%Ecto.Changeset{valid?: false} = changeset, _opts),
    do: {:error, changeset}

  defp internal_update_rubric(%Ecto.Changeset{} = changeset, opts) do
    case {
      Ecto.Changeset.get_change(changeset, :scale_id),
      Ecto.Changeset.get_change(changeset, :descriptors)
    } do
      {nil, _} ->
        changeset
        |> Repo.update()
        |> maybe_preload(opts)

      {_, descriptors} when is_nil(descriptors) or descriptors == [] ->
        changeset
        |> Repo.update()
        |> maybe_preload(opts)

      {_, _} ->
        remove_descriptors_ids =
          changeset
          |> Ecto.Changeset.get_change(:descriptors)
          |> Enum.filter(&(&1.action == :replace))
          |> Enum.map(&Ecto.Changeset.get_field(&1, :id))

        remove_query =
          from(d in RubricDescriptor,
            where: d.id in ^remove_descriptors_ids
          )

        Ecto.Multi.new()
        |> Ecto.Multi.delete_all(:delete_descriptors, remove_query)
        |> Ecto.Multi.update(
          :update_rubric,
          changeset |> Ecto.Changeset.delete_change(:descriptors)
        )
        |> Ecto.Multi.run(
          :cast_descriptors,
          fn _repo, %{update_rubric: rubric} ->
            rubric
            |> Map.delete(:descriptors)
            |> Ecto.Changeset.change(%{
              descriptors:
                changeset.changes.descriptors
                |> Enum.filter(&(&1.action == :insert))
            })
            |> Repo.update()
          end
        )
        |> Repo.transaction()
        |> format_update_rubric_transaction_response()
        |> maybe_preload(opts)
    end
  end

  defp format_update_rubric_transaction_response({:ok, %{cast_descriptors: rubric}}),
    do: {:ok, rubric}

  defp format_update_rubric_transaction_response({:error, _multi_name, error}),
    do: {:error, error}

  @doc """
  Deletes a rubric.

  ## Examples

      iex> delete_rubric(rubric)
      {:ok, %Rubric{}}

      iex> delete_rubric(rubric)
      {:error, %Ecto.Changeset{}}

  """
  def delete_rubric(%Rubric{} = rubric) do
    rubric
    |> Rubric.changeset(%{})
    |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking rubric changes.

  ## Examples

      iex> change_rubric(rubric)
      %Ecto.Changeset{data: %Rubric{}}

  """
  def change_rubric(%Rubric{} = rubric, attrs \\ %{}) do
    Rubric.changeset(rubric, attrs)
  end

  alias Lanttern.Rubrics.RubricDescriptor

  @doc """
  Returns the list of rubric_descriptors.

  ## Examples

      iex> list_rubric_descriptors()
      [%RubricDescriptor{}, ...]

  """
  def list_rubric_descriptors do
    Repo.all(RubricDescriptor)
  end

  @doc """
  Gets a single rubric_descriptor.

  Raises `Ecto.NoResultsError` if the Rubric descriptor does not exist.

  ## Examples

      iex> get_rubric_descriptor!(123)
      %RubricDescriptor{}

      iex> get_rubric_descriptor!(456)
      ** (Ecto.NoResultsError)

  """
  def get_rubric_descriptor!(id), do: Repo.get!(RubricDescriptor, id)

  @doc """
  Creates a rubric_descriptor.

  ## Examples

      iex> create_rubric_descriptor(%{field: value})
      {:ok, %RubricDescriptor{}}

      iex> create_rubric_descriptor(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_rubric_descriptor(attrs \\ %{}) do
    %RubricDescriptor{}
    |> RubricDescriptor.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a rubric_descriptor.

  ## Examples

      iex> update_rubric_descriptor(rubric_descriptor, %{field: new_value})
      {:ok, %RubricDescriptor{}}

      iex> update_rubric_descriptor(rubric_descriptor, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_rubric_descriptor(%RubricDescriptor{} = rubric_descriptor, attrs) do
    rubric_descriptor
    |> RubricDescriptor.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a rubric_descriptor.

  ## Examples

      iex> delete_rubric_descriptor(rubric_descriptor)
      {:ok, %RubricDescriptor{}}

      iex> delete_rubric_descriptor(rubric_descriptor)
      {:error, %Ecto.Changeset{}}

  """
  def delete_rubric_descriptor(%RubricDescriptor{} = rubric_descriptor) do
    Repo.delete(rubric_descriptor)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking rubric_descriptor changes.

  ## Examples

      iex> change_rubric_descriptor(rubric_descriptor)
      %Ecto.Changeset{data: %RubricDescriptor{}}

  """
  def change_rubric_descriptor(%RubricDescriptor{} = rubric_descriptor, attrs \\ %{}) do
    RubricDescriptor.changeset(rubric_descriptor, attrs)
  end

  @doc """
  Links a differentiation rubric to a student.

  ## Examples

      iex> link_rubric_to_student(%Rubric{}, 1)
      :ok

      iex> link_rubric_to_student(%Rubric{}, 1)
      {:error, "Error message"}

  """
  def link_rubric_to_student(%Rubric{diff_for_rubric_id: nil}, _student_id),
    do: {:error, "Only differentiation rubrics can be linked to students"}

  def link_rubric_to_student(%Rubric{id: rubric_id}, student_id) do
    from("differentiation_rubrics_students",
      where: [rubric_id: ^rubric_id, student_id: ^student_id],
      select: true
    )
    |> Repo.one()
    |> case do
      nil ->
        {1, _} =
          Repo.insert_all(
            "differentiation_rubrics_students",
            [[rubric_id: rubric_id, student_id: student_id]]
          )

        :ok

      _ ->
        # rubric already linked to student
        :ok
    end
  end

  @doc """
  Unlinks a rubric from a student.

  ## Examples

      iex> unlink_rubric_from_student(%Rubric{}, 1)
      :ok

      iex> unlink_rubric_from_student(%Rubric{}, 1)
      {:error, "Error message"}

  """
  def unlink_rubric_from_student(%Rubric{id: rubric_id}, student_id) do
    from("differentiation_rubrics_students",
      where: [rubric_id: ^rubric_id, student_id: ^student_id]
    )
    |> Repo.delete_all()

    :ok
  end

  @doc """
  Creates a differentiation rubric and link it to the student.

  This function executes `create_rubric/2` and `link_rubric_to_student/2`
  inside a single transaction.

  ## Options

      - view `create_rubric/2` for opts

  ## Examples

      iex> create_diff_rubric_for_student(1, %{})
      {:ok, %Rubric{}}

      iex> create_diff_rubric_for_student(1, %{})
      {:error, %Ecto.Changeset{}}

  """
  def create_diff_rubric_for_student(student_id, attrs \\ %{}, opts \\ []) do
    Repo.transaction(fn ->
      rubric =
        case create_rubric(attrs, opts) do
          {:ok, rubric} -> rubric
          {:error, error_changeset} -> Repo.rollback(error_changeset)
        end

      case link_rubric_to_student(rubric, student_id) do
        :ok ->
          :ok

        {:error, msg} ->
          rubric
          |> change_rubric(%{})
          |> Ecto.Changeset.add_error(:diff_for_rubric_id, msg)
          |> Map.put(:action, :insert)
          |> Repo.rollback()
      end

      rubric
    end)
  end

  # helpers

  defp apply_filters(rubrics_query, opts) do
    Enum.reduce(opts, rubrics_query, fn {opt, value}, query ->
      maybe_filter(query, opt, value)
    end)
  end

  defp maybe_filter(rubrics_query, :is_differentiation, is_differentiation) do
    from(
      r in rubrics_query,
      where: r.is_differentiation == ^is_differentiation
    )
  end

  defp maybe_filter(rubrics_query, :scale_id, scale_id) do
    from(
      r in rubrics_query,
      where: r.scale_id == ^scale_id
    )
  end

  defp maybe_filter(rubrics_query, _opt, _value), do: rubrics_query
end
