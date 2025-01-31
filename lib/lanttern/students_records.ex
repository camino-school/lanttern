defmodule Lanttern.StudentsRecords do
  @moduledoc """
  The StudentsRecords context.

  # About profile permissions

  Using the `:check_profile_permissions` option, we can validate read,
  update, and delete students records operations based on given `%Profile{}`
  (usually from `socket.assigns.current_user.current_profile`).

  ## Read permissions

  Supported by `list_students_records/1` and `get_student_record/2`.

  A profile has permission to read a student record if it has type `"staff"`
  and the staff member belongs to the same school as the student record, and:

  1. the profile has the `students_records_full_access` permission
  2. or the student record is `shared_with_school`
  3. or the staff member created the student record
  4. or the staff member is an assignee of the student record

  ## Update permissions

  Supported by `update_student_record/3`.

  A profile has permission to update a student record if it has type `"staff"`
  and the staff member belongs to the same school as the student record, and:

  1. the profile has the `students_records_full_access` permission
  2. or the staff member created the student record
  3. or the staff member is an assignee of the student record

  ## Delete permissions

  Supported by `delete_student_record/2`.

  A profile has permission to delete a student record if it has type `"staff"`
  and the staff member belongs to the same school as the student record, and:

  1. the profile has the `students_records_full_access` permission
  2. or the staff member created the student record

  """

  import Ecto.Query, warn: false
  import Lanttern.RepoHelpers
  alias Lanttern.RepoHelpers.Page
  alias Lanttern.Repo

  alias Lanttern.Identity.Profile
  alias Lanttern.Schools.StaffMember
  alias Lanttern.StudentsRecords.AssigneeRelationship
  alias Lanttern.StudentsRecords.StudentRecord
  alias Lanttern.StudentsRecords.StudentRecordStatus
  alias Lanttern.StudentsRecords.Tag
  alias Lanttern.StudentsRecordsLog

  @doc """
  Returns a list of students_records, ordered desc by date and time.

  ## Options

  - `:school_id` - filter results by school
  - `:students_ids` - filter results by students
  - `:classes_ids` - filter results by classes
  - `:statuses_ids` - filter results by status
  - `:tags_ids` - filter results by tag
  - `:owner_id` - filter results by owner
  - `:assignees_ids` - filter results by assignees
  - `:check_profile_permissions` - filter results based on profile permission
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
            classes_ids: [pos_integer()],
            tags_ids: [pos_integer()],
            statuses_ids: [pos_integer()],
            owner_id: pos_integer(),
            assignees_ids: [pos_integer()],
            check_profile_permissions: Profile.t(),
            preloads: list()
          ]
          | Page.opts()
  @spec list_students_records(list_students_records_opts()) :: [StudentRecord.t()]
  def list_students_records(opts \\ []) do
    from(
      sr in StudentRecord,
      order_by: [desc: sr.date, desc: sr.time, desc: sr.id],
      group_by: sr.id
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
      join: srel in assoc(sr, :students_relationships),
      where: srel.student_id in ^students_ids
    )
    |> apply_list_students_records_opts(opts)
  end

  defp apply_list_students_records_opts(queryable, [{:classes_ids, classes_ids} | opts])
       when is_list(classes_ids) and classes_ids != [] do
    from(
      sr in queryable,
      join: cr in assoc(sr, :classes_relationships),
      where: cr.class_id in ^classes_ids
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

  defp apply_list_students_records_opts(queryable, [{:tags_ids, tags_ids} | opts])
       when is_list(tags_ids) and tags_ids != [] do
    tags_len = length(tags_ids)

    from(
      sr in queryable,
      join: srt in assoc(sr, :tags_relationships),
      where: srt.tag_id in ^tags_ids,
      having: count(srt.tag_id) == ^tags_len
    )
    |> apply_list_students_records_opts(opts)
  end

  defp apply_list_students_records_opts(queryable, [{:owner_id, owner_id} | opts])
       when not is_nil(owner_id) do
    from(
      sr in queryable,
      where: sr.created_by_staff_member_id == ^owner_id
    )
    |> apply_list_students_records_opts(opts)
  end

  defp apply_list_students_records_opts(queryable, [{:assignees_ids, assignees_ids} | opts])
       when is_list(assignees_ids) and assignees_ids != [] do
    from(
      sr in queryable,
      join: ar in assoc(sr, :assignees_relationships),
      where: ar.staff_member_id in ^assignees_ids
    )
    |> apply_list_students_records_opts(opts)
  end

  defp apply_list_students_records_opts(queryable, [
         {:check_profile_permissions,
          %Profile{permissions: permissions, staff_member: %StaffMember{}} = profile}
         | opts
       ]) do
    queryable
    |> apply_check_profile_read_permissions(
      profile,
      "students_records_full_access" in permissions
    )
    |> apply_list_students_records_opts(opts)
  end

  defp apply_list_students_records_opts(queryable, [
         {:check_profile_permissions, _not_staff_member_profile} | opts
       ]) do
    from(sr in queryable, where: false)
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

  defp apply_check_profile_read_permissions(
         queryable,
         %Profile{staff_member: %StaffMember{school_id: school_id}},
         true
       ) do
    from(
      sr in queryable,
      where: sr.school_id == ^school_id
    )
  end

  defp apply_check_profile_read_permissions(
         queryable,
         %Profile{staff_member: %StaffMember{id: staff_member_id, school_id: school_id}},
         false
       ) do
    from(
      sr in queryable,
      as: :student_record,
      where: sr.school_id == ^school_id,
      where:
        sr.shared_with_school or sr.created_by_staff_member_id == ^staff_member_id or
          exists(
            from(ar in AssigneeRelationship,
              where: ar.staff_member_id == ^staff_member_id,
              where: ar.student_record_id == parent_as(:student_record).id
            )
          )
    )
  end

  defp apply_check_profile_read_permissions(
         queryable,
         _profile,
         _has_full_access
       ) do
    from(
      sr in queryable,
      where: false
    )
  end

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
  - `:check_profile_permissions` - filter results based on profile permission

  ## Examples

      iex> get_student_record!(123)
      %StudentRecord{}

      iex> get_student_record!(456)
      nil

  """
  def get_student_record(id, opts \\ []) do
    StudentRecord
    |> apply_get_student_record_opts(opts)
    |> Repo.get(id)
    |> maybe_preload(opts)
  end

  defp apply_get_student_record_opts(queryable, []), do: queryable

  defp apply_get_student_record_opts(queryable, [
         {:check_profile_permissions,
          %Profile{permissions: permissions, staff_member: %StaffMember{}} = profile}
         | opts
       ]) do
    queryable
    |> apply_check_profile_read_permissions(
      profile,
      "students_records_full_access" in permissions
    )
    |> apply_get_student_record_opts(opts)
  end

  defp apply_get_student_record_opts(queryable, [
         {:check_profile_permissions, _not_staff_member_profile} | opts
       ]) do
    from(sr in queryable, where: false)
    |> apply_get_student_record_opts(opts)
  end

  defp apply_get_student_record_opts(queryable, [_ | opts]),
    do: apply_get_student_record_opts(queryable, opts)

  @doc """
  Gets a single student record.

  Same as `get_student_record/1`, but raises `Ecto.NoResultsError` if the `StudentRecord` does not exist.

  """
  def get_student_record!(id, opts \\ []) do
    StudentRecord
    |> apply_get_student_record_opts(opts)
    |> Repo.get!(id)
    |> maybe_preload(opts)
  end

  @doc """
  Creates a student_record.

  ## Options:

  - `:log_profile_id` - logs the operation, linked to given profile

  ## Examples

      iex> create_student_record(%{field: value})
      {:ok, %StudentRecord{}}

      iex> create_student_record(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_record(attrs \\ %{}, opts \\ []) do
    %StudentRecord{}
    |> StudentRecord.changeset(attrs)
    |> Repo.insert()
    |> StudentsRecordsLog.maybe_create_student_record_log("CREATE", opts)
  end

  @doc """
  Updates a student_record.

  ## Options:

  - `:log_profile_id` - logs the operation, linked to given profile
  - `:check_profile_permissions` - check if the user has permission to update the record

  ## Examples

      iex> update_student_record(student_record, %{field: new_value})
      {:ok, %StudentRecord{}}

      iex> update_student_record(student_record, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_record(%StudentRecord{} = student_record, attrs, opts \\ []) do
    # for profile permissions check we get the student record from DB
    # to prevent checking against a stale record
    check_profile_update_permissions(
      get_student_record(student_record.id, preloads: :assignees),
      Keyword.get(opts, :check_profile_permissions)
    )
    |> case do
      :ok ->
        student_record
        |> StudentRecord.changeset(attrs)
        |> StudentRecord.update_changeset_closed_fields(attrs)
        |> Repo.update()
        |> StudentsRecordsLog.maybe_create_student_record_log("UPDATE", opts)

      _ ->
        {:error, %Ecto.Changeset{}}
    end
  end

  defp check_profile_update_permissions(_student_record, nil), do: :ok

  defp check_profile_update_permissions(
         %StudentRecord{} = student_record,
         %Profile{} = profile
       ) do
    if profile_has_student_record_update_permissions?(student_record, profile),
      do: :ok,
      else: :error
  end

  defp check_profile_update_permissions(_student_record, _opt), do: :error

  @doc """
  Check if profile has permission to update student record.

  Expects profile permissions, profile staff member, and student record assignees preloads.

  """
  @spec profile_has_student_record_update_permissions?(StudentRecord.t(), Profile.t()) ::
          boolean()
  def profile_has_student_record_update_permissions?(
        %StudentRecord{school_id: student_record_school_id} = student_record,
        %Profile{staff_member: %StaffMember{school_id: profile_school_id}} = profile
      )
      when student_record_school_id == profile_school_id do
    "students_records_full_access" in profile.permissions or
      student_record.created_by_staff_member_id == profile.staff_member.id or
      Enum.any?(student_record.assignees, &(&1.id == profile.staff_member.id))
  end

  def profile_has_student_record_update_permissions?(_student_record, _profile), do: false

  @doc """
  Deletes a student_record.

  ## Options:

  - `:log_profile_id` - logs the operation, linked to given profile
  - `:check_profile_permissions` - check if the user has permission to delete the record

  ## Examples

      iex> delete_student_record(student_record)
      {:ok, %StudentRecord{}}

      iex> delete_student_record(student_record)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_record(%StudentRecord{} = student_record, opts \\ []) do
    # for profile permissions check we get the student record from DB
    # to prevent checking against a stale record
    check_profile_delete_permissions(
      get_student_record(student_record.id),
      Keyword.get(opts, :check_profile_permissions)
    )
    |> case do
      :ok ->
        Repo.delete(student_record)
        |> StudentsRecordsLog.maybe_create_student_record_log("DELETE", opts)

      _ ->
        {:error, %Ecto.Changeset{}}
    end
  end

  defp check_profile_delete_permissions(_student_record, nil), do: :ok

  defp check_profile_delete_permissions(%StudentRecord{} = student_record, %Profile{} = profile) do
    if profile_has_student_record_delete_permissions?(student_record, profile),
      do: :ok,
      else: :error
  end

  defp check_profile_delete_permissions(_student_record, _opt), do: :error

  @doc """
  Check if profile has permission to delete student record.

  Expects profile permissions and staff member preloads.

  """
  @spec profile_has_student_record_delete_permissions?(StudentRecord.t(), Profile.t()) ::
          boolean()
  def profile_has_student_record_delete_permissions?(
        %StudentRecord{school_id: student_record_school_id} = student_record,
        %Profile{staff_member: %StaffMember{school_id: profile_school_id}} = profile
      )
      when student_record_school_id == profile_school_id do
    "students_records_full_access" in profile.permissions or
      student_record.created_by_staff_member_id == profile.staff_member.id
  end

  def profile_has_student_record_delete_permissions?(_student_record, _profile), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_record changes.

  ## Examples

      iex> change_student_record(student_record)
      %Ecto.Changeset{data: %StudentRecord{}}

  """
  def change_student_record(%StudentRecord{} = student_record, attrs \\ %{}) do
    StudentRecord.changeset(student_record, attrs)
  end

  @doc """
  Returns the list of student_record_tags.

  ## Options

  - `:school_id` - filter results by school

  ## Examples

      iex> list_student_record_tags()
      [%Tag{}, ...]

  """
  def list_student_record_tags(opts \\ []) do
    from(
      t in Tag,
      order_by: t.position
    )
    |> apply_list_student_record_tags_opts(opts)
    |> Repo.all()
  end

  defp apply_list_student_record_tags_opts(queryable, []), do: queryable

  defp apply_list_student_record_tags_opts(queryable, [{:school_id, school_id} | opts]) do
    from(
      t in queryable,
      where: t.school_id == ^school_id
    )
    |> apply_list_student_record_tags_opts(opts)
  end

  defp apply_list_student_record_tags_opts(queryable, [_ | opts]),
    do: apply_list_student_record_tags_opts(queryable, opts)

  @doc """
  Gets a single student_record_tag.

  Raises `Ecto.NoResultsError` if the Student record tag does not exist.

  ## Examples

      iex> get_student_record_tag!(123)
      %Tag{}

      iex> get_student_record_tag!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student_record_tag!(id), do: Repo.get!(Tag, id)

  @doc """
  Creates a student_record_tag.

  ## Examples

      iex> create_student_record_tag(%{field: value})
      {:ok, %Tag{}}

      iex> create_student_record_tag(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_record_tag(attrs \\ %{}) do
    queryable =
      case attrs do
        %{school_id: school_id} ->
          from(t in Tag, where: t.school_id == ^school_id)

        %{"school_id" => school_id} ->
          from(t in Tag, where: t.school_id == ^school_id)

        _ ->
          Tag
      end

    attrs = set_position_in_attrs(queryable, attrs)

    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a student_record_tag.

  ## Examples

      iex> update_student_record_tag(student_record_tag, %{field: new_value})
      {:ok, %Tag{}}

      iex> update_student_record_tag(student_record_tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_record_tag(%Tag{} = student_record_tag, attrs) do
    student_record_tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a student_record_tag.

  ## Examples

      iex> delete_student_record_tag(student_record_tag)
      {:ok, %Tag{}}

      iex> delete_student_record_tag(student_record_tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_record_tag(%Tag{} = student_record_tag) do
    Repo.delete(student_record_tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_record_tag changes.

  ## Examples

      iex> change_student_record_tag(student_record_tag)
      %Ecto.Changeset{data: %Tag{}}

  """
  def change_student_record_tag(%Tag{} = student_record_tag, attrs \\ %{}) do
    Tag.changeset(student_record_tag, attrs)
  end

  @doc """
  Update student record tags positions based on ids list order.

  ## Examples

      iex> update_student_record_tags_positions([3, 2, 1])
      :ok

  """
  @spec update_student_record_tags_positions([integer()]) :: :ok | {:error, String.t()}
  def update_student_record_tags_positions(tags_ids), do: update_positions(Tag, tags_ids)

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
      order_by: srs.position
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
    queryable =
      case attrs do
        %{school_id: school_id} ->
          from(srs in StudentRecordStatus, where: srs.school_id == ^school_id)

        %{"school_id" => school_id} ->
          from(srs in StudentRecordStatus, where: srs.school_id == ^school_id)

        _ ->
          StudentRecordStatus
      end

    attrs = set_position_in_attrs(queryable, attrs)

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

  @doc """
  Update student record statuses positions based on ids list order.

  ## Examples

      iex> update_student_record_statuses_positions([3, 2, 1])
      :ok

  """
  @spec update_student_record_statuses_positions([integer()]) :: :ok | {:error, String.t()}
  def update_student_record_statuses_positions(statuses_ids),
    do: update_positions(StudentRecordStatus, statuses_ids)
end
