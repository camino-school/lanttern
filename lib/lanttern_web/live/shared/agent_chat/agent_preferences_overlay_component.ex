defmodule LantternWeb.AgentChat.AgentPreferencesOverlayComponent do
  @moduledoc """
  A live component that renders the current staff member's AI conversation
  preferences in a modal overlay, allowing them to view and edit the preferences.

  ## Required attributes

  - `id` - Component identifier
  - `current_scope` - The current user scope (must have a `staff_member_id`)
  - `on_cancel` - JS command to execute when the modal is dismissed
  """

  use LantternWeb, :live_component

  alias Lanttern.Schools

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.modal id={@id} show={true} on_cancel={@on_cancel}>
        <h1 class="font-display font-black text-2xl">{gettext("AI Conversation Preferences")}</h1>
        <p class="mt-2 text-ltrn-subtle">
          {gettext("Describe how you'd like the AI to interact with you.")}
        </p>
        <section id="agent-preferences-content" class="mt-6">
          <.markdown
            :if={!@preferences_form && @staff_member.agent_conversation_preferences}
            text={@staff_member.agent_conversation_preferences}
            class="mb-4"
          />
          <div :if={!@preferences_form} class="flex gap-4">
            <.button
              :if={!@staff_member.agent_conversation_preferences}
              phx-click="edit_preferences"
              phx-target={@myself}
              theme="primary"
              icon_name="hero-plus-mini"
            >
              {gettext("Add preferences")}
            </.button>
            <.button
              :if={@staff_member.agent_conversation_preferences}
              phx-click="edit_preferences"
              phx-target={@myself}
              size="sm"
            >
              {gettext("Edit preferences")}
            </.button>
          </div>
          <.form
            :if={@preferences_form}
            for={@preferences_form}
            phx-submit="save_preferences"
            phx-change="validate_preferences"
            phx-target={@myself}
            id="agent-preferences-form"
          >
            <.input
              field={@preferences_form[:agent_conversation_preferences]}
              type="markdown"
              label={gettext("AI Conversation Preferences")}
              label_is_sr_only
              phx-debounce="500"
            />
            <div class="flex justify-end gap-2 mt-2">
              <.button
                type="button"
                theme="ghost"
                phx-click="cancel_preferences_edit"
                phx-target={@myself}
              >
                {gettext("Cancel")}
              </.button>
              <.button type="submit">{gettext("Save")}</.button>
            </div>
          </.form>
        </section>
      </.modal>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :preferences_form, nil)}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_staff_member()

    {:ok, socket}
  end

  defp assign_staff_member(%{assigns: %{current_scope: scope}} = socket) do
    staff_member = Schools.get_staff_member!(scope.staff_member_id)
    assign(socket, :staff_member, staff_member)
  end

  # event handlers

  @impl true
  def handle_event("edit_preferences", _params, socket) do
    form =
      socket.assigns.staff_member
      |> Schools.change_staff_member()
      |> to_form()

    {:noreply, assign(socket, :preferences_form, form)}
  end

  def handle_event("cancel_preferences_edit", _params, socket),
    do: {:noreply, assign(socket, :preferences_form, nil)}

  def handle_event("validate_preferences", %{"staff_member" => params}, socket) do
    form =
      socket.assigns.staff_member
      |> Schools.change_staff_member(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :preferences_form, form)}
  end

  def handle_event("save_preferences", %{"staff_member" => params}, socket) do
    case Schools.update_staff_member(socket.assigns.staff_member, params) do
      {:ok, staff_member} ->
        socket =
          socket
          |> assign(:staff_member, staff_member)
          |> assign(:preferences_form, nil)

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :preferences_form, to_form(changeset))}
    end
  end
end
