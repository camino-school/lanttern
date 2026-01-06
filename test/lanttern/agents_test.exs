defmodule Lanttern.AgentsTest do
  use Lanttern.DataCase

  alias Lanttern.Agents

  import Lanttern.Factory

  describe "ai_agents" do
    alias Lanttern.Agents.Agent

    @invalid_attrs %{
      name: nil,
      instructions: nil,
      knowledge: nil,
      personality: nil,
      guardrails: nil
    }

    test "list_ai_agents/0 returns all ai_agents ordered by name" do
      agent_c = insert(:agent, name: "Charlie Agent")
      agent_a = insert(:agent, name: "Alpha Agent")
      agent_b = insert(:agent, name: "Bravo Agent")

      agents = Agents.list_ai_agents()

      assert [agent_a.id, agent_b.id, agent_c.id] == Enum.map(agents, & &1.id)
    end

    test "list_ai_agents/1 with school_id filter returns only agents from that school" do
      school_1 = insert(:school)
      school_2 = insert(:school)

      agent_1 = insert(:agent, name: "Agent 1", school: school_1)
      agent_2 = insert(:agent, name: "Agent 2", school: school_2)
      agent_3 = insert(:agent, name: "Agent 3", school: school_1)

      agents = Agents.list_ai_agents(school_id: school_1.id)

      assert length(agents) == 2
      assert [agent_1.id, agent_3.id] == Enum.map(agents, & &1.id)

      agents_school_2 = Agents.list_ai_agents(school_id: school_2.id)

      assert length(agents_school_2) == 1
      assert [agent_2.id] == Enum.map(agents_school_2, & &1.id)
    end

    test "get_agent!/1 returns the agent with given id" do
      agent = insert(:agent)
      expected_agent = Agents.get_agent!(agent.id)

      assert expected_agent.id == agent.id
      assert expected_agent.name == agent.name
      assert expected_agent.school_id == agent.school_id
    end

    test "create_agent/1 with valid data creates a agent" do
      school = insert(:school)

      valid_attrs = %{
        name: "some name",
        instructions: "some instructions",
        knowledge: "some knowledge",
        personality: "some personality",
        guardrails: "some guardrails",
        school_id: school.id
      }

      assert {:ok, %Agent{} = agent} = Agents.create_agent(valid_attrs)
      assert agent.name == "some name"
      assert agent.instructions == "some instructions"
      assert agent.knowledge == "some knowledge"
      assert agent.personality == "some personality"
      assert agent.guardrails == "some guardrails"
    end

    test "create_agent/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Agents.create_agent(@invalid_attrs)
    end

    test "update_agent/2 with valid data updates the agent" do
      agent = insert(:agent)

      update_attrs = %{
        name: "some updated name",
        instructions: "some updated instructions",
        knowledge: "some updated knowledge",
        personality: "some updated personality",
        guardrails: "some updated guardrails"
      }

      assert {:ok, %Agent{} = agent} = Agents.update_agent(agent, update_attrs)
      assert agent.name == "some updated name"
      assert agent.instructions == "some updated instructions"
      assert agent.knowledge == "some updated knowledge"
      assert agent.personality == "some updated personality"
      assert agent.guardrails == "some updated guardrails"
    end

    test "update_agent/2 with invalid data returns error changeset" do
      agent = insert(:agent)
      assert {:error, %Ecto.Changeset{}} = Agents.update_agent(agent, @invalid_attrs)

      expected_agent = Agents.get_agent!(agent.id)
      assert expected_agent.id == agent.id
      assert expected_agent.name == agent.name
    end

    test "delete_agent/1 deletes the agent" do
      agent = insert(:agent)
      assert {:ok, %Agent{}} = Agents.delete_agent(agent)
      assert_raise Ecto.NoResultsError, fn -> Agents.get_agent!(agent.id) end
    end

    test "change_agent/1 returns a agent changeset" do
      agent = insert(:agent)
      assert %Ecto.Changeset{} = Agents.change_agent(agent)
    end
  end
end
