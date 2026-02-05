defmodule LantternWeb.SchoolAiConfigLive do
  use LantternWeb, :live_view

  alias Lanttern.SchoolConfig
  alias Lanttern.SchoolConfig.AiConfig

  # function component for field section
  attr :field, :atom, required: true
  attr :field_name, :string, required: true
  attr :field_description, :string, required: true
  attr :ai_config, :map, required: true
  attr :is_editing, :boolean, required: true
  attr :form, :map, required: true
  attr :input_type, :string, default: "markdown"

  defp field_section(assigns) do
    ~H"""
    <div>
      <h6 class="font-display font-bold text-lg mb-2">{@field_name}</h6>
      <p class="mb-4">{@field_description}</p>
      <%= if @is_editing do %>
        <.form
          for={@form}
          phx-submit={"save_#{@field}"}
          phx-change={"validate_#{@field}"}
        >
          <.input
            type={@input_type}
            field={@form[@field]}
            phx-debounce="1000"
          />
          <div class="flex gap-2 mt-4">
            <.button
              type="button"
              theme="ghost"
              phx-click={"cancel_edit_#{@field}"}
            >
              {gettext("Cancel")}
            </.button>
            <.button type="submit">
              {gettext("Save")}
            </.button>
          </div>
        </.form>
      <% else %>
        <%= if Map.get(@ai_config, @field) do %>
          <button
            type="button"
            class="w-full text-left group"
            phx-click={"edit_#{@field}"}
          >
            <%= if @input_type == "markdown" do %>
              <.markdown
                text={Map.get(@ai_config, @field)}
                class="rounded-sm group-hover:bg-ltrn-lightest transition-colors"
              />
            <% else %>
              <div class="p-2 rounded-sm group-hover:bg-ltrn-lightest transition-colors">
                {Map.get(@ai_config, @field)}
              </div>
            <% end %>
          </button>
        <% else %>
          <.button
            type="button"
            icon_name="hero-plus-mini"
            size="sm"
            phx-click={"edit_#{@field}"}
          >
            {gettext("Add")}
          </.button>
        <% end %>
      <% end %>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> check_if_user_has_access()
      |> assign(:page_title, gettext("School AI Configuration"))
      |> load_ai_config()
      |> assign_editing_states()
      |> assign_field_forms()

    {:ok, socket}
  end

  defp check_if_user_has_access(socket) do
    has_access =
      "agents_management" in socket.assigns.current_user.current_profile.permissions

    if has_access do
      socket
    else
      socket
      |> push_navigate(to: ~p"/dashboard", replace: true)
      |> put_flash(:error, gettext("You don't have access to school AI configuration"))
    end
  end

  defp load_ai_config(socket) do
    ai_config =
      SchoolConfig.get_ai_config(socket.assigns.current_scope) ||
        %AiConfig{school_id: socket.assigns.current_scope.school_id}

    assign(socket, :ai_config, ai_config)
  end

  defp assign_editing_states(socket) do
    socket
    |> assign(:is_editing_base_model, false)
    |> assign(:is_editing_knowledge, false)
    |> assign(:is_editing_guardrails, false)
  end

  defp assign_field_forms(socket) do
    changeset =
      SchoolConfig.change_ai_config(socket.assigns.current_scope, socket.assigns.ai_config)

    socket
    |> assign(:base_model_form, to_form(changeset))
    |> assign(:knowledge_form, to_form(changeset))
    |> assign(:guardrails_form, to_form(changeset))
  end

  # event handlers

  # Edit handlers
  @impl true
  def handle_event("edit_base_model", _, socket),
    do: {:noreply, assign(socket, :is_editing_base_model, true)}

  def handle_event("edit_knowledge", _, socket),
    do: {:noreply, assign(socket, :is_editing_knowledge, true)}

  def handle_event("edit_guardrails", _, socket),
    do: {:noreply, assign(socket, :is_editing_guardrails, true)}

  # Cancel handlers
  def handle_event("cancel_edit_base_model", _, socket),
    do: {:noreply, assign(socket, :is_editing_base_model, false)}

  def handle_event("cancel_edit_knowledge", _, socket),
    do: {:noreply, assign(socket, :is_editing_knowledge, false)}

  def handle_event("cancel_edit_guardrails", _, socket),
    do: {:noreply, assign(socket, :is_editing_guardrails, false)}

  # Validate handlers
  def handle_event("validate_base_model", %{"ai_config" => params}, socket),
    do: validate_field(socket, :base_model, params)

  def handle_event("validate_knowledge", %{"ai_config" => params}, socket),
    do: validate_field(socket, :knowledge, params)

  def handle_event("validate_guardrails", %{"ai_config" => params}, socket),
    do: validate_field(socket, :guardrails, params)

  # Save handlers
  def handle_event("save_base_model", %{"ai_config" => params}, socket),
    do: save_ai_config_field(socket, :base_model, params)

  def handle_event("save_knowledge", %{"ai_config" => params}, socket),
    do: save_ai_config_field(socket, :knowledge, params)

  def handle_event("save_guardrails", %{"ai_config" => params}, socket),
    do: save_ai_config_field(socket, :guardrails, params)

  # helpers

  defp validate_field(socket, field, params) do
    field_params = Map.take(params, [Atom.to_string(field)])

    changeset =
      SchoolConfig.change_ai_config(
        socket.assigns.current_scope,
        socket.assigns.ai_config,
        field_params
      )
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :"#{field}_form", to_form(changeset))}
  end

  defp save_ai_config_field(socket, field, params) do
    field_params = Map.take(params, [Atom.to_string(field)])

    case save_ai_config(socket.assigns.current_scope, socket.assigns.ai_config, field_params) do
      {:ok, updated_ai_config} ->
        socket =
          socket
          |> assign(:ai_config, updated_ai_config)
          |> assign(:"is_editing_#{field}", false)
          |> assign_field_forms()
          |> put_flash(:info, gettext("School AI config updated"))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :"#{field}_form", to_form(changeset))}
    end
  end

  defp save_ai_config(scope, %AiConfig{id: nil}, params) do
    SchoolConfig.create_ai_config(scope, params)
  end

  defp save_ai_config(scope, ai_config, params) do
    SchoolConfig.update_ai_config(scope, ai_config, params)
  end
end
