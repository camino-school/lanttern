defmodule Lanttern.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Lanttern.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias Lanttern.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Lanttern.DataCase
    end
  end

  setup tags do
    Lanttern.DataCase.setup_sandbox(tags)
    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Lanttern.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  @doc """
  A helper to be used `on_exit/1` for tests where supervised tasks are created.

  Based on https://elixirforum.com/t/36605/2 and https://elixirforum.com/t/41489/5

      on_exit(fn ->
        assert_supervised_tasks_are_down()
        if needed, do something after supervised tasks are finished
      end)

  """
  def assert_supervised_tasks_are_down do
    for pid <- Task.Supervisor.children(Lanttern.TaskSupervisor) do
      # # check for message queue len to avoid
      # # awaiting on empty message boxes
      # {:message_queue_len, len} = Process.info(pid, :message_queue_len)

      # if len > 0 do
      ref = Process.monitor(pid)
      assert_receive {:DOWN, ^ref, _, _, _}, 10_000
      # end
    end
  end
end
