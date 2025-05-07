defmodule LantternWeb.ILP.StudentILPManagerComponent do
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
  - `:student` - `Student`
  - `:template` - `ILPTemplate`
  - `:params` - parent view params. Use `"student_ilp=new"` to create, or `"student_ilp=edit"` to edit

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
  alias LantternWeb.ILP.StudentILPComponent
  alias LantternWeb.ILP.StudentILPFormOverlayComponent
  alias LantternWeb.Schools.StudentHeaderComponent
  import LantternWeb.DateTimeHelpers

  @age_range 0..100

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
            patch={@create_patch}
          >
            <%= gettext("Create %{student}'s %{cycle} ILP",
              student: @student.name,
              cycle: @cycle.name
            ) %>
          </.action>
        </div>
      </.card_base>
      <.live_component
        :if={@student_ilp}
        module={StudentILPComponent}
        id="student-ilp"
        template={@template}
        student={@student}
        student_ilp={@student_ilp}
        show_actions
        edit_patch={@on_edit_patch.(@student_ilp.id)}
        is_ilp_manager={@is_ilp_manager}
        show_teacher_notes
        current_profile={@current_profile}
      />
      <.ai_box :if={@ai_form || @has_ai_revision} class="mt-6 mb-6">
        <div :if={@has_ai_revision} class="py-6 border-y border-ltrn-ai-lighter">
          <h5 class="font-display font-black text-lg">
            <%= gettext("Lanttern AI revision") %>
          </h5>
          <p class="mt-1 mb-6 text-xs">
            <%= gettext("Generated in %{datetime}",
              datetime:
                format_local!(@student_ilp.ai_revision_datetime, "{Mshort} {0D}, {YYYY} {h24}:{m}")
            ) %>
          </p>
          <.markdown text={@student_ilp.ai_revision} />
          <.ai_generated_content_disclaimer class="mt-4" />
        </div>
        <%= if @is_on_ai_cooldown do %>
          <.card_base class="p-2 mt-4">
            <p class="flex items-center gap-2 text-ltrn-ai-dark">
              <.icon name="hero-clock-micro" class="w-4 h-4" />
              <%= gettext("AI revision can be requested every %{minute} minutes",
                minute: @ai_cooldown_minutes
              ) %>
              <%= ngettext(
                "(1 minute left until next revision request)",
                "(%{count} minutes left until next revision request)",
                @ai_cooldown_minutes_left
              ) %>
            </p>
          </.card_base>
        <% else %>
          <form
            :if={@ai_form}
            phx-submit="request_ai_review"
            phx-target={@myself}
            class={if @has_ai_revision, do: "mt-6"}
          >
            <p class="mb-4">
              <%= if @has_ai_revision,
                do:
                  gettext(
                    "Inform the approximated age of the student (in years), and ask for an updated Lanttern AI revision."
                  ),
                else:
                  gettext(
                    "Inform the approximated age of the student (in years), and ask for Lanttern AI revision."
                  ) %>
            </p>
            <div class="flex items-center gap-4">
              <div class="w-40">
                <.base_input
                  name={@ai_form[:age].name}
                  type="number"
                  placeholder={gettext("Student age")}
                  value={@ai_form[:age].value}
                />
              </div>
              <.action type="submit" icon_name="hero-sparkles-mini" theme="ai">
                <%= if @has_ai_revision,
                  do: gettext("Request AI review update"),
                  else: gettext("Request AI review") %>
              </.action>
            </div>
            <p :if={@ai_form_error} class="flex items-center gap-2 mt-2 text-xs">
              <.icon name="hero-exclamation-circle-micro" class="w-4 h-4" />
              <%= @ai_form_error %>
            </p>
            <p :if={@ai_response_error} class="flex items-center gap-2 mt-2 text-xs">
              <.icon name="hero-exclamation-circle-micro" class="w-4 h-4" />
              <%= @ai_response_error %>
            </p>
          </form>
        <% end %>
      </.ai_box>
      <.live_component
        :if={@edit_student_ilp}
        module={StudentILPFormOverlayComponent}
        id={"#{@id}-student-ilp-form-overlay"}
        student_ilp={@edit_student_ilp}
        template={@template}
        title={@ilp_form_overlay_title}
        current_profile={@current_profile}
        on_cancel={@on_edit_cancel}
        notify_component={@myself}
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
      |> assign(:ai_form_error, nil)
      |> assign(:ai_response_error, nil)
      |> assign(:ai_response, nil)
      |> assign(:ai_cooldown_minutes, nil)
      |> assign(:ai_cooldown_minutes_left, nil)
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
    |> ensure_template_ai_layer_is_loaded()
    |> assign_student_ilp()
    |> assign_ai_form()
    |> assign_has_ai_revision()
    |> assign_is_on_ai_cooldown()
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

  defp assign_ai_form(
         %{assigns: %{template: %ILPTemplate{}, student_ilp: %StudentILP{}}} = socket
       ) do
    # we enable the AI form only if
    # - ILP has all entries
    # - template has AI revision instructions
    # - template has a selected AI model

    has_all_entries =
      socket.assigns.student_ilp.entries
      |> Enum.all?(&(not is_nil(&1.description)))

    template_ai_layer_is_ok =
      socket.assigns.template.ai_layer &&
        not is_nil(socket.assigns.template.ai_layer.revision_instructions) &&
        not is_nil(socket.assigns.template.ai_layer.model)

    if has_all_entries && template_ai_layer_is_ok do
      form = to_form(%{"age" => nil}, as: :ai_form)
      assign(socket, :ai_form, form)
    else
      assign(socket, :ai_form, nil)
    end
  end

  defp assign_ai_form(socket) do
    assign(socket, :ai_form, nil)
  end

  defp assign_has_ai_revision(socket) do
    has_ai_revision =
      case socket.assigns.student_ilp do
        %StudentILP{ai_revision: revision} when not is_nil(revision) -> true
        _ -> false
      end

    assign(socket, :has_ai_revision, has_ai_revision)
  end

  defp assign_is_on_ai_cooldown(%{assigns: %{has_ai_revision: true}} = socket) do
    ai_cooldown_minutes =
      (socket.assigns.template.ai_layer && socket.assigns.template.ai_layer.cooldown_minutes) || 0

    cooldown_end_datetime =
      DateTime.shift(socket.assigns.student_ilp.ai_revision_datetime, minute: ai_cooldown_minutes)

    is_on_ai_cooldown =
      DateTime.before?(DateTime.utc_now(), cooldown_end_datetime)

    ai_cooldown_minutes_left =
      Timex.diff(
        cooldown_end_datetime,
        DateTime.utc_now(),
        :minutes
      )

    socket
    |> assign(:is_on_ai_cooldown, is_on_ai_cooldown)
    |> assign(:ai_cooldown_minutes, ai_cooldown_minutes)
    |> assign(:ai_cooldown_minutes_left, ai_cooldown_minutes_left)
  end

  defp assign_is_on_ai_cooldown(socket),
    do: assign(socket, :is_on_ai_cooldown, false)

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

  # event handlers

  @impl true
  def handle_event("request_ai_review", %{"ai_form" => %{"age" => age}}, socket) do
    socket =
      case Integer.parse(age) do
        {age, ""} when age in @age_range ->
          ILP.revise_student_ilp(
            socket.assigns.student_ilp,
            socket.assigns.template,
            age,
            log_profile_id: socket.assigns.current_profile.id
          )
          |> case do
            {:ok, student_ilp} ->
              socket
              |> assign(:student_ilp, student_ilp)
              |> assign_has_ai_revision()
              |> assign_is_on_ai_cooldown()
              |> assign(:ai_response_error, nil)
              |> assign(:ai_form_error, nil)

            _ ->
              socket
              |> assign(:ai_response_error, gettext("AI revision failed"))
              |> assign(:ai_form_error, nil)
          end

        _ ->
          error = gettext("Age should be a number between 0 and 100")
          assign(socket, :ai_form_error, error)
      end

    {:noreply, socket}
  end
end
