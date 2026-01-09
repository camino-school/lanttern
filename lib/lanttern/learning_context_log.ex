defmodule Lanttern.LearningContextLog do
  @moduledoc """
  The LearningContextLog context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Identity.Scope
  alias Lanttern.LearningContext.MomentCard
  alias Lanttern.LearningContextLog.MomentCardLog

  @doc """
  Creates a moment_card_log.

  ## Examples

      iex> create_moment_card_log(%{field: value})
      {:ok, %MomentCardLog{}}

      iex> create_moment_card_log(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_moment_card_log(attrs \\ %{}) do
    %MomentCardLog{}
    |> MomentCardLog.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Util for creating moment card logs.

  Accepts `{:ok, %MomentCard{}}` or `{:error, %Ecto.Changeset{}}` tuple as first arg.

  Always returns the card or tuple as is. The logging process is handled in an async task.

  Uses the profile in current scope to log the operation. if not present, logging will be skipped

  """
  @spec maybe_create_moment_card_log(
          {:ok, MomentCard.t()} | {:error, Ecto.Changeset.t()},
          operation :: String.t(),
          scope :: Scope.t()
        ) ::
          {:ok, MomentCard.t()} | {:error, Ecto.Changeset.t()}
  def maybe_create_moment_card_log(
        {:ok, %MomentCard{} = moment_card} = operation_tuple,
        operation,
        %Scope{profile_id: profile_id}
      ) do
    attrs =
      moment_card
      |> Map.from_struct()
      |> Map.put(:moment_card_id, moment_card.id)
      |> Map.put(:profile_id, profile_id)
      |> Map.put(:operation, operation)

    # create the log in a async task (fire and forget)
    Task.Supervisor.start_child(Lanttern.TaskSupervisor, fn ->
      create_moment_card_log(attrs)
    end)

    # return operation tuple
    operation_tuple
  end

  def maybe_create_moment_card_log(operation_tuple, _, _),
    do: operation_tuple
end
