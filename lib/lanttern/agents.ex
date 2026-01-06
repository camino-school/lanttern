defmodule Lanttern.Agents do
  @moduledoc """
  The Agents context.
  """

  import Ecto.Query, warn: false
  alias Lanttern.Repo

  alias Lanttern.Agents.Agent

  @doc """
  Returns the list of ai_agents.

  ## Options

  - `:school_id` - filter agents by school

  ## Examples

      iex> list_ai_agents()
      [%Agent{}, ...]

      iex> list_ai_agents(school_id: 1)
      [%Agent{}, ...]

  """
  def list_ai_agents(opts \\ []) do
    from(
      a in Agent,
      order_by: [asc: :name]
    )
    |> apply_list_ai_agents_opts(opts)
    |> Repo.all()
  end

  defp apply_list_ai_agents_opts(queryable, []), do: queryable

  defp apply_list_ai_agents_opts(queryable, [{:school_id, school_id} | opts]) do
    from(a in queryable, where: a.school_id == ^school_id)
    |> apply_list_ai_agents_opts(opts)
  end

  defp apply_list_ai_agents_opts(queryable, [_ | opts]),
    do: apply_list_ai_agents_opts(queryable, opts)

  @doc """
  Gets a single agent.

  Raises `Ecto.NoResultsError` if the Agent does not exist.

  ## Examples

      iex> get_agent!(123)
      %Agent{}

      iex> get_agent!(456)
      ** (Ecto.NoResultsError)

  """
  def get_agent!(id), do: Repo.get!(Agent, id)

  @doc """
  Creates a agent.

  ## Examples

      iex> create_agent(%{field: value})
      {:ok, %Agent{}}

      iex> create_agent(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_agent(attrs) do
    %Agent{}
    |> Agent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a agent.

  ## Examples

      iex> update_agent(agent, %{field: new_value})
      {:ok, %Agent{}}

      iex> update_agent(agent, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_agent(%Agent{} = agent, attrs) do
    agent
    |> Agent.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a agent.

  ## Examples

      iex> delete_agent(agent)
      {:ok, %Agent{}}

      iex> delete_agent(agent)
      {:error, %Ecto.Changeset{}}

  """
  def delete_agent(%Agent{} = agent) do
    Repo.delete(agent)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking agent changes.

  ## Examples

      iex> change_agent(agent)
      %Ecto.Changeset{data: %Agent{}}

  """
  def change_agent(%Agent{} = agent, attrs \\ %{}) do
    Agent.changeset(agent, attrs)
  end
end
