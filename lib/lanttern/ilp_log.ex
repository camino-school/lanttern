defmodule Lanttern.ILPLog do
  @moduledoc """
  The ILPLog context.
  """

  alias Lanttern.ILP.ILPComment
  alias Lanttern.ILP.StudentILP
  alias Lanttern.ILPLog.ILPCommentLog
  alias Lanttern.ILPLog.StudentILPLog
  alias Lanttern.Repo

  import Ecto.Query, warn: false

  @doc """
  Creates a student_ilp_log.

  ## Examples

      iex> create_student_ilp_log(%{field: value})
      {:ok, %StudentILPLog{}}

      iex> create_student_ilp_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_student_ilp_log(attrs \\ %{}) do
    %StudentILPLog{}
    |> StudentILPLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Util for create a student ILP log.

  Accepts `{:ok, %StudentILP{}}` or `{:error, %Ecto.Changeset{}}` tuple as first arg.

  Always returns the ilp or tuple as is. The logging process is handled in an async task.

  ### Options:

  - `:log_profile_id` – the profile id used to log the operation. if not present, logging will be skipped

  """
  @spec maybe_create_student_ilp_log(
          {:ok, StudentILP.t()} | {:error, Ecto.Changeset.t()},
          operation :: String.t(),
          opts :: Keyword.t()
        ) ::
          {:ok, StudentILP.t()} | {:error, Ecto.Changeset.t()}
  def maybe_create_student_ilp_log(operation_tuple, operation, opts \\ [])

  def maybe_create_student_ilp_log({:error, _} = operation_tuple, _, _), do: operation_tuple

  def maybe_create_student_ilp_log(
        {:ok, %StudentILP{} = student_ilp} = operation_tuple,
        operation,
        opts
      ) do
    case Keyword.get(opts, :log_profile_id) do
      profile_id when not is_nil(profile_id) ->
        do_create_student_ilp_log(student_ilp, operation, profile_id)
        operation_tuple

      _ ->
        operation_tuple
    end
  end

  defp do_create_student_ilp_log(student_ilp, operation, profile_id) do
    attrs =
      student_ilp
      # ensure entries are loaded
      |> Repo.preload(:entries)
      |> Map.from_struct()
      |> Map.put(:student_ilp_id, student_ilp.id)
      |> Map.put(:profile_id, profile_id)
      |> Map.put(:operation, operation)

    attrs =
      if operation != "DELETE" do
        attrs
        |> Map.update(:entries, [], fn entries ->
          Enum.map(entries, &Map.from_struct/1)
        end)
      else
        Map.drop(attrs, [:entries])
      end

    # create the log in a async task (fire and forget)
    Task.Supervisor.start_child(Lanttern.TaskSupervisor, fn ->
      create_student_ilp_log(attrs)
    end)
  end

  @doc """
  Creates a ilp_comment_log for Lanttern.ILP.ILPComment
  ## Examples

      iex> create_ilp_comment_log(%{field: value})
      {:ok, %ILPCommentLog{}}

      iex> create_ilp_comment_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_ilp_comment_log(attrs \\ %{}) do
    %ILPCommentLog{}
    |> ILPCommentLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Util for creating an ILP comment log.

  Accepts create, update, and delete function responses (tuples) as first arg.

  Always returns the first arg as is. The logging process is handled in an async task.

  ### Options:

  - `:log_profile_id` – the profile id used to log the operation. if not present, logging will be skipped

  """
  @spec maybe_create_ilp_comment_log(
          operation_tuple :: {:ok, ILPComment.t()} | any(),
          operation :: :CREATE | :UPDATE | :DELETE,
          opts :: Keyword.t()
        ) :: {:ok, ILPComment.t()} | any()
  def maybe_create_ilp_comment_log(operation_tuple, operation, opts) do
    operation_tuple
    |> tap(&async_create_ilp_comment_log(&1, operation, Keyword.get(opts, :log_profile_id)))
  end

  defp async_create_ilp_comment_log({:ok, %ILPComment{} = ilp_comment}, operation, profile_id)
       when operation in [:CREATE, :UPDATE, :DELETE] and is_integer(profile_id) do
    ilp_comment
    |> Map.from_struct()
    |> Map.put(:ilp_comment_id, ilp_comment.id)
    |> Map.put(:profile_id, profile_id)
    |> Map.put(:operation, operation)
    |> then(
      &Task.Supervisor.start_child(Lanttern.TaskSupervisor, fn ->
        create_ilp_comment_log(&1)
      end)
    )
  end

  defp async_create_ilp_comment_log(_ilp_comment, _operation, _profile_id), do: :nothing
end
