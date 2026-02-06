defmodule LantternWeb.LessonTagsLive.LessonTagCardComponent do
  use LantternWeb, :live_component

  alias Lanttern.Lessons

  def render(assigns) do
    ~H"""
    <div id={@id} class="mt-4 first:mt-0">
      <.card_base class="flex items-stretch overflow-hidden">
        <div class="flex-1">
          <%!-- Clickable header with drag handle --%>
          <div class="w-full flex items-center gap-4 p-6 text-left">
            <.drag_handle class="sortable-handle" />
            <button
              type="button"
              phx-click="toggle"
              phx-target={@myself}
              class="flex-1 font-bold text-left hover:text-ltrn-subtle truncate"
            >
              {@lesson_tag.name}
            </button>
            <.action
              :if={@is_expanded}
              type="button"
              phx-click="edit_lesson_tag"
              phx-target={@myself}
              icon_name="hero-pencil-mini"
              theme="subtle"
            >
              {gettext("Edit")}
            </.action>
            <.icon_button
              name={if @is_expanded, do: "hero-chevron-up", else: "hero-chevron-down"}
              sr_text={gettext("Toggle lesson tag card")}
              theme="ghost"
              phx-click="toggle"
              phx-target={@myself}
            />
          </div>

          <%!-- Accordion content (only when expanded) --%>
          <%= if @is_expanded do %>
            <div class="border-t border-ltrn-lighter">
              <div class="p-6">
                <%!-- Agent description field --%>
                <div>
                  <h4 class="font-display font-bold text-lg mb-2">
                    {gettext("Agent description")}
                  </h4>
                  <%= if @is_editing_agent_description do %>
                    <.form
                      for={@agent_description_form}
                      phx-submit="save_agent_description"
                      phx-change="validate_agent_description"
                      phx-target={@myself}
                    >
                      <.input
                        type="markdown"
                        field={@agent_description_form[:agent_description]}
                        phx-debounce="1000"
                      />
                      <div class="flex gap-2 mt-4">
                        <.button
                          type="button"
                          theme="ghost"
                          phx-click="cancel_edit_agent_description"
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
                    <%= if @lesson_tag.agent_description do %>
                      <button
                        type="button"
                        class="w-full text-left group"
                        phx-click="edit_agent_description"
                        phx-target={@myself}
                      >
                        <.markdown
                          text={@lesson_tag.agent_description}
                          class="rounded-sm group-hover:bg-ltrn-lightest transition-colors"
                        />
                      </button>
                    <% else %>
                      <.button
                        type="button"
                        icon_name="hero-plus-mini"
                        size="sm"
                        phx-click="edit_agent_description"
                        phx-target={@myself}
                      >
                        {gettext("Add")}
                      </.button>
                    <% end %>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
        </div>
        <div class="w-2" style={"background: #{@lesson_tag.bg_color}"} />
      </.card_base>
    </div>
    """
  end

  # lifecycle

  def mount(socket) do
    {:ok, assign(socket, :is_editing_agent_description, false)}
  end

  # subsequent updates, received via send_update for accordion toggle
  def update(assigns, %{assigns: %{lesson_tag: lesson_tag}} = socket) do
    # Determine if this component should be expanded
    is_expanded = assigns.selected_lesson_tag_id == "#{lesson_tag.id}"

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
      |> assign_agent_description_form()

    {:ok, socket}
  end

  defp maybe_reset_editing_states(socket) do
    if socket.assigns.is_expanded do
      socket
    else
      assign(socket, :is_editing_agent_description, false)
    end
  end

  defp assign_agent_description_form(socket) do
    changeset =
      Lessons.change_tag(
        socket.assigns.current_scope,
        socket.assigns.lesson_tag
      )

    assign(socket, :agent_description_form, to_form(changeset))
  end

  # event handlers

  def handle_event("toggle", _params, socket) do
    path =
      if socket.assigns.is_expanded,
        do: ~p"/settings/lesson_tags",
        else: ~p"/settings/lesson_tags/#{socket.assigns.lesson_tag.id}"

    {:noreply, push_patch(socket, to: path)}
  end

  def handle_event("edit_lesson_tag", _params, socket) do
    send(self(), {__MODULE__, {:edit_lesson_tag, socket.assigns.lesson_tag.id}})
    {:noreply, socket}
  end

  def handle_event("edit_agent_description", _, socket),
    do: {:noreply, assign(socket, :is_editing_agent_description, true)}

  def handle_event("cancel_edit_agent_description", _, socket),
    do: {:noreply, assign(socket, :is_editing_agent_description, false)}

  def handle_event("validate_agent_description", %{"tag" => params}, socket) do
    field_params = Map.take(params, ["agent_description"])

    changeset =
      Lessons.change_tag(
        socket.assigns.current_scope,
        socket.assigns.lesson_tag,
        field_params
      )
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :agent_description_form, to_form(changeset))}
  end

  def handle_event("save_agent_description", %{"tag" => params}, socket) do
    field_params = Map.take(params, ["agent_description"])

    case Lessons.update_tag(
           socket.assigns.current_scope,
           socket.assigns.lesson_tag,
           field_params
         ) do
      {:ok, updated_lesson_tag} ->
        socket
        |> assign(:lesson_tag, updated_lesson_tag)
        |> assign(:is_editing_agent_description, false)
        |> assign_agent_description_form()
        |> then(&{:noreply, &1})

      {:error, changeset} ->
        {:noreply, assign(socket, :agent_description_form, to_form(changeset))}
    end
  end
end
