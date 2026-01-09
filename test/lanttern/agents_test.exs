defmodule Lanttern.AgentsTest do
  use Lanttern.DataCase

  alias Lanttern.Agents

  import Lanttern.Factory

  describe "ai_agents" do
    alias Lanttern.Agents.Agent
    alias Lanttern.IdentityFixtures
    alias Lanttern.Schools.School

    @invalid_attrs %{
      name: nil,
      instructions: nil,
      knowledge: nil,
      personality: nil,
      guardrails: nil
    }

    test "list_ai_agents/1 returns all ai_agents from scope's school ordered by name" do
      scope = IdentityFixtures.scope_fixture()
      school = Repo.get!(School, scope.school_id)

      # Insert agents for the scope's school
      agent_c = insert(:agent, %{name: "Charlie Agent", school: school})
      agent_a = insert(:agent, %{name: "Alpha Agent", school: school})
      agent_b = insert(:agent, %{name: "Bravo Agent", school: school})

      # Create agent from different school to verify filtering
      other_school = insert(:school)
      insert(:agent, %{name: "Other School Agent", school: other_school})

      agents = Agents.list_ai_agents(scope)

      assert [agent_a.id, agent_b.id, agent_c.id] == Enum.map(agents, & &1.id)
    end

    test "get_agent!/2 returns the agent with given id from scope's school" do
      scope = IdentityFixtures.scope_fixture()
      school = Repo.get!(School, scope.school_id)
      agent = insert(:agent, %{school: school})

      expected_agent = Agents.get_agent!(scope, agent.id)

      assert expected_agent.id == agent.id
      assert expected_agent.name == agent.name
      assert expected_agent.school_id == agent.school_id
    end

    test "create_agent/2 with valid data creates a agent" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["agents_management"]})

      valid_attrs = %{
        name: "some name",
        instructions: "some instructions",
        knowledge: "some knowledge",
        personality: "some personality",
        guardrails: "some guardrails"
      }

      assert {:ok, %Agent{} = agent} = Agents.create_agent(scope, valid_attrs)
      assert agent.name == "some name"
      assert agent.instructions == "some instructions"
      assert agent.knowledge == "some knowledge"
      assert agent.personality == "some personality"
      assert agent.guardrails == "some guardrails"
      assert agent.school_id == scope.school_id
    end

    test "create_agent/2 with invalid data returns error changeset" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["agents_management"]})

      assert {:error, %Ecto.Changeset{}} = Agents.create_agent(scope, @invalid_attrs)
    end

    test "update_agent/3 with valid data updates the agent" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["agents_management"]})
      school = Repo.get!(School, scope.school_id)
      agent = insert(:agent, %{school: school})

      update_attrs = %{
        name: "some updated name",
        instructions: "some updated instructions",
        knowledge: "some updated knowledge",
        personality: "some updated personality",
        guardrails: "some updated guardrails"
      }

      assert {:ok, %Agent{} = updated_agent} = Agents.update_agent(scope, agent, update_attrs)
      assert updated_agent.name == "some updated name"
      assert updated_agent.instructions == "some updated instructions"
      assert updated_agent.knowledge == "some updated knowledge"
      assert updated_agent.personality == "some updated personality"
      assert updated_agent.guardrails == "some updated guardrails"
      assert updated_agent.school_id == scope.school_id
    end

    test "update_agent/3 with invalid data returns error changeset" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["agents_management"]})
      school = Repo.get!(School, scope.school_id)
      agent = insert(:agent, %{school: school})

      assert {:error, %Ecto.Changeset{}} = Agents.update_agent(scope, agent, @invalid_attrs)

      expected_agent = Agents.get_agent!(scope, agent.id)
      assert expected_agent.id == agent.id
      assert expected_agent.name == agent.name
    end

    test "delete_agent/2 deletes the agent" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["agents_management"]})
      school = Repo.get!(School, scope.school_id)
      agent = insert(:agent, %{school: school})

      assert {:ok, %Agent{}} = Agents.delete_agent(scope, agent)
      assert_raise Ecto.NoResultsError, fn -> Agents.get_agent!(scope, agent.id) end
    end

    test "change_agent/2 returns a agent changeset" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["agents_management"]})
      school = Repo.get!(School, scope.school_id)
      agent = insert(:agent, %{school: school})

      assert %Ecto.Changeset{} = Agents.change_agent(scope, agent)
    end
  end

  describe "permission checks" do
    alias Lanttern.Agents.Agent
    alias Lanttern.IdentityFixtures
    alias Lanttern.Schools.School

    test "create_agent/2 fails when user lacks agents_management permission" do
      scope = IdentityFixtures.scope_fixture(%{permissions: []})

      valid_attrs = %{name: "Test Agent"}

      assert_raise MatchError, fn ->
        Agents.create_agent(scope, valid_attrs)
      end
    end

    test "update_agent/3 fails when user lacks agents_management permission" do
      scope = IdentityFixtures.scope_fixture(%{permissions: []})
      school = Repo.get!(School, scope.school_id)
      agent = insert(:agent, %{school: school})

      assert_raise MatchError, fn ->
        Agents.update_agent(scope, agent, %{name: "Updated"})
      end
    end

    test "delete_agent/2 fails when user lacks agents_management permission" do
      scope = IdentityFixtures.scope_fixture(%{permissions: []})
      school = Repo.get!(School, scope.school_id)
      agent = insert(:agent, %{school: school})

      assert_raise MatchError, fn ->
        Agents.delete_agent(scope, agent)
      end
    end

    test "change_agent/2 fails when user lacks agents_management permission" do
      scope = IdentityFixtures.scope_fixture(%{permissions: []})
      school = Repo.get!(School, scope.school_id)
      agent = insert(:agent, %{school: school})

      assert_raise MatchError, fn ->
        Agents.change_agent(scope, agent)
      end
    end
  end

  describe "school isolation" do
    alias Lanttern.Agents.Agent
    alias Lanttern.IdentityFixtures

    test "get_agent!/2 fails when agent belongs to different school" do
      scope = IdentityFixtures.scope_fixture()
      other_school = insert(:school)
      agent = insert(:agent, school: other_school)

      assert_raise Ecto.NoResultsError, fn ->
        Agents.get_agent!(scope, agent.id)
      end
    end

    test "update_agent/3 fails when agent belongs to different school" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["agents_management"]})
      other_school = insert(:school)
      agent = insert(:agent, school: other_school)

      assert_raise MatchError, fn ->
        Agents.update_agent(scope, agent, %{name: "Updated"})
      end
    end

    test "delete_agent/2 fails when agent belongs to different school" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["agents_management"]})
      other_school = insert(:school)
      agent = insert(:agent, school: other_school)

      assert_raise MatchError, fn ->
        Agents.delete_agent(scope, agent)
      end
    end

    test "change_agent/2 fails when agent belongs to different school" do
      scope = IdentityFixtures.scope_fixture(%{permissions: ["agents_management"]})
      other_school = insert(:school)
      agent = insert(:agent, school: other_school)

      assert_raise MatchError, fn ->
        Agents.change_agent(scope, agent)
      end
    end
  end
end
