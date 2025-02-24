defmodule LantternWeb.ILP.ILPTemplateFormComponent do
  @moduledoc """
  Renders an `ILPTemplate` form.

  Handles ILP sections and components.

  ### Attrs

      attr :template, ILPTemplate, required: true, doc: "requires sections and components preload"
      attr :class, :any, default: nil
      attr :notify_parent, :boolean
      attr :notify_component, Phoenix.LiveComponent.CID

  """

  use LantternWeb, :live_component

  alias Lanttern.ILP

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form id={@id} for={@form} phx-change="validate" phx-submit="save" phx-target={@myself}>
        <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
          <%= gettext("Oops, something went wrong! Please check the errors below.") %>
        </.error_block>
        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Template name")}
          class="mb-6"
          phx-debounce="1500"
        />
        <.input
          field={@form[:description]}
          type="textarea"
          label={gettext("About this template (visible to staff only)")}
          phx-debounce="1500"
          class="mb-1"
          show_optional
        />
        <.markdown_supported class="mb-6" />
        <%!--
          limit sections and components management to existing templates
          because we need the template id to cast assoc components (composite fk)
        --%>
        <div :if={@template.id} class="mb-6">
          <.inputs_for :let={section_f} field={@form[:sections]}>
            <input type="hidden" name="ilp_template[sections_sort][]" value={section_f.index} />
            <div class="mb-6">
              <div class="flex gap-2">
                <.input
                  type="text"
                  field={section_f[:name]}
                  label={gettext("Section")}
                  class="flex-1"
                  phx-debounce="1500"
                />
                <button
                  type="button"
                  name="ilp_template[sections_drop][]"
                  value={section_f.index}
                  phx-click={JS.dispatch("change")}
                >
                  drop
                </button>
              </div>
              <.inputs_for :let={component_f} field={section_f[:components]}>
                <input
                  type="hidden"
                  name={"#{section_f.name}[components_sort][]"}
                  value={component_f.index}
                />
                <div class="flex gap-2">
                  <.input
                    type="text"
                    field={component_f[:name]}
                    label={gettext("Component")}
                    class="flex-1"
                    phx-debounce="1500"
                  />
                  <button
                    type="button"
                    name={"#{section_f.name}[components_drop][]"}
                    value={component_f.index}
                    phx-click={JS.dispatch("change")}
                  >
                    drop
                  </button>
                </div>
              </.inputs_for>
              <input type="hidden" name={"#{section_f.name}[components_drop][]"} />

              <.action
                type="button"
                name={"#{section_f.name}[components_sort][]"}
                value="new_component"
                phx-click={JS.dispatch("change")}
              >
                <%= gettext("Add component") %>
              </.action>
            </div>
          </.inputs_for>
          <input type="hidden" name="ilp_template[sections_drop][]" />

          <.action
            type="button"
            name="ilp_template[sections_sort][]"
            value="new_section"
            phx-click={JS.dispatch("change")}
          >
            <%= gettext("Add section") %>
          </.action>
          <%!-- <.action type="button" phx-click={JS.push("new_section", target: @myself)}>
            <%= gettext("Add section") %>
          </.action> --%>
        </div>
        <div class="flex items-center justify-between gap-4">
          <div>
            <.action
              :if={@template.id}
              type="button"
              size="md"
              theme="subtle"
              phx-click={JS.push("delete", target: @myself)}
              data-confirm={gettext("Are you sure?")}
            >
              <%= gettext("Delete template") %>
            </.action>
          </div>
          <div class="flex items-center gap-4">
            <.action type="button" size="md" phx-click={JS.push("cancel", target: @myself)}>
              <%= gettext("Cancel") %>
            </.action>
            <.action type="submit" theme="primary" size="md" icon_name="hero-check">
              <%= gettext("Save") %>
            </.action>
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
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_form()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_form(socket) do
    template = socket.assigns.template
    changeset = ILP.change_ilp_template(template)

    socket
    |> assign(:form, to_form(changeset))
  end

  # event handlers

  @impl true
  def handle_event("cancel", _, socket) do
    notify(__MODULE__, :cancel, socket.assigns)
    {:noreply, socket}
  end

  def handle_event("delete", _, socket) do
    ILP.delete_ilp_template(socket.assigns.template)
    |> case do
      {:ok, template} ->
        notify(__MODULE__, {:deleted, template}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  def handle_event("validate", %{"ilp_template" => template_params}, socket),
    do: {:noreply, assign_validated_form(socket, template_params)}

  def handle_event("save", %{"ilp_template" => template_params}, socket) do
    # template_params = inject_extra_params(socket, template_params)
    save_template(socket, socket.assigns.template.id, template_params)
  end

  defp assign_validated_form(socket, params) do
    changeset =
      socket.assigns.template
      |> ILP.change_ilp_template(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  # # inject params handled in backend
  # defp inject_extra_params(socket, params) do
  #   params
  #   |> Map.put("school_id", socket.assigns.status.school_id)
  # end

  defp save_template(socket, nil, template_params) do
    # inject school_id from template assign when creating new
    template_params = Map.put(template_params, "school_id", socket.assigns.template.school_id)

    ILP.create_ilp_template(template_params)
    |> case do
      {:ok, template} ->
        notify(__MODULE__, {:created, template}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_template(socket, _id, template_params) do
    template_id = socket.assigns.template.id

    # inject template_id in components
    template_params =
      Map.update(template_params, "sections", %{}, fn sections ->
        Enum.map(sections, fn {s_index, section} ->
          updated_section =
            Map.update(section, "components", %{}, fn components ->
              components
              |> Enum.map(fn {c_index, component} ->
                {c_index, Map.put(component, "template_id", template_id)}
              end)
              |> Enum.into(%{})
            end)

          {s_index, updated_section}
        end)
        |> Enum.into(%{})
      end)
      |> IO.inspect(label: "updated")

    ILP.update_ilp_template(
      socket.assigns.template,
      template_params
    )
    |> case do
      {:ok, template} ->
        notify(__MODULE__, {:updated, template}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
