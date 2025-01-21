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

  - `:note_id` - filter results by attachments linked the note
  - `:assessment_point_entry_id` - filter results by assessment point entry evidences
  - `:student_cycle_info_id` - filter attachments linked to given student cycle info. May be used with `:is_family` option.
  - `:moment_card_id` - filter results by moment card
  - `:shared_with_family` - expect a tuple with type and boolean (view the section below for accepted types). If not given, will not filter results.

  #### `:shared_with_family` supported types

  - `:student_cycle_info` - use with `:student_cycle_info_id` opt
  - `:moment_card` - use with `:moment_card_id` opt

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

  defp apply_list_attachments_opts(queryable, [{:note_id, note_id} | opts])
       when is_integer(note_id) do
    from(
      a in queryable,
      join: na in assoc(a, :note_attachment),
      where: na.note_id == ^note_id,
      order_by: na.position
    )
    |> apply_list_attachments_opts(opts)
  end

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
    |> maybe_filter_by_shared_with_family(Keyword.get(opts, :shared_with_family))
    |> apply_list_attachments_opts(opts)
  end

  defp apply_list_attachments_opts(queryable, [{:moment_card_id, moment_card_id} | opts])
       when is_integer(moment_card_id) do
    from(
      a in queryable,
      join: mca in assoc(a, :moment_card_attachment),
      as: :moment_card_attachment,
      where: mca.moment_card_id == ^moment_card_id,
      order_by: mca.position
    )
    |> maybe_filter_by_shared_with_family(Keyword.get(opts, :shared_with_family))
    |> apply_list_attachments_opts(opts)
  end

  defp apply_list_attachments_opts(queryable, [_ | opts]),
    do: apply_list_attachments_opts(queryable, opts)

  defp maybe_filter_by_shared_with_family(queryable, {:student_cycle_info, is_family})
       when is_boolean(is_family) do
    from(
      [_a, student_cycle_info_attachment: scia] in queryable,
      where: scia.is_family == ^is_family
    )
  end

  defp maybe_filter_by_shared_with_family(queryable, {:moment_card, share_with_family})
       when is_boolean(share_with_family) do
    from(
      [_a, moment_card_attachment: mca] in queryable,
      where: mca.share_with_family == ^share_with_family
    )
  end

  defp maybe_filter_by_shared_with_family(queryable, _shared_tuple),
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
