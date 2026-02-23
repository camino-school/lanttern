defmodule Lanttern.Agents do
  @moduledoc """
  The Agents context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Agents.Agent
  alias Lanttern.Identity.Scope

  @doc """
  Returns the list of ai_agents.

  ## Examples

      iex> list_ai_agents(scope)
      [%Agent{}, ...]

  """
  def list_ai_agents(%Scope{} = scope) do
    from(
      a in Agent,
      where: a.school_id == ^scope.school_id,
      order_by: [asc: :name]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single agent.

  Raises `Ecto.NoResultsError` if the Agent does not exist.

  ## Examples

      iex> get_agent!(scope, 123)
      %Agent{}

      iex> get_agent!(scope, 456)
      ** (Ecto.NoResultsError)

  """
  def get_agent!(%Scope{} = scope, id) do
    Repo.get_by!(Agent, id: id, school_id: scope.school_id)
  end

  @doc """
  Creates a agent.

  ## Examples

      iex> create_agent(scope, %{field: value})
      {:ok, %Agent{}}

      iex> create_agent(scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_agent(%Scope{} = scope, attrs) do
    true = Scope.has_permission?(scope, "agents_management")

    %Agent{}
    |> Agent.changeset(attrs, scope)
    |> Repo.insert()
  end

  @doc """
  Updates a agent.

  ## Examples

      iex> update_agent(scope, agent, %{field: new_value})
      {:ok, %Agent{}}

      iex> update_agent(scope, agent, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_agent(%Scope{} = scope, %Agent{} = agent, attrs) do
    true = Scope.has_permission?(scope, "agents_management")
    true = Scope.belongs_to_school?(scope, agent.school_id)

    agent
    |> Agent.changeset(attrs, scope)
    |> Repo.update()
  end

  @doc """
  Deletes a agent.

  ## Examples

      iex> delete_agent(scope, agent)
      {:ok, %Agent{}}

      iex> delete_agent(scope, agent)
      {:error, %Ecto.Changeset{}}

  """
  def delete_agent(%Scope{} = scope, %Agent{} = agent) do
    true = Scope.has_permission?(scope, "agents_management")
    true = Scope.belongs_to_school?(scope, agent.school_id)

    Repo.delete(agent)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking agent changes.

  ## Examples

      iex> change_agent(scope, agent)
      %Ecto.Changeset{data: %Agent{}}

  """
  def change_agent(%Scope{} = scope, %Agent{} = agent, attrs \\ %{}) do
    true = Scope.has_permission?(scope, "agents_management")
    true = Scope.belongs_to_school?(scope, agent.school_id)

    Agent.changeset(agent, attrs, scope)
  end
end
