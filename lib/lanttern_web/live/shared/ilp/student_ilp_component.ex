defmodule LantternWeb.ILP.StudentILPComponent do
  @moduledoc """
  Renders a `StudentILP`.

  Parent view/component controls if ILP is being created or edited,
  and this component handles the form setup.

  ### Required attrs

  - `:cycle` - `Cycle`
  - `:on_edit_patch` - function, receive `student_ilp_id` as arg. Passed to edit action `patch` attr
  - `:create_patch` - passed to create action `patch` attr
  - `:on_edit_cancel` - passed to edit ILP form overlay `on_cancel` attr
  - `:edit_navigate` - navigate when ILP is edited, created, or deleted
  - `:current_profile` - `Profile`, from `current_user.current_profile`
  - `:params` - parent view params. Use `"edit_student_ilp=new"` to create, or `"edit_student_ilp=id"` to edit

  ### Optional attrs

  - `:student` - `Student`
  - `:template` - `ILPTemplate`
  - `:class` - any, additional classes for the component
  - `:student_navigate` - function, passed to `StudentHeaderComponent` navigate

  """

  use LantternWeb, :live_component

  alias Lanttern.ILP
  alias Lanttern.ILP.ILPEntry
  alias Lanttern.ILP.ILPTemplate
  alias Lanttern.ILP.StudentILP
  alias Lanttern.Schools.Student

  # shared components
  alias LantternWeb.ILP.StudentILPFormOverlayComponent
  alias LantternWeb.Schools.StudentHeaderComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <%= if !@template do %>
        <.card_base class="p-10">
          <.empty_state><%= gettext("No ILP template selected") %></.empty_state>
        </.card_base>
      <% else %>
        <.card_base :if={!@student} class="p-10">
          <.empty_state><%= gettext("No student selected") %></.empty_state>
        </.card_base>
        <.live_component
          :if={@student}
          module={StudentHeaderComponent}
          id={"#{@id}-student-header"}
          cycle_id={@cycle.id}
          student_id={@student.id}
          class="mb-10"
          navigate={@student_navigate}
        />
        <.card_base :if={@student_ilp && @student_ilp.id} class="p-6 mt-10">
          <div class="flex items-center gap-4">
            <h4 class="flex-1 font-display font-black text-xl"><%= @template.name %></h4>
            <.action type="link" icon_name="hero-pencil-mini" patch={@on_edit_patch.(@student_ilp.id)}>
              <%= gettext("Edit") %>
            </.action>
          </div>
          <div>
            <.card_base
              :for={section <- @template.sections}
              class="p-4 border border-ltrn-lightest mt-4"
            >
              <div class="font-display font-black text-base">
                <%= section.name %>
              </div>
              <div :for={component <- section.components} class="p-4 rounded mt-2 bg-ltrn-lightest">
                <div class="font-bold"><%= component.name %></div>
                <.ilp_entry entry={@component_entry_map[component.id]} class="mt-4" />
              </div>
            </.card_base>
          </div>
          <div :if={@student_ilp.notes} class="p-4 rounded mt-6 bg-ltrn-mesh-cyan">
            <p class="flex items-center gap-2 font-bold mb-4">
              <.icon name="hero-pencil-square-mini" class="text-ltrn-primary" />
              <%= gettext("Notes") %>
            </p>
            <.markdown text={@student_ilp.notes} />
          </div>
          <div :if={@student_ilp.teacher_notes} class="p-4 rounded mt-6 bg-ltrn-staff-lightest">
            <p class="flex items-center gap-2 font-bold mb-4">
              <.icon name="hero-pencil-square-mini" class="text-ltrn-staff-accent" />
              <span class="text-ltrn-staff-dark"><%= gettext("Teacher notes (internal)") %></span>
            </p>
            <.markdown text={@student_ilp.teacher_notes} />
          </div>
        </.card_base>
        <.card_base
          :if={@student && (!@student_ilp || (@student_ilp && is_nil(@student_ilp.id)))}
          class="p-10 mt-10"
        >
          <.empty_state><%= gettext("No student ILP created yet") %></.empty_state>
          <div class="flex justify-center mt-10">
            <.action
              type="link"
              icon_name="hero-plus-circle-mini"
              theme="primary"
              size="md"
              patch={@create_patch}
            >
              <%= gettext("Create %{student}'s %{cycle} ILP",
                student: @student.name,
                cycle: @cycle.name
              ) %>
            </.action>
          </div>
        </.card_base>
      <% end %>
      <.live_component
        :if={@edit_student_ilp}
        module={StudentILPFormOverlayComponent}
        id={"#{@id}-student-ilp-form-overlay"}
        ilp={@edit_student_ilp}
        template={@template}
        title={@ilp_form_overlay_title}
        current_profile={@current_profile}
        on_cancel={@on_edit_cancel}
        notify_component={@myself}
      />
    </div>
    """
  end

  # function components

  attr :entry, ILPEntry
  attr :class, :any, default: nil

  defp ilp_entry(%{entry: nil} = assigns) do
    ~H"""
    <.empty_state_simple class={@class}>
      <%= gettext("Nothing yet") %>
    </.empty_state_simple>
    """
  end

  defp ilp_entry(%{entry: %{description: nil}} = assigns) do
    ~H"""
    <.empty_state_simple class={@class}>
      <%= gettext("Nothing yet") %>
    </.empty_state_simple>
    """
  end

  defp ilp_entry(assigns) do
    ~H"""
    <.markdown text={@entry.description} class={["max-w-none", @class]} />
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:student, nil)
      |> assign(:student_navigate, nil)
      |> assign(:template, nil)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(%{action: {StudentILPFormOverlayComponent, {action, _message}}}, socket)
      when action in [:created, :updated, :deleted] do
    flash_message =
      case action do
        :created -> {:info, gettext("ILP created successfully")}
        :updated -> {:info, gettext("ILP updated successfully")}
        :deleted -> {:info, gettext("ILP deleted successfully")}
      end

    nav_opts = [
      put_flash: flash_message,
      push_navigate: [to: socket.assigns.edit_navigate]
    ]

    {:ok, delegate_navigation(socket, nav_opts)}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_edit_student_ilp()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_student_ilp()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_student_ilp(socket) do
    with %Student{} = student <- socket.assigns.student,
         %ILPTemplate{} = template <- socket.assigns.template do
      student_ilp =
        ILP.get_student_ilp_by(
          [
            student_id: student.id,
            template_id: template.id,
            cycle_id: socket.assigns.cycle.id
          ],
          preloads: :entries
        )

      component_entry_map =
        if student_ilp do
          socket.assigns.template.sections
          |> Enum.flat_map(& &1.components)
          |> Enum.map(fn component ->
            {
              component.id,
              Enum.find(student_ilp.entries, &(&1.component_id == component.id))
            }
          end)
          |> Enum.filter(fn {_component_id, entry} -> entry end)
          |> Enum.into(%{})
        end

      socket
      |> assign(:student_ilp, student_ilp)
      |> assign(:component_entry_map, component_entry_map)
    else
      _ -> assign(socket, :student_ilp, nil)
    end
  end

  defp assign_edit_student_ilp(%{assigns: %{params: %{"edit_student_ilp" => "new"}}} = socket) do
    with nil <- socket.assigns.student_ilp,
         %Student{} = student <- socket.assigns.student,
         %ILPTemplate{} = template <- socket.assigns.template do
      student_ilp =
        %StudentILP{
          school_id: student.school_id,
          student_id: student.id,
          template_id: template.id,
          cycle_id: socket.assigns.cycle.id,
          entries: []
        }

      socket
      |> assign(:edit_student_ilp, student_ilp)
      |> assign(:ilp_form_overlay_title, gettext("Create ILP"))
    else
      _ -> assign(socket, :edit_student_ilp, nil)
    end
  end

  defp assign_edit_student_ilp(
         %{assigns: %{params: %{"edit_student_ilp" => id}, student_ilp: %StudentILP{}}} = socket
       )
       when id != "new" do
    socket
    |> assign(:edit_student_ilp, socket.assigns.student_ilp)
    |> assign(:ilp_form_overlay_title, gettext("Edit ILP"))
  end

  defp assign_edit_student_ilp(socket),
    do: assign(socket, :edit_student_ilp, nil)
end
