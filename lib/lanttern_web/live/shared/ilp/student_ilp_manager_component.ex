defmodule LantternWeb.ILP.StudentILPManagerComponent do
  @moduledoc """
  Renders a `StudentILP`.

  Parent view/component controls if ILP is being created or edited,
  and this component handles the form setup.

  ### Required attrs

  - `:cycle` - `Cycle`
  - `:base_path` - used on create, overlays cancel (edit/AI), and edit navigate
  - `:current_profile` - `Profile`, from `current_user.current_profile`
  - `:student` - `Student`
  - `:template` - `ILPTemplate`
  - `:params` - parent view params. Use `"student_ilp=new"` to create, or `"student_ilp=edit"` to edit
  - `:tz` - from `current_user.tz`
  - `:current_user` - `%User{}` in `socket.assigns.current_user`

  ### Optional attrs

  - `:class` - any, additional classes for the component
  - `:student_navigate` - function, passed to `StudentHeaderComponent` navigate

  """

  use LantternWeb, :live_component

  alias Lanttern.ILP
  alias Lanttern.ILP.ILPTemplate
  alias Lanttern.ILP.StudentILP
  alias Lanttern.Schools.Student

  # shared components
  alias LantternWeb.ILP.ILPCommentFormOverlayComponent
  alias LantternWeb.ILP.StudentILPAIRevisionActionBarComponent
  alias LantternWeb.ILP.StudentILPAIRevisionOverlayComponent
  alias LantternWeb.ILP.StudentILPComponent
  alias LantternWeb.ILP.StudentILPFormOverlayComponent
  alias LantternWeb.Schools.StudentHeaderComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.card_base :if={!@student} class="p-10 mb-10">
        <.empty_state><%= gettext("No student selected") %></.empty_state>
      </.card_base>
      <.live_component
        :if={@student}
        module={StudentHeaderComponent}
        id="ilp-student-header"
        cycle_id={@cycle.id}
        student_id={@student.id}
        class="mb-10"
        navigate={@student_navigate}
        show_tags
      />
      <.card_base :if={!@template} class="p-10">
        <.empty_state><%= gettext("No ILP template selected") %></.empty_state>
      </.card_base>
      <.card_base :if={@student && @template && !@student_ilp} class="p-10">
        <.empty_state><%= gettext("No student ILP created yet") %></.empty_state>
        <div class="flex justify-center mt-10">
          <.action
            type="link"
            icon_name="hero-plus-circle-mini"
            theme="primary"
            size="md"
            patch="?student_ilp=new"
          >
            <%= gettext("Create %{student}'s %{cycle} ILP",
              student: @student.name,
              cycle: @cycle.name
            ) %>
          </.action>
        </div>
      </.card_base>
      <.live_component
        module={StudentILPAIRevisionActionBarComponent}
        id={"student-ilp-ai-revision-action-bar-#{@id}"}
        class="mb-4"
        student_ilp={@student_ilp}
        ilp_template={@template}
        view_patch="?ai_revision=show"
        current_profile={@current_profile}
        notify_component={@myself}
      />
      <.live_component
        :if={@student_ilp}
        module={StudentILPComponent}
        id={"student-ilp-#{@id}"}
        template={@template}
        student={@student}
        student_ilp={@student_ilp}
        show_actions
        edit_patch="?student_ilp=edit"
        is_ilp_manager={@is_ilp_manager}
        show_teacher_notes
        params={@params}
        current_user={@current_user}
      />

      <.live_component
        :if={@ilp_comment}
        module={ILPCommentFormOverlayComponent}
        id={"#{@id}-comment-slide-over"}
        title={@ilp_comment_title}
        ilp_comment={@ilp_comment}
        form_action={@ilp_comment_action}
        student_ilp={@student_ilp}
        current_profile={@current_profile}
        on_cancel={JS.patch(@base_path)}
        notify_component={@myself}
      />
      <.live_component
        :if={@edit_student_ilp}
        module={StudentILPFormOverlayComponent}
        id={"student-ilp-form-overlay-#{@id}"}
        student_ilp={@edit_student_ilp}
        template={@template}
        title={@ilp_form_overlay_title}
        current_profile={@current_profile}
        on_cancel={JS.patch(@base_path)}
        notify_component={@myself}
      />
      <.live_component
        :if={@ai_panel_open}
        module={StudentILPAIRevisionOverlayComponent}
        id={"student-ilp-ai-revision-overlay-#{@id}"}
        student_ilp={@student_ilp}
        ilp_template={@template}
        current_profile={@current_profile}
        tz={@tz}
        on_cancel={JS.patch(@base_path)}
      />
    </div>
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
      |> assign(:ilp_comments, [])
      |> assign(:ilp_comment, nil)
      |> assign(:ilp_comment_title, nil)
      |> assign(:ilp_comment_action, nil)
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
      push_navigate: [to: socket.assigns.base_path]
    ]

    {:ok, delegate_navigation(socket, nav_opts)}
  end

  def update(%{action: {ILPCommentFormOverlayComponent, {action, _message}}}, socket)
      when action in [:created, :updated] do
    flash_message =
      case action do
        :created -> {:info, gettext("Comment created successfully")}
        :updated -> {:info, gettext("Comment updated successfully")}
      end

    nav_opts = [
      put_flash: flash_message,
      push_navigate: [to: socket.assigns.base_path]
    ]

    {:ok, delegate_navigation(socket, nav_opts)}
  end

  def update(%{action: {StudentILPAIRevisionActionBarComponent, {_action, _msg}}}, socket) do
    nav_opts = [push_navigate: [to: "#{socket.assigns.base_path}?ai_revision=show"]]

    {:ok, delegate_navigation(socket, nav_opts)}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_edit_student_ilp()
      |> assign_ilp_comment()
      |> assign_ai_panel_open()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> ensure_template_ai_layer_is_loaded()
    |> assign_student_ilp()
    |> assign_ilp_comments()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp ensure_template_ai_layer_is_loaded(
         %{assigns: %{template: %ILPTemplate{ai_layer: %Ecto.Association.NotLoaded{}}}} = socket
       ) do
    template =
      socket.assigns.template
      |> Lanttern.Repo.preload(:ai_layer)

    assign(socket, :template, template)
  end

  defp ensure_template_ai_layer_is_loaded(socket), do: socket

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
          preloads: [:cycle, :entries]
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

  defp assign_ilp_comment(%{assigns: %{params: %{"comment" => "new"}}} = socket) do
    socket
    |> assign(:ilp_comment, %ILP.ILPComment{})
    |> assign(:ilp_comment_title, gettext("New Comment"))
    |> assign(:ilp_comment_action, :new)
  end

  defp assign_ilp_comment(%{assigns: %{params: %{"comment_id" => id}}} = socket) do
    socket
    |> assign(:ilp_comment, ILP.get_ilp_comment(id))
    |> assign(:ilp_comment_title, gettext("Edit Comment"))
    |> assign(:ilp_comment_action, :edit)
  end

  defp assign_ilp_comment(socket), do: assign(socket, :ilp_comment, nil)

  defp assign_ilp_comments(%{assigns: %{student_ilp: %StudentILP{id: id}}} = socket) do
    socket
    |> assign(:ilp_comments, ILP.list_ilp_comments_by_student_ilp(id))
  end

  defp assign_ilp_comments(socket), do: socket

  defp assign_edit_student_ilp(%{assigns: %{params: %{"student_ilp" => "new"}}} = socket) do
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
         %{assigns: %{params: %{"student_ilp" => "edit"}, student_ilp: %StudentILP{}}} = socket
       ) do
    socket
    |> assign(:edit_student_ilp, socket.assigns.student_ilp)
    |> assign(:ilp_form_overlay_title, gettext("Edit ILP"))
  end

  defp assign_edit_student_ilp(socket),
    do: assign(socket, :edit_student_ilp, nil)

  defp assign_ai_panel_open(%{assigns: %{params: %{"ai_revision" => "show"}}} = socket),
    do: assign(socket, :ai_panel_open, true)

  defp assign_ai_panel_open(socket), do: assign(socket, :ai_panel_open, false)
end
