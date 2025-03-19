defmodule Lanttern.StudentsCycleInfo do
  @moduledoc """
  The StudentsCycleInfo context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Schools.Student
  alias Lanttern.Repo

  import Lanttern.RepoHelpers

  alias Lanttern.Attachments.Attachment
  alias Lanttern.StudentsCycleInfoLog
  alias Lanttern.StudentsCycleInfo.StudentCycleInfo
  alias Lanttern.StudentsCycleInfo.StudentCycleInfoAttachment
  alias Lanttern.Schools.Class
  alias Lanttern.Schools.Cycle

  @doc """
  Returns the list of students_cycle_info.

  ## Examples

      iex> list_students_cycle_info()
      [%StudentCycleInfo{}, ...]

  """
  def list_students_cycle_info do
    Repo.all(StudentCycleInfo)
  end

  @doc """
  Gets a single student_cycle_info.

  Raises `Ecto.NoResultsError` if the Student cycle info does not exist.

  ## Examples

      iex> get_student_cycle_info!(123)
      %StudentCycleInfo{}

      iex> get_student_cycle_info!(456)
      ** (Ecto.NoResultsError)

  """
  def get_student_cycle_info!(id), do: Repo.get!(StudentCycleInfo, id)

  @doc """
  Gets a single student_cycle_info based on given student and cycle id.

  Returns `nil` if the Student cycle info does not exist.

  ## Options:

  - `:check_attachments_for` - supports `:school` or `:student`. will check for linked attachments of given type and set `has_attachments` field

  ## Examples

      iex> get_student_cycle_info_by_student_and_cycle(student_id, cycle_id)
      %StudentCycleInfo{}

      iex> get_student_cycle_info_by_student_and_cycle(student_id, cycle_id)
      nil

  """
  @spec get_student_cycle_info_by_student_and_cycle(
          student_id :: pos_integer(),
          cycle_id :: pos_integer(),
          opts :: Keyword.t()
        ) :: StudentCycleInfo.t() | nil
  def get_student_cycle_info_by_student_and_cycle(student_id, cycle_id, opts \\ []) do
    from(
      sci in StudentCycleInfo,
      where: sci.student_id == ^student_id,
      where: sci.cycle_id == ^cycle_id
    )
    |> apply_get_student_cycle_info_by_student_and_cycle_opts(opts)
    |> Repo.one()
  end

  defp apply_get_student_cycle_info_by_student_and_cycle_opts(queryable, []), do: queryable

  defp apply_get_student_cycle_info_by_student_and_cycle_opts(queryable, [
         {:check_attachments_for, type} | opts
       ])
       when type in [:school, :student] do
    is_student = if type == :student, do: true, else: false

    from(
      sci in queryable,
      left_join: scia in assoc(sci, :student_cycle_info_attachments),
      on: scia.shared_with_student == ^is_student,
      group_by: sci.id,
      select: %{sci | has_attachments: count(scia.id) > 0}
    )
    |> apply_get_student_cycle_info_by_student_and_cycle_opts(opts)
  end

  defp apply_get_student_cycle_info_by_student_and_cycle_opts(queryable, [_ | opts]),
    do: apply_get_student_cycle_info_by_student_and_cycle_opts(queryable, opts)

  @doc """
  Creates a student_cycle_info.

  ## Options:

  - `:log_profile_id` - logs the operation, linked to given profile

  ## Examples

    iex> create_student_cycle_info(%{field: value})
    {:ok, %StudentCycleInfo{}}

    iex> create_student_cycle_info(%{field: bad_value})
    {:error, %Ecto.Changeset{}}

  """
  def create_student_cycle_info(attrs \\ %{}, opts \\ []) do
    %StudentCycleInfo{}
    |> StudentCycleInfo.changeset(attrs)
    |> Repo.insert()
    |> StudentsCycleInfoLog.maybe_create_student_cycle_info_log("CREATE", opts)
  end

  @doc """
  Updates a student_cycle_info.

  ## Options:

  - `:log_profile_id` - logs the operation, linked to given profile

  ## Examples

      iex> update_student_cycle_info(student_cycle_info, %{field: new_value})
      {:ok, %StudentCycleInfo{}}

      iex> update_student_cycle_info(student_cycle_info, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_student_cycle_info(%StudentCycleInfo{} = student_cycle_info, attrs, opts \\ []) do
    student_cycle_info
    |> StudentCycleInfo.changeset(attrs)
    |> Repo.update()
    |> StudentsCycleInfoLog.maybe_create_student_cycle_info_log("UPDATE", opts)
  end

  @doc """
  Deletes a student_cycle_info.

  ## Options:

  - `:log_profile_id` - logs the operation, linked to given profile

  ## Examples

      iex> delete_student_cycle_info(student_cycle_info)
      {:ok, %StudentCycleInfo{}}

      iex> delete_student_cycle_info(student_cycle_info)
      {:error, %Ecto.Changeset{}}

  """
  def delete_student_cycle_info(%StudentCycleInfo{} = student_cycle_info, opts \\ []) do
    Repo.delete(student_cycle_info)
    |> StudentsCycleInfoLog.maybe_create_student_cycle_info_log("DELETE", opts)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking student_cycle_info changes.

  ## Examples

      iex> change_student_cycle_info(student_cycle_info)
      %Ecto.Changeset{data: %StudentCycleInfo{}}

  """
  def change_student_cycle_info(%StudentCycleInfo{} = student_cycle_info, attrs \\ %{}) do
    StudentCycleInfo.changeset(student_cycle_info, attrs)
  end

  @doc """
  List parent cycles with a list of classes related to the given student.

  Results are ordered by cycle end_at desc and cycle start_at asc.

  Classes in tuple are ordered alphabetically.

  ## Examples

      iex> list_cycles_and_classes_for_student(student)
      [{%Cycle{}, [%Class{}, ...]}, ...]

  """
  @spec list_cycles_and_classes_for_student(Student.t()) :: [
          {Cycle.t(), [Class.t()]}
        ]
  def list_cycles_and_classes_for_student(%Student{} = student) do
    student_classes_map =
      from(
        c in Class,
        join: s in assoc(c, :students),
        where: s.id == ^student.id,
        order_by: [asc: c.name]
      )
      |> Repo.all()
      |> Enum.group_by(& &1.cycle_id)

    from(
      cy in Cycle,
      where: cy.school_id == ^student.school_id,
      where: is_nil(cy.parent_cycle_id),
      order_by: [desc: cy.end_at, asc: cy.start_at]
    )
    |> Repo.all()
    |> Enum.map(fn cycle ->
      {cycle, student_classes_map[cycle.id] || []}
    end)
  end

  @doc """
  Creates an attachment and links it to an existing student cycle info in a single transaction.

  ## Examples

      iex> create_student_cycle_info_attachment(profile_id, student_cycle_info_id, %{field: value})
      {:ok, %Attachment{}}

      iex> create_student_cycle_info_attachment(profile_id, student_cycle_info_id, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_student_cycle_info_attachment(
          profile_id :: pos_integer(),
          student_cycle_info_id :: pos_integer(),
          attachment_attrs :: map(),
          shared_with_student :: boolean()
        ) ::
          {:ok, Attachment.t()} | {:error, Ecto.Changeset.t()}
  def create_student_cycle_info_attachment(
        profile_id,
        student_cycle_info_id,
        attachment_attrs,
        shared_with_student \\ false
      ) do
    insert_query =
      %Attachment{}
      |> Attachment.changeset(Map.put(attachment_attrs, "owner_id", profile_id))

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:insert_attachment, insert_query)
    |> Ecto.Multi.run(
      :link_student_cycle_info,
      fn _repo, %{insert_attachment: attachment} ->
        attrs =
          from(
            scia in StudentCycleInfoAttachment,
            where: scia.student_cycle_info_id == ^student_cycle_info_id
          )
          |> set_position_in_attrs(%{
            student_cycle_info_id: student_cycle_info_id,
            attachment_id: attachment.id,
            shared_with_student: shared_with_student,
            owner_id: profile_id
          })

        %StudentCycleInfoAttachment{}
        |> StudentCycleInfoAttachment.changeset(attrs)
        |> Repo.insert()
      end
    )
    |> Repo.transaction()
    |> case do
      {:error, _multi, changeset, _changes} -> {:error, changeset}
      {:ok, %{insert_attachment: attachment}} -> {:ok, attachment}
    end
  end

  @doc """
  Update student cycle info attachments positions based on ids list order.

  ## Examples

  iex> update_student_cycle_info_attachments_positions([3, 2, 1])
  :ok

  """
  @spec update_student_cycle_info_attachments_positions(attachments_ids :: [pos_integer()]) ::
          :ok | {:error, String.t()}
  def update_student_cycle_info_attachments_positions(attachments_ids),
    do: update_positions(StudentCycleInfoAttachment, attachments_ids, id_field: :attachment_id)

  @doc """
  """

  @spec build_students_cycle_info_profile_picture_url_map(
          cycle_id :: pos_integer(),
          students_ids :: [pos_integer()]
        ) :: %{pos_integer() => String.t() | nil}
  def build_students_cycle_info_profile_picture_url_map(cycle_id, students_ids) do
    from(
      sci in StudentCycleInfo,
      where: sci.cycle_id == ^cycle_id,
      where: sci.student_id in ^students_ids,
      select: {sci.student_id, sci.profile_picture_url}
    )
    |> Repo.all()
    |> Enum.into(%{})
  end
end
