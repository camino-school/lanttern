defmodule LantternWeb.Agents.AgentFormComponent do
  @moduledoc """
  Renders a `Agent` form
  """

  use LantternWeb, :live_component

  alias Lanttern.Agents

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form for={@form} id={@id} phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Agent name")}
          class="mb-6"
          phx-debounce="1500"
        />
        <.error_block
          :if={@has_delete_error}
          on_dismiss={JS.push("dismiss_delete_error", target: @myself)}
        >
          <p>{gettext("Something went wrong when trying to delete the agent")}</p>
        </.error_block>
        <div class="flex justify-between gap-2 mt-10">
          <div>
            <.button
              :if={@agent.id}
              type="button"
              theme="ghost"
              phx-click="delete"
              phx-target={@myself}
              data-confirm={gettext("Are you sure?")}
            >
              {gettext("Delete")}
            </.button>
          </div>
          <div class="flex gap-2">
            <.button
              type="button"
              theme="ghost"
              phx-click={@on_cancel}
            >
              {gettext("Cancel")}
            </.button>
            <.button type="submit">
              {gettext("Save")}
            </.button>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:has_delete_error, false)

    {:ok, socket}
  end

  @impl true
  def update(%{agent: agent} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_form(Agents.change_agent(assigns.current_scope, agent))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"agent" => agent_params}, socket) do
    changeset =
      Agents.change_agent(
        socket.assigns.current_scope,
        socket.assigns.agent,
        agent_params
      )
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("delete", _params, socket) do
    socket =
      case Agents.delete_agent(socket.assigns.current_scope, socket.assigns.agent) do
        {:ok, agent} ->
          message = {:deleted, agent}

          notify(__MODULE__, message, socket.assigns)

          socket
          |> put_flash(:info, gettext("Agent deleted"))
          |> handle_navigation(message)

        {:error, _changeset} ->
          assign(socket, :has_delete_error, true)
      end

    {:noreply, socket}
  end

  def handle_event("dismiss_delete_error", _params, socket),
    do: {:noreply, assign(socket, :has_delete_error, false)}

  def handle_event("save", %{"agent" => agent_params}, socket) do
    save_agent(socket, socket.assigns.agent.id, agent_params)
  end

  defp save_agent(socket, nil, agent_params) do
    case Agents.create_agent(socket.assigns.current_scope, agent_params) do
      {:ok, agent} ->
        message = {:created, agent}

        notify(__MODULE__, message, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Agent created"))
          |> handle_navigation(message)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_agent(socket, _id, agent_params) do
    case Agents.update_agent(socket.assigns.current_scope, socket.assigns.agent, agent_params) do
      {:ok, agent} ->
        message = {:updated, agent}

        notify(__MODULE__, message, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Agent updated"))
          |> handle_navigation(message)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  # helpers

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
