defmodule LantternWeb.LessonTemplatesLive.LessonTemplateCardComponent do
  use LantternWeb, :live_component

  alias Lanttern.LessonTemplates

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
            {@lesson_template.name}
          </button>
          <.action
            :if={@is_expanded}
            type="button"
            phx-click="edit_lesson_template"
            phx-target={@myself}
            icon_name="hero-pencil-mini"
            theme="subtle"
          >
            {gettext("Edit")}
          </.action>
          <.icon_button
            name={if @is_expanded, do: "hero-chevron-up", else: "hero-chevron-down"}
            sr_text={gettext("Toggle lesson template card")}
            theme="ghost"
            phx-click="toggle"
            phx-target={@myself}
          />
        </div>

        <%!-- Accordion content (only when expanded) --%>
        <%= if @is_expanded do %>
          <div class="border-t border-ltrn-lighter">
            <div class="p-6 space-y-8">
              <%!-- About field --%>
              <.field_section
                field={:about}
                field_name={gettext("About")}
                lesson_template={@lesson_template}
                is_editing={@is_editing_about}
                form={@about_form}
                myself={@myself}
              />

              <%!-- Template field --%>
              <.field_section
                field={:template}
                field_name={gettext("Template")}
                lesson_template={@lesson_template}
                is_editing={@is_editing_template}
                form={@template_form}
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
  attr :field_name, :string, required: true
  attr :lesson_template, :map, required: true
  attr :is_editing, :boolean, required: true
  attr :form, :map, required: true
  attr :myself, :any, required: true

  defp field_section(assigns) do
    ~H"""
    <div>
      <h4 class="font-display font-bold text-lg mb-2">{@field_name}</h4>
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
        <%= if Map.get(@lesson_template, @field) do %>
          <button
            type="button"
            class="w-full text-left group"
            phx-click={"edit_#{@field}"}
            phx-target={@myself}
          >
            <.markdown
              text={Map.get(@lesson_template, @field)}
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
            {gettext("Add")}
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
      |> assign(:is_editing_about, false)
      |> assign(:is_editing_template, false)

    {:ok, socket}
  end

  # subsequent updates, received via send_update for accordion toggle
  def update(assigns, %{assigns: %{lesson_template: lesson_template}} = socket) do
    # Determine if this component should be expanded
    is_expanded = assigns.selected_lesson_template_id == "#{lesson_template.id}"

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
      |> assign(:is_editing_about, false)
      |> assign(:is_editing_template, false)
    end
  end

  defp assign_field_forms(socket) do
    changeset =
      LessonTemplates.change_lesson_template(
        socket.assigns.current_scope,
        socket.assigns.lesson_template
      )

    socket
    |> assign(:about_form, to_form(changeset))
    |> assign(:template_form, to_form(changeset))
  end

  # event handlers

  def handle_event("toggle", _params, socket) do
    path =
      if socket.assigns.is_expanded,
        do: ~p"/settings/lesson_templates",
        else: ~p"/settings/lesson_templates/#{socket.assigns.lesson_template.id}"

    {:noreply, push_patch(socket, to: path)}
  end

  def handle_event("edit_lesson_template", _params, socket) do
    send(self(), {__MODULE__, {:edit_lesson_template, socket.assigns.lesson_template.id}})
    {:noreply, socket}
  end

  # Edit handlers
  def handle_event("edit_about", _, socket),
    do: {:noreply, assign(socket, :is_editing_about, true)}

  def handle_event("edit_template", _, socket),
    do: {:noreply, assign(socket, :is_editing_template, true)}

  # Cancel handlers
  def handle_event("cancel_edit_about", _, socket),
    do: {:noreply, assign(socket, :is_editing_about, false)}

  def handle_event("cancel_edit_template", _, socket),
    do: {:noreply, assign(socket, :is_editing_template, false)}

  # Validate handlers
  def handle_event("validate_about", %{"lesson_template" => params}, socket),
    do: validate_field(socket, :about, params)

  def handle_event("validate_template", %{"lesson_template" => params}, socket),
    do: validate_field(socket, :template, params)

  # Save handlers
  def handle_event("save_about", %{"lesson_template" => params}, socket),
    do: save_lesson_template_field(socket, :about, params)

  def handle_event("save_template", %{"lesson_template" => params}, socket),
    do: save_lesson_template_field(socket, :template, params)

  # helpers

  defp validate_field(socket, field, params) do
    field_params = Map.take(params, [Atom.to_string(field)])

    changeset =
      LessonTemplates.change_lesson_template(
        socket.assigns.current_scope,
        socket.assigns.lesson_template,
        field_params
      )
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :"#{field}_form", to_form(changeset))}
  end

  defp save_lesson_template_field(socket, field, params) do
    field_params = Map.take(params, [Atom.to_string(field)])

    case LessonTemplates.update_lesson_template(
           socket.assigns.current_scope,
           socket.assigns.lesson_template,
           field_params
         ) do
      {:ok, updated_lesson_template} ->
        socket
        |> assign(:lesson_template, updated_lesson_template)
        |> assign(:"is_editing_#{field}", false)
        |> assign_field_forms()
        |> then(&{:noreply, &1})

      {:error, changeset} ->
        {:noreply, assign(socket, :"#{field}_form", to_form(changeset))}
    end
  end
end
