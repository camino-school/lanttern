defmodule LantternWeb.ILP.ILPTemplateFormComponent do
  @moduledoc """
  Renders an `ILPTemplate` form.

  Handles ILP sections and components.

  ### Attrs

      attr :template, ILPTemplate, required: true, doc: "requires sections, components, and AI layer preload"
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
        <%!--
          limit sections and components management to existing templates
          because we need the template id to cast assoc components (composite fk)
        --%>
        <div :if={@template.id} class="py-6 border-y border-ltrn-light mb-6">
          <p class="font-bold"><%= gettext("Sections and components") %></p>
          <.inputs_for :let={section_f} field={@form[:sections]}>
            <.card_base class="p-4 border border-ltrn-lightest mt-4">
              <input type="hidden" name="ilp_template[sections_sort][]" value={section_f.index} />

              <div class="flex items-center gap-4">
                <.input type="text" field={section_f[:name]} class="flex-1" phx-debounce="1500" />
                <.action
                  type="button"
                  name="ilp_template[sections_drop][]"
                  value={section_f.index}
                  phx-click={JS.dispatch("change")}
                >
                  <.icon name="hero-trash-mini" />
                </.action>
              </div>
              <.inputs_for :let={component_f} field={section_f[:components]}>
                <input
                  type="hidden"
                  name={"#{section_f.name}[components_sort][]"}
                  value={component_f.index}
                />
                <div class="flex items-center gap-4 p-4 rounded-sm mt-4 bg-ltrn-lightest">
                  <.input type="text" field={component_f[:name]} class="flex-1" phx-debounce="1500" />
                  <.action
                    type="button"
                    theme="subtle"
                    name={"#{section_f.name}[components_drop][]"}
                    value={component_f.index}
                    phx-click={JS.dispatch("change")}
                  >
                    <.icon name="hero-x-circle-mini" />
                  </.action>
                </div>
              </.inputs_for>
              <input type="hidden" name={"#{section_f.name}[components_drop][]"} />
              <div class="flex justify-center p-4 rounded-sm mt-4 bg-ltrn-lightest">
                <.action
                  type="button"
                  icon_name="hero-plus-circle-mini"
                  name={"#{section_f.name}[components_sort][]"}
                  value="new_component"
                  phx-click={JS.dispatch("change")}
                >
                  <%= gettext("Add component") %>
                </.action>
              </div>
            </.card_base>
          </.inputs_for>
          <input type="hidden" name="ilp_template[sections_drop][]" />
          <.card_base class="flex justify-center gap-4 p-4 mt-4">
            <.action
              type="button"
              icon_name="hero-plus-circle-mini"
              name="ilp_template[sections_sort][]"
              value="new_section"
              phx-click={JS.dispatch("change")}
            >
              <%= gettext("Add section") %>
            </.action>
          </.card_base>
        </div>
        <.input
          field={@form[:description]}
          type="markdown"
          label={gettext("About this template")}
          phx-debounce="1500"
          class="mb-6"
          show_optional
        />
        <div class="mb-6 p-4 rounded-sm bg-ltrn-staff-lightest">
          <.input
            field={@form[:teacher_description]}
            type="markdown"
            label={gettext("Template instructions (visible to staff only)")}
            phx-debounce="1500"
            show_optional
          />
        </div>
        <.ai_box class="mb-6">
          <p class="mb-6">
            <%= gettext("Add instructions on how Lanttern should revise this ILP.") %>
          </p>
          <.inputs_for :let={ai_layer_f} field={@form[:ai_layer]}>
            <.input
              field={ai_layer_f[:revision_instructions]}
              type="markdown"
              label={gettext("AI revision instructions")}
              phx-debounce="1500"
              class="mb-6"
              show_optional
            />
            <.input
              field={ai_layer_f[:model]}
              type="select"
              label="AI model"
              options={@ai_model_options}
              prompt="Select an AI model"
              class="mb-6"
            />
            <.input
              field={ai_layer_f[:cooldown_minutes]}
              type="number"
              label="AI request cooldown (minutes)"
            />
          </.inputs_for>
        </.ai_box>
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
    |> assign_ai_model_options()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_form(socket) do
    template = socket.assigns.template
    changeset = ILP.change_ilp_template(template)

    socket
    |> assign(:form, to_form(changeset))
  end

  defp assign_ai_model_options(socket) do
    ai_model_options =
      Map.get(socket.assigns.template.ai_layer || %{}, :model)
      |> LantternWeb.AIHelpers.generate_ai_model_options()

    socket
    |> assign(:ai_model_options, ai_model_options)
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
      Map.update(
        template_params,
        "sections",
        %{},
        &put_template_id_in_sections_components(&1, template_id)
      )

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

  defp put_template_id_in_sections_components(sections, template_id) do
    Enum.map(sections, fn {s_index, section} ->
      updated_section =
        Map.update(section, "components", %{}, &put_template_id_in_components(&1, template_id))

      {s_index, updated_section}
    end)
    |> Enum.into(%{})
  end

  defp put_template_id_in_components(components, template_id) do
    components
    |> Enum.map(fn {c_index, component} ->
      {c_index, Map.put(component, "template_id", template_id)}
    end)
    |> Enum.into(%{})
  end
end
