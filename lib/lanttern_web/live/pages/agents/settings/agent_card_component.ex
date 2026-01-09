defmodule LantternWeb.AgentsSettingsLive.AgentCardComponent do
  use LantternWeb, :live_component

  alias Lanttern.Agents

  def render(assigns) do
    ~H"""
    <div id={@id} class="mt-4 first:mt-0">
      <.card_base>
        <%!-- Clickable header --%>
        <div class="w-full flex items-center gap-4 p-6 text-left">
          <button
            type="button"
            phx-click="toggle"
            phx-target={@myself}
            class="flex-1 font-semibold text-left hover:text-ltrn-subtle"
          >
            {@agent.name}
          </button>
          <.action
            :if={@is_expanded}
            type="button"
            phx-click="edit_agent"
            phx-target={@myself}
            icon_name="hero-pencil-mini"
            theme="subtle"
          >
            {gettext("Edit")}
          </.action>
          <.icon_button
            name={if @is_expanded, do: "hero-chevron-up", else: "hero-chevron-down"}
            sr_text={gettext("Toggle agent card")}
            theme="ghost"
            phx-click="toggle"
            phx-target={@myself}
          />
        </div>

        <%!-- Accordion content (only when expanded) --%>
        <%= if @is_expanded do %>
          <div class="border-t border-ltrn-lighter">
            <div class="p-6 space-y-8">
              <%!-- Personality field --%>
              <.field_section
                field={:personality}
                label="Personality"
                agent={@agent}
                is_editing={@is_editing_personality}
                form={@personality_form}
                myself={@myself}
              />

              <%!-- Knowledge field --%>
              <.field_section
                field={:knowledge}
                label="Knowledge"
                agent={@agent}
                is_editing={@is_editing_knowledge}
                form={@knowledge_form}
                myself={@myself}
              />

              <%!-- Instructions field --%>
              <.field_section
                field={:instructions}
                label="Instructions"
                agent={@agent}
                is_editing={@is_editing_instructions}
                form={@instructions_form}
                myself={@myself}
              />

              <%!-- Guardrails field --%>
              <.field_section
                field={:guardrails}
                label="Guardrails"
                agent={@agent}
                is_editing={@is_editing_guardrails}
                form={@guardrails_form}
                myself={@myself}
              />
            </div>
          </div>
        <% end %>
      </.card_base>
    </div>
    """
  end

  # function component for field section
  attr :field, :atom, required: true
  attr :label, :string, required: true
  attr :agent, :map, required: true
  attr :is_editing, :boolean, required: true
  attr :form, :map, required: true
  attr :myself, :any, required: true

  defp field_section(assigns) do
    ~H"""
    <div>
      <h4 class="font-display font-bold text-lg mb-2">{@label}</h4>
      <%= if @is_editing do %>
        <.form
          for={@form}
          phx-submit={"save_#{@field}"}
          phx-change={"validate_#{@field}"}
          phx-target={@myself}
        >
          <.input
            type="markdown"
            field={@form[@field]}
            phx-debounce="1000"
          />
          <div class="flex gap-2 mt-4">
            <.button
              type="button"
              theme="ghost"
              phx-click={"cancel_edit_#{@field}"}
              phx-target={@myself}
            >
              {gettext("Cancel")}
            </.button>
            <.button type="submit">
              {gettext("Save")}
            </.button>
          </div>
        </.form>
      <% else %>
        <%= if Map.get(@agent, @field) do %>
          <button
            type="button"
            class="w-full text-left group"
            phx-click={"edit_#{@field}"}
            phx-target={@myself}
          >
            <.markdown
              text={Map.get(@agent, @field)}
              class="rounded-sm group-hover:bg-ltrn-lightest transition-colors"
            />
          </button>
        <% else %>
          <.button
            type="button"
            icon_name="hero-plus-mini"
            size="sm"
            phx-click={"edit_#{@field}"}
            phx-target={@myself}
          >
            {"Add #{String.downcase(@label)}"}
          </.button>
        <% end %>
      <% end %>
    </div>
    """
  end

  # lifecycle

  def mount(socket) do
    socket =
      socket
      |> assign(:is_editing_personality, false)
      |> assign(:is_editing_knowledge, false)
      |> assign(:is_editing_instructions, false)
      |> assign(:is_editing_guardrails, false)

    {:ok, socket}
  end

  # subsequent updates, received via send_update for accordion toggle
  def update(assigns, %{assigns: %{agent: agent}} = socket) do
    # Determine if this component should be expanded
    is_expanded = assigns.selected_agent_id == "#{agent.id}"

    socket =
      socket
      |> assign(:is_expanded, is_expanded)
      # Reset editing states when component collapses
      |> maybe_reset_editing_states()

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:is_expanded, false)
      |> assign_field_forms()

    {:ok, socket}
  end

  defp maybe_reset_editing_states(socket) do
    if socket.assigns.is_expanded do
      socket
    else
      socket
      |> assign(:is_editing_personality, false)
      |> assign(:is_editing_knowledge, false)
      |> assign(:is_editing_instructions, false)
      |> assign(:is_editing_guardrails, false)
    end
  end

  defp assign_field_forms(socket) do
    changeset = Agents.change_agent(socket.assigns.current_scope, socket.assigns.agent)

    socket
    |> assign(:personality_form, to_form(changeset))
    |> assign(:knowledge_form, to_form(changeset))
    |> assign(:instructions_form, to_form(changeset))
    |> assign(:guardrails_form, to_form(changeset))
  end

  # event handlers

  def handle_event("toggle", _params, socket) do
    path =
      if socket.assigns.is_expanded,
        do: ~p"/settings/agents",
        else: ~p"/settings/agents/#{socket.assigns.agent.id}"

    {:noreply, push_patch(socket, to: path)}
  end

  def handle_event("edit_agent", _params, socket) do
    send(self(), {__MODULE__, {:edit_agent, socket.assigns.agent.id}})
    {:noreply, socket}
  end

  # Edit handlers
  def handle_event("edit_personality", _, socket),
    do: {:noreply, assign(socket, :is_editing_personality, true)}

  def handle_event("edit_knowledge", _, socket),
    do: {:noreply, assign(socket, :is_editing_knowledge, true)}

  def handle_event("edit_instructions", _, socket),
    do: {:noreply, assign(socket, :is_editing_instructions, true)}

  def handle_event("edit_guardrails", _, socket),
    do: {:noreply, assign(socket, :is_editing_guardrails, true)}

  # Cancel handlers
  def handle_event("cancel_edit_personality", _, socket),
    do: {:noreply, assign(socket, :is_editing_personality, false)}

  def handle_event("cancel_edit_knowledge", _, socket),
    do: {:noreply, assign(socket, :is_editing_knowledge, false)}

  def handle_event("cancel_edit_instructions", _, socket),
    do: {:noreply, assign(socket, :is_editing_instructions, false)}

  def handle_event("cancel_edit_guardrails", _, socket),
    do: {:noreply, assign(socket, :is_editing_guardrails, false)}

  # Validate handlers
  def handle_event("validate_personality", %{"agent" => params}, socket),
    do: validate_field(socket, :personality, params)

  def handle_event("validate_knowledge", %{"agent" => params}, socket),
    do: validate_field(socket, :knowledge, params)

  def handle_event("validate_instructions", %{"agent" => params}, socket),
    do: validate_field(socket, :instructions, params)

  def handle_event("validate_guardrails", %{"agent" => params}, socket),
    do: validate_field(socket, :guardrails, params)

  # Save handlers
  def handle_event("save_personality", %{"agent" => params}, socket),
    do: save_agent_field(socket, :personality, params)

  def handle_event("save_knowledge", %{"agent" => params}, socket),
    do: save_agent_field(socket, :knowledge, params)

  def handle_event("save_instructions", %{"agent" => params}, socket),
    do: save_agent_field(socket, :instructions, params)

  def handle_event("save_guardrails", %{"agent" => params}, socket),
    do: save_agent_field(socket, :guardrails, params)

  # helpers

  defp validate_field(socket, field, params) do
    field_params = Map.take(params, [Atom.to_string(field)])

    changeset =
      Agents.change_agent(
        socket.assigns.current_scope,
        socket.assigns.agent,
        field_params
      )
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :"#{field}_form", to_form(changeset))}
  end

  defp save_agent_field(socket, field, params) do
    field_params = Map.take(params, [Atom.to_string(field)])

    case Agents.update_agent(socket.assigns.current_scope, socket.assigns.agent, field_params) do
      {:ok, updated_agent} ->
        socket
        |> assign(:agent, updated_agent)
        |> assign(:"is_editing_#{field}", false)
        |> assign_field_forms()
        |> then(&{:noreply, &1})

      {:error, changeset} ->
        {:noreply, assign(socket, :"#{field}_form", to_form(changeset))}
    end
  end
end
