defmodule Lanttern.Attachments do
  @moduledoc """
  The Attachments context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo
  alias Lanttern.SupabaseHelpers

  alias Lanttern.Attachments.Attachment

  @doc """
  Returns the list of attachments.

  ## Options

  - `:assessment_point_entry_id` - filter results by assessment point entry evidences
  - `:student_cycle_info_id` - filter attachments linked to given student cycle info. May be used with `:shared_with_student` option.
  - `:lesson_id` - filter results by lesson. May be used with `:is_teacher_only_resource` option.
  - `:ilp_comment_id` - filter results by ILP comment
  - `:student_record_id` - filter results by student record
  - `:shared_with_student` - expect a tuple with type and boolean (view the section below for accepted types). If not given, will not filter results.
  - `:is_teacher_only_resource` - expect a tuple with type and boolean (view the section below for accepted types). If not given, will not filter results.

  #### `:shared_with_student` supported types

  - `:student_cycle_info` - use with `:student_cycle_info_id` opt

  #### `:is_teacher_only_resource` supported types

  - `:lesson` - use with `:lesson_id` opt

  ## Examples

      iex> list_attachments()
      [%Attachment{}, ...]

  """
  def list_attachments(opts \\ []) do
    Attachment
    |> apply_list_attachments_opts(opts)
    |> Repo.all()
  end

  defp apply_list_attachments_opts(queryable, []), do: queryable

  defp apply_list_attachments_opts(queryable, [
         {:assessment_point_entry_id, assessment_point_entry_id} | opts
       ])
       when is_integer(assessment_point_entry_id) do
    from(
      a in queryable,
      join: apee in assoc(a, :assessment_point_entry_evidence),
      where: apee.assessment_point_entry_id == ^assessment_point_entry_id,
      order_by: apee.position
    )
    |> apply_list_attachments_opts(opts)
  end

  defp apply_list_attachments_opts(queryable, [
         {:student_cycle_info_id, student_cycle_info_id} | opts
       ])
       when is_integer(student_cycle_info_id) do
    from(
      a in queryable,
      join: scia in assoc(a, :student_cycle_info_attachment),
      as: :student_cycle_info_attachment,
      where: scia.student_cycle_info_id == ^student_cycle_info_id,
      order_by: scia.position
    )
    |> maybe_filter_by_shared_with_student(Keyword.get(opts, :shared_with_student))
    |> apply_list_attachments_opts(opts)
  end

  defp apply_list_attachments_opts(queryable, [{:lesson_id, lesson_id} | opts])
       when is_integer(lesson_id) do
    from(
      a in queryable,
      join: la in assoc(a, :lesson_attachment),
      as: :lesson_attachment,
      where: la.lesson_id == ^lesson_id,
      order_by: la.position,
      select: %{a | is_teacher_only: la.is_teacher_only_resource}
    )
    |> maybe_filter_by_is_teacher_only_resource(Keyword.get(opts, :is_teacher_only_resource))
    |> apply_list_attachments_opts(opts)
  end

  defp apply_list_attachments_opts(queryable, [{:ilp_comment_id, ilp_comment_id} | opts])
       when is_integer(ilp_comment_id) do
    from(
      a in queryable,
      join: ica in assoc(a, :ilp_comment_attachment),
      as: :ilp_comment_attachment,
      where: ica.ilp_comment_id == ^ilp_comment_id,
      order_by: ica.position
    )
    |> apply_list_attachments_opts(opts)
  end

  defp apply_list_attachments_opts(queryable, [
         {:student_record_id, student_record_id} | opts
       ])
       when is_integer(student_record_id) do
    from(
      a in queryable,
      join: sra in assoc(a, :student_record_attachment),
      where: sra.student_record_id == ^student_record_id,
      order_by: sra.position
    )
    |> apply_list_attachments_opts(opts)
  end

  defp apply_list_attachments_opts(queryable, [_ | opts]),
    do: apply_list_attachments_opts(queryable, opts)

  defp maybe_filter_by_shared_with_student(queryable, {:student_cycle_info, shared_with_student})
       when is_boolean(shared_with_student) do
    from(
      [_a, student_cycle_info_attachment: scia] in queryable,
      where: scia.shared_with_student == ^shared_with_student
    )
  end

  defp maybe_filter_by_shared_with_student(queryable, _shared_tuple),
    do: queryable

  defp maybe_filter_by_is_teacher_only_resource(queryable, {:lesson, is_teacher_only_resource})
       when is_boolean(is_teacher_only_resource) do
    from(
      [_a, lesson_attachment: la] in queryable,
      where: la.is_teacher_only_resource == ^is_teacher_only_resource
    )
  end

  defp maybe_filter_by_is_teacher_only_resource(queryable, _tuple),
    do: queryable

  @doc """
  Gets a single attachment.

  Raises `Ecto.NoResultsError` if the Attachment does not exist.

  ## Examples

      iex> get_attachment!(123)
      %Attachment{}

      iex> get_attachment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_attachment!(id), do: Repo.get!(Attachment, id)

  @doc """
  Creates a attachment.

  ## Examples

      iex> create_attachment(%{field: value})
      {:ok, %Attachment{}}

      iex> create_attachment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_attachment(attrs \\ %{}) do
    %Attachment{}
    |> Attachment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a attachment.

  ## Examples

      iex> update_attachment(attachment, %{field: new_value})
      {:ok, %Attachment{}}

      iex> update_attachment(attachment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_attachment(%Attachment{} = attachment, attrs) do
    attachment
    |> Attachment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a attachment.

  ## Examples

      iex> delete_attachment(attachment)
      {:ok, %Attachment{}}

      iex> delete_attachment(attachment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_attachment(%Attachment{} = attachment) do
    Repo.delete(attachment)
    |> case do
      {:ok, _} = res ->
        # if attachment is internal (Supabase),
        # delete from cloud in an async task (fire and forget)
        maybe_delete_attachment_from_cloud(attachment, res)

      {:error, _} = res ->
        res
    end
  end

  @doc """
  Delete an attachment from cloud if attachment is internal.

  ## Examples

      iex> maybe_delete_attachment_from_cloud(attachment, {:ok, %Attachment{}})
      {:ok, %Attachment{}}

  """
  @spec maybe_delete_attachment_from_cloud(Attachment.t(), res :: any()) :: any()
  def maybe_delete_attachment_from_cloud(attachment, res \\ nil)

  def maybe_delete_attachment_from_cloud(%{is_external: false} = attachment, res) do
    Task.Supervisor.start_child(Lanttern.TaskSupervisor, fn ->
      SupabaseHelpers.remove_object("attachments", attachment.link)
    end)

    res
  end

  def maybe_delete_attachment_from_cloud(_attachment, res), do: res

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking attachment changes.

  ## Examples

      iex> change_attachment(attachment)
      %Ecto.Changeset{data: %Attachment{}}

  """
  def change_attachment(%Attachment{} = attachment, attrs \\ %{}) do
    Attachment.changeset(attachment, attrs)
  end
end
