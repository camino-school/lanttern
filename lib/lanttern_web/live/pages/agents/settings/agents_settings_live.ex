defmodule LantternWeb.AgentsSettingsLive do
  use LantternWeb, :live_view

  alias Lanttern.Agents
  alias Lanttern.Agents.Agent

  # page components
  alias __MODULE__.AgentCardComponent

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> check_if_user_has_access()
      |> assign(:page_title, gettext("AI Agents"))
      |> assign(:agent, nil)
      |> assign(:selected_agent_id, nil)
      |> stream_agents()

    {:ok, socket}
  end

  defp check_if_user_has_access(socket) do
    has_access =
      "school_management" in socket.assigns.current_user.current_profile.permissions

    if has_access do
      socket
    else
      socket
      |> push_navigate(to: ~p"/dashboard", replace: true)
      |> put_flash(:error, gettext("You don't have access to agents settings page"))
    end
  end

  defp stream_agents(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id
    agents = Agents.list_ai_agents(school_id: school_id)

    socket
    |> stream(:agents, agents)
    |> assign(:has_agents, length(agents) > 0)
    |> assign(:agents_ids, Enum.map(agents, &"#{&1.id}"))
  end

  @impl true
  def handle_params(params, _uri, socket),
    do: {:noreply, update_selected_agent_components(socket, params)}

  defp update_selected_agent_components(socket, params) do
    prev_id = socket.assigns.selected_agent_id

    selected_agent_id =
      case params do
        %{"id" => id} -> if id in socket.assigns.agents_ids, do: id, else: nil
        _ -> nil
      end

    # Re-stream only the agents that need to toggle (previous and current selection)
    ids_to_update = [prev_id, selected_agent_id] |> Enum.reject(&is_nil/1) |> Enum.uniq()

    Enum.each(ids_to_update, fn id ->
      send_update(AgentCardComponent, id: "agents-#{id}", selected_agent_id: selected_agent_id)
    end)

    assign(socket, :selected_agent_id, selected_agent_id)
  end

  # event handlers

  @impl true
  def handle_event("new_agent", _params, socket) do
    agent = %Agent{
      school_id: socket.assigns.current_user.current_profile.school_id
    }

    socket =
      socket
      |> assign(:agent, agent)
      |> assign(:agent_overlay_title, gettext("New AI agent"))

    {:noreply, socket}
  end

  def handle_event("close_agent_form", _params, socket),
    do: {:noreply, assign(socket, :agent, nil)}

  # info handlers

  @impl true
  def handle_info({AgentCardComponent, {:edit_agent, agent_id}}, socket) do
    {:noreply, open_agent_form(socket, agent_id)}
  end

  defp open_agent_form(socket, agent_id) do
    if "#{agent_id}" in socket.assigns.agents_ids do
      agent = Agents.get_agent!(agent_id)

      socket
      |> assign(:agent, agent)
      |> assign(:agent_overlay_title, gettext("Edit AI agent"))
    else
      socket
    end
  end
end
