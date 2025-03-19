defmodule LantternWeb.ILP.StudentILPFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `StudentILP` form

  ### Attrs

      attr :student_ilp, StudentILP, required: true, doc: "expects entries preloads"
      attr :template, ILPTemplate, required: true, doc: "expects sections/components preloads"
      attr :title, :string, required: true
      attr :current_profile, Profile, required: true
      attr :on_cancel, :any, required: true, doc: "`<.slide_over>` `on_cancel` attr"
      attr :notify_parent, :boolean
      attr :notify_component, Phoenix.LiveComponent.CID

  """

  use LantternWeb, :live_component

  alias Lanttern.ILP
  alias Lanttern.ILP.ILPEntry
  alias Lanttern.ILP.StudentILP

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over id={@id} show={true} on_cancel={@on_cancel}>
        <:title><%= @title %></:title>
        <.form
          id="student-ilp-form"
          for={@form}
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
        >
          <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
            <%= gettext("Oops, something went wrong! Please check the errors below.") %>
          </.error_block>
          <div class="mb-6">
            <.inputs_for :let={template_f} field={@form[:template]}>
              <.inputs_for :let={section_f} field={template_f[:sections]}>
                <.card_base
                  class="p-4 border border-ltrn-lightest mt-4"
                  id={"#{@id}-section-#{section_f.data.id}"}
                >
                  <div class="font-display font-black text-base">
                    <%= section_f.data.name %>
                  </div>
                  <.inputs_for :let={component_f} field={section_f[:components]}>
                    <div
                      class="p-4 rounded mt-2 bg-ltrn-lightest"
                      id={"#{@id}-component-#{component_f.data.id}"}
                    >
                      <div class="mb-2 font-bold"><%= component_f.data.name %></div>
                      <.inputs_for :let={entry_f} field={component_f[:entry]}>
                        <.input type="textarea" field={entry_f[:description]} phx-debounce="1500" />
                      </.inputs_for>
                    </div>
                  </.inputs_for>
                </.card_base>
              </.inputs_for>
            </.inputs_for>
          </div>
          <.input
            field={@form[:notes]}
            type="textarea"
            label={gettext("Notes (shared with students/guardians)")}
            class="mb-1"
            phx-debounce="1500"
            show_optional
          />
          <.markdown_supported class="mb-6" />
          <div class="mb-6 p-4 rounded bg-ltrn-staff-lightest">
            <.input
              field={@form[:teacher_notes]}
              type="textarea"
              label={gettext("Teacher notes (internal, not shared)")}
              class="mb-1"
              phx-debounce="1500"
              show_optional
            />
            <.markdown_supported />
          </div>
          <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
            <%= gettext("Oops, something went wrong! Please check the errors above.") %>
          </.error_block>
        </.form>
        <:actions_left :if={@student_ilp.id}>
          <.action
            type="button"
            theme="subtle"
            size="md"
            phx-click="delete"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
          >
            <%= gettext("Delete") %>
          </.action>
        </:actions_left>
        <:actions>
          <.action
            type="button"
            theme="subtle"
            size="md"
            phx-click={JS.exec("data-cancel", to: "##{@id}")}
          >
            <%= gettext("Cancel") %>
          </.action>
          <.action
            type="submit"
            theme="primary"
            size="md"
            icon_name="hero-check"
            form="student-ilp-form"
          >
            <%= gettext("Save") %>
          </.action>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket = assign(socket, :initialized, false)
    {:ok, socket}
  end

  @impl true
  def update(%{student_ilp: %StudentILP{}} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> adjust_student_ilp_and_assign_form()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp adjust_student_ilp_and_assign_form(socket) do
    # format ilp entries, including empty entries for missing components
    components =
      Enum.flat_map(socket.assigns.template.sections, & &1.components)

    component_entries_map =
      Enum.map(components, fn component ->
        case Enum.find(socket.assigns.student_ilp.entries, &(&1.component_id == component.id)) do
          nil ->
            %ILPEntry{
              component_id: component.id,
              template_id: socket.assigns.student_ilp.template_id,
              student_ilp_id: socket.assigns.student_ilp.id
            }

          entry ->
            entry
        end
      end)
      |> Enum.map(&{&1.component_id, &1})
      |> Enum.into(%{})

    # inject entries into template
    template =
      %{
        socket.assigns.template
        | sections:
            Enum.map(socket.assigns.template.sections, fn section ->
              %{
                section
                | components:
                    Enum.map(section.components, fn component ->
                      Map.put(component, :entry, component_entries_map[component.id])
                    end)
              }
            end)
      }

    student_ilp = %{socket.assigns.student_ilp | template: template}

    changeset = ILP.change_student_ilp(student_ilp)

    socket
    |> assign(:student_ilp, student_ilp)
    |> assign(:form, to_form(changeset))
  end

  # event handlers

  @impl true
  def handle_event("validate", %{"student_ilp" => ilp_params}, socket),
    do: {:noreply, assign_validated_form(socket, ilp_params)}

  def handle_event("save", %{"student_ilp" => ilp_params}, socket) do
    ilp_params =
      inject_extra_params(socket, ilp_params)

    save_ilp(socket, socket.assigns.student_ilp.id, ilp_params)
  end

  def handle_event("delete", _, socket) do
    ILP.delete_student_ilp(socket.assigns.student_ilp,
      log_profile_id: socket.assigns.current_profile.id
    )
    |> case do
      {:ok, ilp} ->
        notify(__MODULE__, {:deleted, ilp}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp assign_validated_form(socket, params) do
    params = inject_extra_params(socket, params)

    changeset =
      socket.assigns.student_ilp
      |> ILP.change_student_ilp(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  # inject params handled in backend when creating new ILP
  defp inject_extra_params(%{assigns: %{student_ilp: %{id: nil}}} = socket, params) do
    params
    |> Map.put("school_id", socket.assigns.student_ilp.school_id)
    |> Map.put("template_id", socket.assigns.student_ilp.template_id)
    |> Map.put("cycle_id", socket.assigns.student_ilp.cycle_id)
    |> Map.put("student_id", socket.assigns.student_ilp.student_id)
  end

  defp inject_extra_params(_socket, params), do: params

  defp save_ilp(socket, nil, ilp_params) do
    ilp_params = prepare_save_params(socket, ilp_params)

    ILP.create_student_ilp(ilp_params,
      log_profile_id: socket.assigns.current_profile.id
    )
    |> case do
      {:ok, ilp} ->
        notify(__MODULE__, {:created, ilp}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_ilp(socket, _id, ilp_params) do
    ilp_params = prepare_save_params(socket, ilp_params)

    ILP.update_student_ilp(
      socket.assigns.student_ilp,
      ilp_params,
      log_profile_id: socket.assigns.current_profile.id
    )
    |> case do
      {:ok, message} ->
        notify(__MODULE__, {:updated, message}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  # when saving, we need to format the params to match the schema
  #
  # while validating we use a chain of cast assocs from student ILP
  # to entries (ilp > template > section > component > entry), but
  # to save we can format and just cast_assoc entries on student ILP
  defp prepare_save_params(socket, params) do
    entries =
      params["template"]["sections"]
      |> Enum.flat_map(fn {_index, %{"components" => components} = _section} ->
        components
        |> Enum.map(fn {_index, %{"id" => component_id, "entry" => entry} = _component} ->
          entry
          |> Map.put("component_id", component_id)
          |> Map.put("template_id", socket.assigns.template.id)
        end)
      end)

    params
    |> Map.drop(["template"])
    |> Map.put("entries", entries)
  end
end
