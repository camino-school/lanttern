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

  ## Examples

      iex> list_attachments()
      [%Attachment{}, ...]

  """
  def list_attachments do
    Repo.all(Attachment)
  end

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

  defp maybe_delete_attachment_from_cloud(%{is_external: false} = attachment, res) do
    Task.Supervisor.start_child(Lanttern.TaskSupervisor, fn ->
      SupabaseHelpers.remove_object("attachments", attachment.link)
    end)

    res
  end

  defp maybe_delete_attachment_from_cloud(_attachment, res), do: res

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
