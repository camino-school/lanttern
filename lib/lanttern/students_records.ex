defmodule Lanttern.StudentsRecords do
  @moduledoc """
  The StudentsRecords context.
  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  alias Lanttern.RepoHelpers.Page
  alias Lanttern.Repo

  alias Lanttern.StudentsRecords.StudentRecord

  @doc """
  Returns a list of students_records, ordered desc by date and time.

  ## Options

  - `:school_id` - filter results by school
  - `:students_ids` - filter results by students
  - `:types_ids` - filter results by type
  - `:statuses_ids` - filter results by status
  - `:preloads` - preloads associated data
  - page opts (view `Page.opts()`)

  ## Examples

      iex> list_students_records()
      [%StudentRecord{}, ...]

  """
  @type list_students_records_opts ::
          [
            school_id: pos_integer(),
            students_ids: [pos_integer()],
            types_ids: [pos_integer()],
            statuses_ids: [pos_integer()],
            preloads: list()
          ]
          | Page.opts()
  @spec list_students_records(list_students_records_opts()) :: [StudentRecord.t()]
  def list_students_records(opts \\ []) do
    from(
      sr in StudentRecord,
      order_by: [desc: sr.date, desc: sr.time, desc: sr.id]
    )
    |> apply_list_students_records_opts(opts)
    |> Repo.all()
    |> maybe_preload(opts)
  end

  defp apply_list_students_records_opts(queryable, []), do: queryable

  defp apply_list_students_records_opts(queryable, [{:school_id, school_id} | opts]) do
    from(
      sr in queryable,
      where: sr.school_id == ^school_id
    )
    |> apply_list_students_records_opts(opts)
  end

  defp apply_list_students_records_opts(queryable, [{:students_ids, students_ids} | opts])
       when is_list(students_ids) and students_ids != [] do
    from(
      sr in queryable,
      join: s in assoc(sr, :students),
      where: s.id in ^students_ids
    )
    |> apply_list_students_records_opts(opts)
  end

  defp apply_list_students_records_opts(queryable, [{:types_ids, types_ids} | opts])
       when is_list(types_ids) and types_ids != [] do
    from(
      sr in queryable,
      where: sr.type_id in ^types_ids
    )
    |> apply_list_students_records_opts(opts)
  end

  defp apply_list_students_records_opts(queryable, [{:statuses_ids, statuses_ids} | opts])
       when is_list(statuses_ids) and statuses_ids != [] do
    from(
      sr in queryable,
      where: sr.status_id in ^statuses_ids
    )
    |> apply_list_students_records_opts(opts)
  end

  defp apply_list_students_records_opts(queryable, [{:first, first} | opts]) do
    from(sr in queryable, limit: ^first + 1)
    |> apply_list_students_records_opts(opts)
  end

  defp apply_list_students_records_opts(queryable, [
         {:after, [date: date, time: %Time{} = time, id: id]} | opts
       ]) do
    from(
      sr in queryable,
      where:
        sr.date < ^date or (sr.date == ^date and sr.time < ^time) or
          (sr.date == ^date and sr.time == ^time and sr.id < ^id)
    )
    |> apply_list_students_records_opts(opts)
  end

  # time is optiona, so there's a keyset case to consider only date
  defp apply_list_students_records_opts(queryable, [
         {:after, [date: date, time: _, id: id]} | opts
       ]) do
    from(
      sr in queryable,
      where: sr.date < ^date or (sr.date == ^date and sr.id < ^id)
    )
    |> apply_list_students_records_opts(opts)
  end

  defp apply_list_students_records_opts(queryable, [_ | opts]),
    do: apply_list_students_records_opts(queryable, opts)

  @doc """
  Returns a page with the list of students_records.

  Sets the `first` default to 100.

  Keyset for this query is `[:date, :time, :id]`.

  Same as `list_students_records/1`, but returned in a `%Page{}` struct.
  """
  @spec list_students_records_page(list_students_records_opts()) :: Page.t()
  def list_students_records_page(opts \\ []) do
    # set default for first opt
    first = Keyword.get(opts, :first, 100)
    opts = Keyword.put(opts, :first, first)

    students_records = list_students_records(opts)

    {results, has_next, keyset} =
      Page.extract_pagination_fields_from(
        students_records,
        first,
        fn last -> [date: last.date, time: last.time, id: last.id] end
      )

    %Page{results: results, keyset: keyset, has_next: has_next}
  end

  @doc """
  Gets a single student_record.

  Returns `nil` if the student record does not exist.

  ## Options

  - `:preloads` - preloads associated data

  ## Examples

      iex> get_student_record!(123)
      %StudentRecord{}

      iex> get_student_record!(456)
      nil

  """
  def get_student_record(id, opts \\ []) do
    Repo.get(StudentRecord, id)
    |> maybe_preload(opts)
  end

  @doc """
  Gets a single student record.

  Same as `get_student_record/1`, but raises `Ecto.NoResultsError` if the `StudentRecord` does not exist.

  """
  def get_student_record!(id, opts \\ []) do
    Repo.get!(StudentRecord, id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a student_record.

  ## Examples

      iex> create_student_record(%{field: value})
      {:ok, %StudentRecord{}}

      iex> create_student_record(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_record(attrs \\ %{}) do
    %StudentRecord{}
    |> StudentRecord.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a student_record.

  ## Examples

      iex> update_student_record(student_record, %{field: new_value})
      {:ok, %StudentRecord{}}

      iex> update_student_record(student_record, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_record(%StudentRecord{} = student_record, attrs) do
    student_record
    |> StudentRecord.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a student_record.

  ## Examples

      iex> delete_student_record(student_record)
      {:ok, %StudentRecord{}}

      iex> delete_student_record(student_record)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_record(%StudentRecord{} = student_record) do
    Repo.delete(student_record)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_record changes.

  ## Examples

      iex> change_student_record(student_record)
      %Ecto.Changeset{data: %StudentRecord{}}

  """
  def change_student_record(%StudentRecord{} = student_record, attrs \\ %{}) do
    StudentRecord.changeset(student_record, attrs)
  end

  alias Lanttern.StudentsRecords.StudentRecordType

  @doc """
  Returns the list of student_record_types.

  ## Options

  - `:school_id` - filter results by school

  ## Examples

      iex> list_student_record_types()
      [%StudentRecordType{}, ...]

  """
  def list_student_record_types(opts \\ []) do
    from(
      srt in StudentRecordType,
      order_by: srt.name
    )
    |> apply_list_student_record_types_opts(opts)
    |> Repo.all()
  end

  defp apply_list_student_record_types_opts(queryable, []), do: queryable

  defp apply_list_student_record_types_opts(queryable, [{:school_id, school_id} | opts]) do
    from(
      srt in queryable,
      where: srt.school_id == ^school_id
    )
    |> apply_list_student_record_types_opts(opts)
  end

  defp apply_list_student_record_types_opts(queryable, [_ | opts]),
    do: apply_list_student_record_types_opts(queryable, opts)

  @doc """
  Gets a single student_record_type.

  Raises `Ecto.NoResultsError` if the Student record type does not exist.

  ## Examples

      iex> get_student_record_type!(123)
      %StudentRecordType{}

      iex> get_student_record_type!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student_record_type!(id), do: Repo.get!(StudentRecordType, id)

  @doc """
  Creates a student_record_type.

  ## Examples

      iex> create_student_record_type(%{field: value})
      {:ok, %StudentRecordType{}}

      iex> create_student_record_type(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_record_type(attrs \\ %{}) do
    %StudentRecordType{}
    |> StudentRecordType.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a student_record_type.

  ## Examples

      iex> update_student_record_type(student_record_type, %{field: new_value})
      {:ok, %StudentRecordType{}}

      iex> update_student_record_type(student_record_type, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_record_type(%StudentRecordType{} = student_record_type, attrs) do
    student_record_type
    |> StudentRecordType.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a student_record_type.

  ## Examples

      iex> delete_student_record_type(student_record_type)
      {:ok, %StudentRecordType{}}

      iex> delete_student_record_type(student_record_type)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_record_type(%StudentRecordType{} = student_record_type) do
    Repo.delete(student_record_type)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_record_type changes.

  ## Examples

      iex> change_student_record_type(student_record_type)
      %Ecto.Changeset{data: %StudentRecordType{}}

  """
  def change_student_record_type(%StudentRecordType{} = student_record_type, attrs \\ %{}) do
    StudentRecordType.changeset(student_record_type, attrs)
  end

  alias Lanttern.StudentsRecords.StudentRecordStatus

  @doc """
  Returns the list of student_record_statuses.

  ## Options

  - `:school_id` - filter results by school

  ## Examples

      iex> list_student_record_statuses()
      [%StudentRecordStatus{}, ...]

  """
  def list_student_record_statuses(opts \\ []) do
    from(
      srs in StudentRecordStatus,
      order_by: srs.name
    )
    |> apply_list_student_record_statuses_opts(opts)
    |> Repo.all()
  end

  defp apply_list_student_record_statuses_opts(queryable, []), do: queryable

  defp apply_list_student_record_statuses_opts(queryable, [{:school_id, school_id} | opts]) do
    from(
      srs in queryable,
      where: srs.school_id == ^school_id
    )
    |> apply_list_student_record_statuses_opts(opts)
  end

  defp apply_list_student_record_statuses_opts(queryable, [_ | opts]),
    do: apply_list_student_record_statuses_opts(queryable, opts)

  @doc """
  Gets a single student_record_status.

  Raises `Ecto.NoResultsError` if the Student record status does not exist.

  ## Examples

      iex> get_student_record_status!(123)
      %StudentRecordStatus{}

      iex> get_student_record_status!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student_record_status!(id), do: Repo.get!(StudentRecordStatus, id)

  @doc """
  Creates a student_record_status.

  ## Examples

      iex> create_student_record_status(%{field: value})
      {:ok, %StudentRecordStatus{}}

      iex> create_student_record_status(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_record_status(attrs \\ %{}) do
    %StudentRecordStatus{}
    |> StudentRecordStatus.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a student_record_status.

  ## Examples

      iex> update_student_record_status(student_record_status, %{field: new_value})
      {:ok, %StudentRecordStatus{}}

      iex> update_student_record_status(student_record_status, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_record_status(%StudentRecordStatus{} = student_record_status, attrs) do
    student_record_status
    |> StudentRecordStatus.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a student_record_status.

  ## Examples

      iex> delete_student_record_status(student_record_status)
      {:ok, %StudentRecordStatus{}}

      iex> delete_student_record_status(student_record_status)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_record_status(%StudentRecordStatus{} = student_record_status) do
    Repo.delete(student_record_status)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_record_status changes.

  ## Examples

      iex> change_student_record_status(student_record_status)
      %Ecto.Changeset{data: %StudentRecordStatus{}}

  """
  def change_student_record_status(%StudentRecordStatus{} = student_record_status, attrs \\ %{}) do
    StudentRecordStatus.changeset(student_record_status, attrs)
  end
end
