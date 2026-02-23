defmodule Lanttern.AuditLog do
  @moduledoc """
  Unified audit logging orchestration.

  Provides a behaviour for log schemas and a `maybe_log/5` function
  that handles the common pattern of conditionally logging operations
  in either async (prod/dev) or sync (test) mode.

  ## Usage

  Log schemas implement the `build_log_attrs/1` callback:

      defmodule MyLog do
        @behaviour Lanttern.AuditLog

        @impl true
        def build_log_attrs(%MyStruct{} = record) do
          %{my_struct_id: record.id, name: record.name, ...}
        end
      end

  Context modules delegate to `maybe_log/5`:

      AuditLog.maybe_log({:ok, record}, MyLog, "CREATE", scope, opts)

  """

  require Logger

  alias Lanttern.Identity.Scope
  alias Lanttern.Repo

  @callback build_log_attrs(source :: struct()) :: map()

  @doc """
  Conditionally creates a log entry for an operation result.

  On `{:ok, record}` with a non-nil `profile_id` in scope, inserts a log entry.
  On `{:error, changeset}` or nil `profile_id`, returns the tuple unchanged.

  ## Options

    * `:is_ai_agent` - marks the log entry as AI-generated (default: `false`)

  """
  @spec maybe_log(
          result :: {:ok, struct()} | {:error, Ecto.Changeset.t()},
          log_schema :: module(),
          operation :: String.t(),
          scope :: Scope.t(),
          opts :: keyword()
        ) :: {:ok, struct()} | {:error, Ecto.Changeset.t()}
  def maybe_log({:ok, record}, log_schema, operation, %Scope{profile_id: pid}, opts)
      when not is_nil(pid) do
    do_log(record, log_schema, operation, pid, opts)
    {:ok, record}
  end

  def maybe_log(result, _log_schema, _operation, _scope, _opts), do: result

  defp do_log(record, log_schema, operation, profile_id, opts) do
    attrs =
      log_schema.build_log_attrs(record)
      |> Map.put(:profile_id, profile_id)
      |> Map.put(:operation, operation)
      |> Map.put(:is_ai_agent, Keyword.get(opts, :is_ai_agent, false))

    changeset =
      log_schema
      |> struct()
      |> log_schema.changeset(attrs)

    case mode() do
      :sync ->
        insert_log(changeset)

      :async ->
        Task.Supervisor.start_child(Lanttern.TaskSupervisor, fn ->
          insert_log(changeset)
        end)
    end
  end

  defp insert_log(changeset) do
    case Repo.insert(changeset) do
      {:ok, _log} ->
        :ok

      {:error, changeset} ->
        Logger.warning("Failed to insert audit log: #{inspect(changeset.errors)}")
        :error
    end
  end

  defp mode do
    Application.get_env(:lanttern, __MODULE__, [])[:mode] || :async
  end
end
