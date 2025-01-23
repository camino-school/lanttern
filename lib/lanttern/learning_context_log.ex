defmodule Lanttern.LearningContextLog do
  @moduledoc """
  The LearningContextLog context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

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
  Util for create a moment card log.

  Accepts `{:ok, %MomentCard{}}` or `{:error, %Ecto.Changeset{}}` tuple as first arg.

  Always returns the card or tuple as is. The logging process is handled in an async task.

  ### Options:

  - `:log_profile_id` – the profile id used to log the operation. if not present, logging will be skipped

  """
  @spec maybe_create_moment_card_log(
          {:ok, MomentCard.t()} | {:error, Ecto.Changeset.t()},
          operation :: String.t(),
          opts :: Keyword.t()
        ) ::
          {:ok, MomentCard.t()} | {:error, Ecto.Changeset.t()}
  def maybe_create_moment_card_log(operation_tuple, operation, opts \\ [])

  def maybe_create_moment_card_log({:error, _} = operation_tuple, _, _),
    do: operation_tuple

  def maybe_create_moment_card_log(
        {:ok, %MomentCard{} = moment_card} = operation_tuple,
        operation,
        opts
      ) do
    case Keyword.get(opts, :log_profile_id) do
      profile_id when not is_nil(profile_id) ->
        do_create_moment_card_log(moment_card, operation, profile_id)
        operation_tuple

      _ ->
        operation_tuple
    end
  end

  defp do_create_moment_card_log(moment_card, operation, profile_id) do
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
  end
end
