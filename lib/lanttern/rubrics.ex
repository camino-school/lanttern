defmodule Lanttern.Rubrics do
  @moduledoc """
  The Rubrics context.
  """

  import Ecto.Query, warn: false

  import Lanttern.RepoHelpers
  alias Lanttern.Repo

  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.LearningContext.Moment
  alias Lanttern.Rubrics.Rubric
  alias Lanttern.Rubrics.RubricDescriptor
  alias Lanttern.Schools.Student

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
  List all student strand rubrics grouped by strand goals (assessment points).

  Assessment points preload `curriculum_item` with
  `curriculum_component` and are ordered by position.

  Rubrics are ordered by position.

  ### Rules for determining if a rubric is a "student rubric"

  The results include:

  - rubrics linked to any non-diff strand assessment point (moment or goal)
  - differentiation rubrics linked to student. Diff rubrics in entries overrides the original rubrics
  - rubrics linked to differentiation assessment point only when the student has an entry for the assessment point

  ## Options

  - `:only_with_entries` - boolean, will include only results with linked student entries

  ## Examples

      iex> list_student_strand_rubrics_grouped_by_goal(1, 2)
      [{%AssessmentPoint{}, [%Rubric{}, ...]}, ...]

  """
  @spec list_student_strand_rubrics_grouped_by_goal(
          student_id :: pos_integer(),
          strand_id :: pos_integer(),
          opts :: Keyword.t()
        ) :: [Rubric.t()]
  def list_student_strand_rubrics_grouped_by_goal(student_id, strand_id, opts \\ []) do
    assessment_points_rubrics_and_ap_ids =
      from(
        r in Rubric,
        join: ap in assoc(r, :assessment_points),
        left_join: e in assoc(ap, :entries),
        on: e.student_id == ^student_id,
        as: :entries,
        # we need to know the assessment point id to remove
        # or keep rubrics based on student entry diff rubrics
        select: {r, ap.id},
        where: r.strand_id == ^strand_id,
        where: not ap.is_differentiation or not is_nil(e)
      )
      |> apply_only_with_entries_filter(Keyword.get(opts, :only_with_entries))
      |> Repo.all()

    {student_diff_rubrics, ap_with_diff_entry_rubrics} =
      from(
        r in Rubric,
        join: e in assoc(r, :diff_entries),
        on: e.student_id == ^student_id,
        select: {r, e.assessment_point_id},
        where: r.strand_id == ^strand_id
      )
      |> Repo.all()
      |> Enum.reduce({[], []}, fn {rubric, assessment_point_id}, {rubrics, ap_ids} ->
        {[rubric | rubrics], [assessment_point_id | ap_ids]}
      end)

    assessment_points_rubrics =
      assessment_points_rubrics_and_ap_ids
      |> Enum.filter(fn {_rubric, ap_id} ->
        ap_id not in ap_with_diff_entry_rubrics
      end)
      |> Enum.map(fn {rubric, _ap_id} -> rubric end)

    curriculum_items_rubrics_map =
      (assessment_points_rubrics ++ student_diff_rubrics)
      |> Enum.uniq()
      |> Enum.sort_by(& &1.position)
      |> Enum.group_by(& &1.curriculum_item_id)

    from(
      ap in AssessmentPoint,
      join: ci in assoc(ap, :curriculum_item),
      join: cc in assoc(ci, :curriculum_component),
      where: ap.strand_id == ^strand_id,
      preload: [curriculum_item: {ci, curriculum_component: cc}],
      order_by: ap.position
    )
    |> Repo.all()
    |> Enum.map(fn ap ->
      {ap, Map.get(curriculum_items_rubrics_map, ap.curriculum_item_id, [])}
    end)
    |> Enum.filter(fn {_ap, rubrics} -> rubrics != [] end)
  end

  defp apply_only_with_entries_filter(queryable, true) do
    from(
      [_r, entries: e] in queryable,
      where: not is_nil(e)
    )
  end

  defp apply_only_with_entries_filter(queryable, _), do: queryable

  @doc """
  List all rubrics matching given assessment point.

  A rubric "matches" the assessment point if its from the same strand and uses the
  same scale/curriculum item.

  Results are ordered by position.

  ## Options

  - `:only_diff` - boolean
  - `:exclude_diff` - boolean

  ## Examples

      iex> list_assessment_point_rubrics(1)
      [%Rubric{}, ...]

  """
  @spec list_assessment_point_rubrics(AssessmentPoint.t(), opts :: Keyword.t()) :: [Rubric.t()]
  def list_assessment_point_rubrics(%AssessmentPoint{} = assessment_point, opts \\ []) do
    %{
      scale_id: scale_id,
      curriculum_item_id: curriculum_item_id
    } = assessment_point

    strand_id =
      case assessment_point do
        %{strand_id: nil, moment_id: moment_id} ->
          from(
            m in Moment,
            where: m.id == ^moment_id,
            select: m.strand_id
          )
          |> Repo.one()

        %{strand_id: strand_id} ->
          strand_id
      end

    from(
      r in Rubric,
      where: r.strand_id == ^strand_id,
      where: r.scale_id == ^scale_id,
      where: r.curriculum_item_id == ^curriculum_item_id,
      order_by: r.position
    )
    |> apply_list_assessment_point_rubrics_opts(opts)
    |> Repo.all()
  end

  defp apply_list_assessment_point_rubrics_opts(queryable, []), do: queryable

  defp apply_list_assessment_point_rubrics_opts(queryable, [{:only_diff, true} | opts]) do
    from(r in queryable, where: r.is_differentiation == true)
    |> apply_list_assessment_point_rubrics_opts(opts)
  end

  defp apply_list_assessment_point_rubrics_opts(queryable, [{:exclude_diff, true} | opts]) do
    from(r in queryable, where: r.is_differentiation == false)
    |> apply_list_assessment_point_rubrics_opts(opts)
  end

  defp apply_list_assessment_point_rubrics_opts(queryable, [_ | opts]),
    do: apply_list_assessment_point_rubrics_opts(queryable, opts)

  @doc """
  List all strand rubrics grouped by strand goals (assessment points).

  Assessment points preload `curriculum_item` with
  `curriculum_component` and are ordered by position.

  Rubrics are ordered by position.

  ### Differentiation filters

  When using `:exclude_diff` options, we remove goals with `is_differentiation == true`
  from the results, as well as rubrics with `is_differentiation` flag.

  When using `:only_diff` options, we include all goals, but list only differentiation
  rubrics or rubrics linked to differentiation goals (even if they're not flagged as differentiation).

  ### Differentiation students

  There are two ways of connecting students to differentiation rubrics:

  1. through assessment point entries' `differentiation_rubric_id` field
  2. through differentition assessment point entries

  ## Options

  - `:only_diff` - boolean, refer to "Differentiation filters" section
  - `:exclude_diff` - boolean, refer to "Differentiation filters" section
  - `:preload_diff_students_from_classes_ids` - list of class ids to preload differentiation students

  ## Examples

      iex> list_strand_rubrics_grouped_by_goal(1)
      [{%AssessmentPoint{}, [%Rubric{}, ...]}, ...]

  """
  @spec list_strand_rubrics_grouped_by_goal(strand_id :: pos_integer(), opts :: Keyword.t()) :: [
          {AssessmentPoint.t(), [Rubric.t()]}
        ]
  def list_strand_rubrics_grouped_by_goal(strand_id, opts \\ []) do
    curriculum_items_rubrics_map =
      from(
        r in Rubric,
        where: r.strand_id == ^strand_id,
        order_by: r.position
      )
      |> Repo.all()
      |> preload_diff_students_in_rubrics(
        Keyword.get(opts, :preload_diff_students_from_classes_ids)
      )
      |> Enum.group_by(& &1.curriculum_item_id)

    filter_type =
      cond do
        Keyword.get(opts, :only_diff) == true -> :only_diff
        Keyword.get(opts, :exclude_diff) == true -> :exclude_diff
        true -> nil
      end

    from(
      ap in AssessmentPoint,
      join: ci in assoc(ap, :curriculum_item),
      join: cc in assoc(ci, :curriculum_component),
      where: ap.strand_id == ^strand_id,
      preload: [curriculum_item: {ci, curriculum_component: cc}],
      order_by: ap.position
    )
    |> Repo.all()
    |> Enum.map(fn ap ->
      {ap, Map.get(curriculum_items_rubrics_map, ap.curriculum_item_id, [])}
    end)
    |> filter_strand_rubrics_grouped_by_goal(filter_type)
  end

  defp preload_diff_students_in_rubrics(rubrics, classes_ids)
       when is_list(classes_ids) and classes_ids != [] do
    rubrics_ids = Enum.map(rubrics, & &1.id)

    rubric_diff_students_map =
      from(
        s in Student,
        join: ape in assoc(s, :assessment_point_entries),
        join: ap in assoc(ape, :assessment_point),
        join: c in assoc(s, :classes),
        select: {ape.differentiation_rubric_id, ap.rubric_id, s},
        where: c.id in ^classes_ids,
        where:
          ape.differentiation_rubric_id in ^rubrics_ids or
            (ap.is_differentiation and ap.rubric_id in ^rubrics_ids),
        order_by: s.name
      )
      |> Repo.all()
      # we need to "unify" rubric ids, prioritizing diff_rubric_id but
      # falling back to diff assessment point rubric id
      |> Enum.map(fn {diff_rubric_id, diff_ap_rubric_id, student} ->
        {diff_rubric_id || diff_ap_rubric_id, student}
      end)
      |> Enum.uniq()
      |> Enum.group_by(
        fn {rubric_id, _student} -> rubric_id end,
        fn {_rubric_id, student} -> student end
      )

    Enum.map(rubrics, &%{&1 | diff_students: Map.get(rubric_diff_students_map, &1.id, [])})
  end

  defp preload_diff_students_in_rubrics(rubrics, _classes_ids), do: rubrics

  defp filter_strand_rubrics_grouped_by_goal(rubrics_grouped_by_goal, :only_diff) do
    rubrics_grouped_by_goal
    |> Enum.map(fn
      {%{is_differentiation: true} = ap, rubrics} -> {ap, rubrics}
      {ap, rubrics} -> {ap, Enum.filter(rubrics, & &1.is_differentiation)}
    end)
  end

  defp filter_strand_rubrics_grouped_by_goal(rubrics_grouped_by_goal, :exclude_diff) do
    rubrics_grouped_by_goal
    |> Enum.filter(fn {ap, _rubrics} -> !ap.is_differentiation end)
    |> Enum.map(fn {ap, rubrics} ->
      {ap, Enum.filter(rubrics, &(!&1.is_differentiation))}
    end)
  end

  defp filter_strand_rubrics_grouped_by_goal(rubrics_grouped_by_goal, _),
    do: rubrics_grouped_by_goal

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
  Load the rubric descriptors, ordered by score or ordinal value normalized value.

  ## Examples

      iex> load_rubric_descriptors(rubric)
      %Rubric{}

  """
  @spec load_rubric_descriptors(Rubric.t()) :: Rubric.t()
  def load_rubric_descriptors(%Rubric{} = rubric) do
    descriptors =
      from(
        d in RubricDescriptor,
        left_join: ov in assoc(d, :ordinal_value),
        where: d.rubric_id == ^rubric.id,
        order_by: [d.score, ov.normalized_value]
      )
      |> Repo.all()

    %{rubric | descriptors: descriptors}
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
  def full_rubric_query do
    descriptors_query =
      from(
        d in RubricDescriptor,
        left_join: ov in assoc(d, :ordinal_value),
        order_by: [d.score, ov.normalized_value],
        preload: [ordinal_value: ov]
      )

    from(r in Rubric,
      join: s in assoc(r, :scale),
      preload: [scale: s, descriptors: ^descriptors_query]
    )
  end

  @doc """
  Creates a rubric.

  This function also handles the linking of assessment points to the rubric
  via `link_to_assessment_points_ids` attribute.

  ## Options:

  - `:preloads` – preloads associated data

  ## Examples

      iex> create_rubric(%{field: value})
      {:ok, %Rubric{}}

      iex> create_rubric(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_rubric(attrs \\ %{}, opts \\ []) do
    attrs =
      case attrs do
        %{strand_id: strand_id} when not is_nil(strand_id) ->
          from(r in Rubric, where: r.strand_id == ^strand_id)

        %{"strand_id" => strand_id} when not is_nil(strand_id) ->
          from(r in Rubric, where: r.strand_id == ^strand_id)

        _ ->
          Rubric
      end
      |> set_position_in_attrs(attrs)

    Ecto.Multi.new()
    # :insert would be a better multi name, but we use the generic
    # :rubric name to allow maybe_link/unlink_assessment_points reuse
    |> Ecto.Multi.insert(
      :rubric,
      Rubric.changeset(%Rubric{}, attrs)
    )
    |> maybe_link_assessment_points(attrs)
    |> Repo.transaction()
    |> case do
      {:error, _multi, changeset, _changes} -> {:error, changeset}
      {:ok, %{rubric: rubric}} -> {:ok, rubric}
    end
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

  This function also handles the linking/unlinking of assessment points to the rubric
  via `link_to_assessment_points_ids` and `unlink_from_assessment_points_ids` attributes.

  ### Options:

  `:preloads` – preloads associated data

  ## Examples

      iex> update_rubric(rubric, %{field: new_value})
      {:ok, %Rubric{}}

      iex> update_rubric(rubric, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_rubric(%Rubric{} = rubric, attrs, opts \\ []) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:rubric, fn _repo, _changes ->
      rubric
      |> Rubric.changeset(attrs)
      |> internal_update_rubric()
    end)
    |> maybe_link_assessment_points(attrs)
    |> maybe_unlink_assessment_points(attrs)
    |> Repo.transaction()
    |> case do
      {:error, _multi, changeset, _changes} -> {:error, changeset}
      {:ok, %{rubric: rubric}} -> {:ok, rubric}
    end
    |> maybe_preload(opts)
  end

  defp internal_update_rubric(%Ecto.Changeset{valid?: false} = changeset),
    do: {:error, changeset}

  defp internal_update_rubric(%Ecto.Changeset{} = changeset) do
    case {
      Ecto.Changeset.get_change(changeset, :scale_id),
      Ecto.Changeset.get_change(changeset, :descriptors)
    } do
      {nil, _} ->
        changeset
        |> Repo.update()

      {_, descriptors} when is_nil(descriptors) or descriptors == [] ->
        changeset
        |> Repo.update()

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
    end
  end

  defp format_update_rubric_transaction_response({:ok, %{cast_descriptors: rubric}}),
    do: {:ok, rubric}

  defp format_update_rubric_transaction_response({:error, _multi_name, error}),
    do: {:error, error}

  defp maybe_link_assessment_points(multi, %{"link_to_assessment_points_ids" => ids})
       when is_list(ids) do
    multi
    |> Ecto.Multi.update_all(
      :link_to_assessment_points,
      fn %{rubric: rubric} ->
        from(
          ap in AssessmentPoint,
          where: ap.id in ^ids,
          update: [set: [rubric_id: ^rubric.id]]
        )
      end,
      []
    )
  end

  defp maybe_link_assessment_points(multi, _attrs), do: multi

  defp maybe_unlink_assessment_points(multi, %{"unlink_from_assessment_points_ids" => ids})
       when is_list(ids) do
    multi
    |> Ecto.Multi.update_all(
      :unlink_from_assessment_points,
      fn %{rubric: rubric} ->
        from(
          ap in AssessmentPoint,
          where: ap.id in ^ids,
          where: ap.rubric_id == ^rubric.id,
          update: [set: [rubric_id: nil]]
        )
      end,
      []
    )
  end

  defp maybe_unlink_assessment_points(multi, _attrs), do: multi

  @doc """
  Update rubrics positions based on ids list order.

  ## Examples

  iex> update_rubrics_positions([3, 2, 1])
  :ok

  """
  @spec update_rubrics_positions(rubrics_ids :: [pos_integer()]) :: :ok | {:error, String.t()}
  def update_rubrics_positions(rubrics_ids), do: update_positions(Rubric, rubrics_ids)

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
  Returns a map with rubrics ids as keys and the list of
  ordered descriptors as value.

  Ordinal values are preloaded in descriptors.

  ## Examples

      iex> build_rubrics_descriptors_map(rubrics_ids)
      %{1 => [%RubricDescriptor{}, ...], ...}

  """
  @spec build_rubrics_descriptors_map([pos_integer()]) :: %{
          pos_integer() => [RubricDescriptor.t()]
        }
  def build_rubrics_descriptors_map(rubrics_ids) do
    from(
      d in RubricDescriptor,
      left_join: ov in assoc(d, :ordinal_value),
      where: d.rubric_id in ^rubrics_ids,
      order_by: [d.score, ov.normalized_value],
      preload: [ordinal_value: ov]
    )
    |> Repo.all()
    |> Enum.group_by(& &1.rubric_id)
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
  List all diff students linked to given rubric.

  There are two ways of connecting students to differentiation rubrics:

  1. through assessment point entries' `differentiation_rubric_id` field
  2. through differentition assessment point entries

  Use `school_id` from current profile to avoid listing students out of user scope.

  ## Options

  - `:load_profile_picture_from_cycle_id` - will try to load the profile picture from linked `%StudentCycleInfo{}` with the given cycle id

  ## Examples

      iex> list_diff_students_for_rubric(1, 1)
      [%Student{}, ...]

  """
  @spec list_diff_students_for_rubric(
          rubric_id :: pos_integer(),
          school_id :: pos_integer(),
          opts :: Keyword.t()
        ) :: [Student.t()]
  def list_diff_students_for_rubric(rubric_id, school_id, opts \\ []) do
    from(
      s in Student,
      join: ape in assoc(s, :assessment_point_entries),
      join: ap in assoc(ape, :assessment_point),
      where: s.school_id == ^school_id,
      where:
        ape.differentiation_rubric_id == ^rubric_id or
          (ap.is_differentiation and ap.rubric_id == ^rubric_id),
      distinct: [asc: s.name, asc: s.id],
      order_by: s.name
    )
    |> apply_list_diff_students_for_rubric_opts(opts)
    |> Repo.all()
  end

  defp apply_list_diff_students_for_rubric_opts(queryable, []), do: queryable

  defp apply_list_diff_students_for_rubric_opts(queryable, [
         {:load_profile_picture_from_cycle_id, cycle_id} | opts
       ]) do
    from(
      s in queryable,
      left_join: sci in assoc(s, :cycles_info),
      on: sci.cycle_id == ^cycle_id,
      select_merge: %{profile_picture_url: sci.profile_picture_url}
    )
    |> apply_list_diff_students_for_rubric_opts(opts)
  end

  defp apply_list_diff_students_for_rubric_opts(queryable, [_ | opts]),
    do: apply_list_diff_students_for_rubric_opts(queryable, opts)

  @doc """
  List all assessment points that are eligible to link to given rubric.

  An assessment point is considered eligible if

  - it's linked to the same strand as the rubric
  - it uses the same scale as the rubric
  - it uses the same curriculum item as the rubric
  - it `is_differentiation` flag matches the rubric's

  Preloads moment in case of moments assessment points.

  """
  @spec list_rubric_assessment_points_options(Rubric.t()) :: [
          {AssessmentPoint.t(), currently_linked :: boolean()}
        ]
  def list_rubric_assessment_points_options(%Rubric{} = rubric) do
    from(
      ap in AssessmentPoint,
      left_join: m in assoc(ap, :moment),
      preload: [moment: m],
      where: ap.strand_id == ^rubric.strand_id or m.strand_id == ^rubric.strand_id,
      where: ap.scale_id == ^rubric.scale_id,
      where: ap.curriculum_item_id == ^rubric.curriculum_item_id,
      where: ap.is_differentiation == ^rubric.is_differentiation,
      order_by: [asc_nulls_last: ap.strand_id, asc: m.position, asc: ap.position]
    )
    |> Repo.all()
    |> Enum.map(fn ap ->
      {ap, not is_nil(rubric.id) && ap.rubric_id == rubric.id}
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
