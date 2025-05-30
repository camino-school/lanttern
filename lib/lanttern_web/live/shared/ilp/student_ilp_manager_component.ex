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

  ### Optional attrs

  - `:class` - any, additional classes for the component
  - `:student_navigate` - function, passed to `StudentHeaderComponent` navigate

  """

  use LantternWeb, :live_component

  import LantternWeb.DateTimeHelpers

  alias Lanttern.Identity
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
        current_profile={@current_profile}
        tz={@tz}
      />
      <br /><br />
      <div :if={@student_ilp} id="all_comments">
        <h5 class="flex items-center gap-2 text-ltrn-subtle">
          <div class="w-10 text-center">
            <.icon name="hero-chat-bubble-left-right" class="w-6 h-6" />
          </div>
          <span class="font-display font-black text-xl"><%= gettext("ILP comments") %></span>
        </h5>

        <.empty_state_simple :if={Enum.empty?(@ilp_comments)} class="mt-6">
          <%= gettext("No comments in this ILP yet") %>
        </.empty_state_simple>

        <%!-- I hard coded profile name and picture_url --%>
        <div
          :for={ilp_comment <- @ilp_comments}
          class={[
            "flex items-start gap-2 w-full mt-6",
            if(ilp_comment.owner_id == @current_profile.id, do: "flex-row-reverse")
          ]}
          id={"ilp-comment-#{ilp_comment.id}"}
        >
          <.profile_picture
            picture_url={ilp_comment.owner.profile_picture_url}
            profile_name={ilp_comment.owner.name}
          />
          <.card_base class="flex-1 max-w-3/4 p-2">
            <div class="flex items-center justify-between gap-4">
              <div class="flex items-center gap-4">
                <div class="flex-1 font-bold text-xs text-ltrn-staff-dark">
                  <%= Identity.get_profile_name(ilp_comment.owner_id) %>
                </div>
                <.badge theme="staff"><%= gettext("Staff") %></.badge>
              </div>
              <.action
                :if={ilp_comment.owner_id == @current_profile.id}
                type="link"
                icon_name="hero-pencil-mini"
                patch={"?comment_id=#{ilp_comment.id}"}
                theme="subtle"
                id={"edit-comment-#{ilp_comment.id}"}
              >
                <%= gettext("Edit") %>
              </.action>
            </div>
            <div class="flex items-end justify-between gap-2 mt-4 font-bold text-ltrn-staff-dark">
              <%= ilp_comment.name %>
            </div>
            <div class="flex items-end justify-between gap-2 mt-4">
              <.markdown text={ilp_comment.content} class="flex-1" />
              <div class="text-ltrn-subtle text-xs">
                <%= format_by_locale(ilp_comment.inserted_at, @tz) %>
              </div>
            </div>
            <div
              :if={!Enum.empty?(ilp_comment.attachments)}
              class="p-2 rounded-sm mt-4 bg-ltrn-lightest"
            >
              <h6 class="flex items-center gap-2 font-bold text-ltrn-subtle">
                <.icon name="hero-paper-clip-mini" />
                <%= gettext("Attachments") %>
              </h6>
              <%!-- Maybe render with AttachmentsComponents later--%>
              <div :for={ilp_attachment <- ilp_comment.attachments}>
                <.card_base class="p-4 mt-2">
                  <%= if(ilp_attachment.is_external) do %>
                    <.badge><%= gettext("External link") %></.badge>
                  <% else %>
                    <.badge theme="cyan"><%= gettext("Upload") %></.badge>
                  <% end %>
                  <a
                    href={ilp_attachment.link}
                    target="_blank"
                    class="block mt-2 text-sm underline hover:text-ltrn-subtle"
                  >
                    <%= ilp_attachment.name %>
                  </a>
                </.card_base>
              </div>
            </div>
          </.card_base>
        </div>
        <div class="flex flex-row-reverse items-center gap-2 w-full mt-6">
          <.profile_picture
            picture_url={@current_profile.profile_picture_url}
            profile_name={@current_profile.name}
          />
          <.card_base class="flex-1 flex max-w-3/4 p-4">
            <.action
              type="link"
              patch="?comment=new"
              icon_name="hero-plus-circle-mini"
              theme="primary"
            >
              <%= gettext("Add ILP comment") %>
            </.action>
          </.card_base>
        </div>
      </div>

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
