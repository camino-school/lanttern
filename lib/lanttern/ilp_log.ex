defmodule Lanttern.ILPLog do
  @moduledoc """
  The ILPLog context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.ILP.StudentILP
  alias Lanttern.ILPLog.StudentILPLog

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
end
