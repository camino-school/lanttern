defmodule LantternWeb.Assessments.EntryDetailsOverlayComponent do
  @moduledoc """
  Render an assessment point entry detail overlay.

  When initializing the component, it will create the entry in the DB if it doesn't exist yet.
  ```

  """
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Grading.OrdinalValue
  alias Lanttern.Grading.Scale

  # shared components
  alias LantternWeb.Attachments.AttachmentAreaComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.slide_over id={@id} show={true} on_cancel={@on_cancel}>
        <:title><%= gettext("Assessment point entry details") %></:title>
        <.metadata class="mb-6" icon_name="hero-user">
          <%= @student.name %>
        </.metadata>
        <.metadata icon_name="hero-document-text">
          <div class="flex flex-wrap gap-1 mb-1">
            <.badge><%= @assessment_point.curriculum_item.curriculum_component.name %></.badge>
            <.badge :if={@assessment_point.is_differentiation} theme="diff">
              <%= gettext("Differentiation") %>
            </.badge>
          </div>
          <p><%= @assessment_point.curriculum_item.name %></p>
        </.metadata>
        <.form
          for={@form}
          phx-change="change_marking"
          phx-submit="save_marking"
          phx-target={@myself}
          class="mt-10"
        >
          <div class="grid grid-cols-2 gap-2">
            <div class="pb-1 border-b-2 border-ltrn-staff-accent text-xs text-center text-ltrn-staff-dark">
              <%= gettext("Teacher assessment") %>
            </div>
            <div class="pb-1 border-b-2 border-ltrn-student-accent text-xs text-center text-ltrn-student-dark">
              <%= gettext("Student self-assessment") %>
            </div>
            <.marking_input
              scale={@assessment_point.scale}
              ordinal_value_options={@ordinal_value_options}
              form={@form}
              assessment_view="teacher"
              ov_style_map={@ov_style_map}
              has_change={@has_teacher_change}
            />
            <.marking_input
              scale={@assessment_point.scale}
              ordinal_value_options={@ordinal_value_options}
              form={@form}
              assessment_view="student"
              ov_style_map={@ov_style_map}
              has_change={@has_student_change}
            />
          </div>
          <div
            :if={@has_teacher_change || @has_student_change}
            class="p-2 rounded mt-2 text-sm text-white text-center bg-ltrn-dark"
          >
            <button class="underline hover:text-ltrn-primary">
              <%= gettext("Save") %>
            </button>
            <%= gettext("or") %>
            <button
              type="button"
              theme="ghost"
              class="underline hover:text-ltrn-light"
              phx-click="cancel_change_marking"
              phx-target={@myself}
            >
              <%= gettext("discard changes") %>
            </button>
          </div>
        </.form>
        <.comment_area
          note={@entry.report_note}
          is_editing={@is_editing_note}
          form={@form}
          error={@save_note_error}
          theme="staff"
          on_edit={JS.push("edit_note", target: @myself)}
          on_cancel={JS.push("cancel_edit_note", target: @myself)}
          on_save={JS.push("save_note", target: @myself)}
          class="mt-10"
        />
        <.comment_area
          note={@entry.student_report_note}
          is_editing={@is_editing_student_note}
          form={@form}
          error={@save_student_note_error}
          theme="student"
          student_name={@student.name}
          on_edit={JS.push("edit_student_note", target: @myself)}
          on_cancel={JS.push("cancel_edit_student_note", target: @myself)}
          on_save={JS.push("save_note", target: @myself)}
          class="mt-6"
        />
        <.live_component
          :if={@entry && @entry.id}
          module={AttachmentAreaComponent}
          id="assessment-point-entry-evidences"
          class="mt-10"
          current_user={@current_user}
          assessment_point_entry_id={@entry.id}
          title={gettext("Assessment point entry's evidences")}
          allow_editing
          notify_component={@myself}
        />
      </.slide_over>
    </div>
    """
  end

  attr :scale, Scale, required: true
  attr :ordinal_value_options, :list, required: true
  attr :form, Phoenix.HTML.Form, required: true
  attr :assessment_view, :string, required: true
  attr :ov_style_map, :map, required: true
  attr :has_change, :boolean, required: true

  def marking_input(%{scale: %{type: "ordinal"}} = assigns) do
    field =
      case assigns.assessment_view do
        "student" -> assigns.form[:student_ordinal_value_id]
        _ -> assigns.form[:ordinal_value_id]
      end

    class =
      case assigns.has_change do
        true -> "bg-white"
        _ -> "bg-ltrn-lighter"
      end

    style =
      case assigns.has_change do
        true -> ""
        _ -> Map.get(assigns.ov_style_map, "#{field.value}", "")
      end

    assigns =
      assigns
      |> assign(:field, field)
      |> assign(:class, class)
      |> assign(:style, style)

    ~H"""
    <.select
      type="select"
      name={@field.name}
      value={@field.value}
      options={@ordinal_value_options}
      prompt="—"
      class={["py-3 rounded-sm font-mono text-sm text-center truncate", @class]}
      style={@style}
    />
    """
  end

  def marking_input(%{scale: %{type: "numeric"}} = assigns) do
    field =
      case assigns.assessment_view do
        "student" -> assigns.form[:student_score]
        _ -> assigns.form[:score]
      end

    assigns = assign(assigns, :field, field)

    ~H"""
    <.input field={@field} type="number" phx-debounce="1000" min={@scale.start} max={@scale.stop} />
    """
  end

  attr :note, :string, required: true
  attr :is_editing, :boolean, required: true
  attr :form, Phoenix.HTML.Form, required: true
  attr :error, :string, required: true
  attr :theme, :string, required: true, doc: "teacher or student"
  attr :student_name, :string, default: nil
  attr :on_edit, JS, required: true
  attr :on_cancel, JS, required: true
  attr :on_save, JS, required: true
  attr :class, :any, default: nil

  def comment_area(assigns) do
    new_assigns =
      case assigns.theme do
        "staff" ->
          %{
            bg_lightest: "bg-ltrn-staff-lightest",
            text_accent: "text-ltrn-staff-accent",
            text_dark: "text-ltrn-staff-dark",
            comment_text: gettext("Teacher comment"),
            no_comment_text: gettext("No teacher comment"),
            field: assigns.form[:report_note]
          }

        "student" ->
          %{
            bg_lightest: "bg-ltrn-student-lightest",
            text_accent: "text-ltrn-student-accent",
            text_dark: "text-ltrn-student-dark",
            comment_text: gettext("%{student} comment", student: assigns.student_name),
            no_comment_text: gettext("No student comment"),
            field: assigns.form[:student_report_note]
          }
      end

    assigns = assign(assigns, new_assigns)

    ~H"""
    <div class={[
      "p-4 rounded mt-10",
      @class,
      if(@note, do: @bg_lightest, else: "bg-ltrn-lightest")
    ]}>
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2 font-bold text-sm">
          <.icon name="hero-chat-bubble-oval-left" class={["w-6 h-6", @text_accent]} />
          <span class={@text_dark}><%= @comment_text %></span>
        </div>
        <button
          :if={!@is_editing}
          phx-click={@on_edit}
          class={["font-display font-bold text-sm underline hover:opacity-50", @text_dark]}
        >
          <%= if @note, do: gettext("Edit"), else: gettext("Add") %>
        </button>
      </div>
      <.form :if={@is_editing} for={@form} phx-submit={@on_save} class="mt-4">
        <.input field={@field} type="textarea" phx-debounce="1500" class="mb-1" />
        <.markdown_supported />
        <p :if={@error} class="p-4 rounded mt-4 text-sm text-ltrn-alert-accent bg-ltrn-alert-lighter">
          <%= @error %>
        </p>
        <div class="flex justify-end gap-2 mt-6">
          <.button type="button" theme="ghost" phx-click={@on_cancel}>
            <%= gettext("Cancel") %>
          </.button>
          <.button type="submit" theme={@theme}><%= gettext("Save comment") %></.button>
        </div>
      </.form>
      <.markdown :if={!@is_editing && @note} text={@note} class="max-w-none mt-4" />
      <div
        :if={!@is_editing && !@note}
        class="p-4 rounded border border-dashed border-ltrn-light mt-4 text-sm text-center text-ltrn-subtle"
      >
        <%= @no_comment_text %>
      </div>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:has_teacher_change, false)
      |> assign(:has_student_change, false)
      |> assign(:save_marking_error, nil)
      |> assign(:ov_style_map, nil)
      |> assign(:is_editing_note, false)
      |> assign(:is_editing_student_note, false)
      |> assign(:save_note_error, nil)
      |> assign(:save_student_note_error, nil)

    {:ok, socket}
  end

  @impl true
  def update(%{action: {AttachmentAreaComponent, {:created, attachment}}}, socket) do
    notify(
      __MODULE__,
      {:created_attachment, attachment},
      socket.assigns
    )

    {:ok, socket}
  end

  def update(%{action: {AttachmentAreaComponent, {:edited, attachment}}}, socket) do
    notify(
      __MODULE__,
      {:edited_attachment, attachment},
      socket.assigns
    )

    {:ok, socket}
  end

  def update(%{action: {AttachmentAreaComponent, {:deleted, attachment}}}, socket) do
    notify(
      __MODULE__,
      {:deleted_attachment, attachment},
      socket.assigns
    )

    {:ok, socket}
  end

  def update(%{entry: %AssessmentPointEntry{}} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_student()
      |> assign_assessment_point()
      |> maybe_create_and_assign_entry()
      |> assign_form()
      |> assign_ordinal_value_options()
      |> assign_ov_style_map()

    {:ok, socket}
  end

  defp assign_student(socket) do
    %{student: student} =
      socket.assigns.entry
      |> Lanttern.Repo.preload([:student])

    assign(socket, :student, student)
  end

  defp assign_assessment_point(socket) do
    %{assessment_point: assessment_point} =
      socket.assigns.entry
      |> Lanttern.Repo.preload(
        assessment_point: [scale: :ordinal_values, curriculum_item: :curriculum_component]
      )

    assign(socket, :assessment_point, assessment_point)
  end

  defp maybe_create_and_assign_entry(%{assigns: %{entry: %{id: nil}}} = socket) do
    params =
      %{
        assessment_point_id: socket.assigns.assessment_point.id,
        scale_id: socket.assigns.assessment_point.scale.id,
        scale_type: socket.assigns.assessment_point.scale.type,
        student_id: socket.assigns.student.id
      }

    {:ok, entry} =
      Assessments.create_assessment_point_entry(params,
        log_profile_id: socket.assigns.current_user.current_profile_id
      )

    notify(
      __MODULE__,
      {:created_entry, entry},
      socket.assigns
    )

    assign(socket, :entry, entry)
  end

  defp maybe_create_and_assign_entry(socket), do: socket

  defp assign_form(socket) do
    form =
      socket.assigns.entry
      |> Assessments.change_assessment_point_entry()
      |> to_form()

    assign(socket, :form, form)
  end

  defp assign_ordinal_value_options(
         %{assigns: %{assessment_point: %{scale: %{type: "ordinal"}}}} = socket
       ) do
    ordinal_value_options =
      socket.assigns.assessment_point.scale.ordinal_values
      |> Enum.map(fn ov -> {ov.name, ov.id} end)

    assign(socket, :ordinal_value_options, ordinal_value_options)
  end

  defp assign_ordinal_value_options(socket),
    do: assign(socket, :ordinal_value_options, [])

  defp assign_ov_style_map(%{assigns: %{entry: %{scale_type: "ordinal"}}} = socket) do
    %{
      assessment_point: %{scale: %{ordinal_values: ordinal_values}}
    } = socket.assigns

    ov_style_map =
      ordinal_values
      |> Enum.map(fn ov ->
        {"#{ov.id}", get_colors_style(ov)}
      end)
      |> Enum.into(%{})

    socket
    |> assign(:ov_style_map, ov_style_map)
  end

  defp assign_ov_style_map(socket), do: socket

  # event handlers

  @impl true
  def handle_event("change_marking", %{"assessment_point_entry" => params}, socket) do
    entry = socket.assigns.entry

    form =
      entry
      |> Assessments.change_assessment_point_entry(params)
      |> to_form()

    {has_teacher_change, has_student_change} =
      case entry do
        %{scale_type: "ordinal"} ->
          {
            "#{entry.ordinal_value_id}" != params["ordinal_value_id"],
            "#{entry.student_ordinal_value_id}" != params["student_ordinal_value_id"]
          }

        %{scale_type: "numeric"} ->
          {
            "#{entry.score}" != params["score"],
            "#{entry.student_score}" != params["student_score"]
          }
      end

    socket =
      socket
      |> assign(:has_teacher_change, has_teacher_change)
      |> assign(:has_student_change, has_student_change)
      |> assign(:form, form)

    {:noreply, socket}
  end

  def handle_event("save_marking", %{"assessment_point_entry" => params}, socket) do
    opts = [log_profile_id: socket.assigns.current_user.current_profile_id]

    socket =
      case Assessments.update_assessment_point_entry(socket.assigns.entry, params, opts) do
        {:ok, entry} ->
          notify(
            __MODULE__,
            {:change, entry},
            socket.assigns
          )

          socket
          |> assign(:entry, entry)
          |> assign(:has_teacher_change, false)
          |> assign(:has_student_change, false)
          |> assign(:save_marking_error, nil)

        {:error, _} ->
          assign(socket, :save_marking_error, gettext("Something went wrong"))
      end

    {:noreply, socket}
  end

  def handle_event("cancel_change_marking", _, socket) do
    form =
      socket.assigns.entry
      |> Assessments.change_assessment_point_entry()
      |> to_form()

    socket =
      socket
      |> assign(:has_teacher_change, false)
      |> assign(:has_student_change, false)
      |> assign(:form, form)

    {:noreply, socket}
  end

  def handle_event("edit_note", _, socket),
    do: {:noreply, assign(socket, :is_editing_note, true)}

  def handle_event("cancel_edit_note", _, socket),
    do: {:noreply, assign(socket, :is_editing_note, false)}

  def handle_event("edit_student_note", _, socket),
    do: {:noreply, assign(socket, :is_editing_student_note, true)}

  def handle_event("cancel_edit_student_note", _, socket),
    do: {:noreply, assign(socket, :is_editing_student_note, false)}

  def handle_event(
        "save_note",
        %{"assessment_point_entry" => %{"report_note" => _} = params},
        socket
      ) do
    socket =
      socket
      |> handle_save_note(params, "teacher")

    {:noreply, socket}
  end

  def handle_event(
        "save_note",
        %{"assessment_point_entry" => %{"student_report_note" => _} = params},
        socket
      ) do
    socket =
      socket
      |> handle_save_note(params, "student")

    {:noreply, socket}
  end

  # helpers

  defp handle_save_note(socket, params, type) do
    opts = [log_profile_id: socket.assigns.current_user.current_profile_id]

    case Assessments.update_assessment_point_entry(socket.assigns.entry, params, opts) do
      {:ok, entry} ->
        notify(
          __MODULE__,
          {:change, entry},
          socket.assigns
        )

        form =
          entry
          |> Assessments.change_assessment_point_entry(params)
          |> to_form()

        socket =
          case type do
            "teacher" ->
              socket
              |> assign(:is_editing_note, false)
              |> assign(:save_note_error, nil)
              |> assign(:form, form)

            "student" ->
              socket
              |> assign(:is_editing_student_note, false)
              |> assign(:save_student_note_error, nil)
              |> assign(:form, form)
          end

        socket
        |> assign(:entry, entry)

      {:error, _} ->
        case type do
          "teacher" -> assign(socket, :save_note_error, gettext("Something went wrong"))
          "student" -> assign(socket, :save_student_note_error, gettext("Something went wrong"))
        end
    end
  end

  defp get_colors_style(%OrdinalValue{} = ov) do
    "background-color: #{ov.bg_color}; color: #{ov.text_color}"
  end
end
