defmodule LantternWeb.Assessments.EntryDetailsComponent do
  @moduledoc """
  TBD
  ```

  """
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPointEntry
  # alias Lanttern.Grading.OrdinalValue
  # alias Lanttern.Grading.Scale

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.metadata class="mb-6" icon_name="hero-user">
        <%= @student.name %>
      </.metadata>
      <.metadata class="mb-6" icon_name="hero-document-text">
        <div class="flex flex-wrap gap-1 mb-1">
          <.badge><%= @assessment_point.curriculum_item.curriculum_component.name %></.badge>
          <.badge :if={@assessment_point.is_differentiation} theme="diff">
            <%= gettext("Differentiation") %>
          </.badge>
        </div>
        <p><%= @assessment_point.curriculum_item.name %></p>
      </.metadata>
      <div class="p-4 mt-4 bg-white shadow-lg">
        Teacher and student entries
      </div>
      <div class="p-4 mt-4 bg-white shadow-lg">
        Rubrics
      </div>
      <.comment_area
        note={@entry.report_note}
        is_editing={@is_editing_note}
        form={@form}
        error={@save_note_error}
        theme="teacher"
        on_edit={JS.push("edit_note", target: @myself)}
        on_cancel={JS.push("cancel_edit_note", target: @myself)}
        on_save={JS.push("save_note", target: @myself)}
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
      />
      <%!-- <div class="p-4 rounded mt-4 bg-ltrn-teacher-lightest">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2 font-bold text-sm">
            <.icon name="hero-chat-bubble-oval-left" class="w-6 h-6 text-ltrn-teacher-accent" />
            <span class="text-ltrn-teacher-dark"><%= gettext("Teacher comment") %></span>
          </div>
          <.button :if={!@is_editing_note} theme="ghost" phx-click="edit_note" phx-target={@myself}>
            <%= gettext("Edit") %>
          </.button>
        </div>
        <.form
          :if={@is_editing_note}
          for={@form}
          phx-submit="save_note"
          phx-target={@myself}
          id={"entry-#{@id}-note-form"}
          class="mt-4"
        >
          <.input field={@form[:report_note]} type="textarea" phx-debounce="1500" class="mb-1" />
          <.markdown_supported />
          <div class="flex justify-end gap-2 mt-6">
            <.button type="button" theme="ghost" phx-click="cancel_edit_note" phx-target={@myself}>
              <%= gettext("Cancel") %>
            </.button>
            <.button type="submit" theme="teacher"><%= gettext("Save note") %></.button>
          </div>
        </.form>
        <.markdown
          :if={!@is_editing_note && @entry.report_note}
          text={@entry.report_note}
          size="sm"
          class="max-w-none mt-4"
        />
        <div
          :if={!@is_editing_note && !@entry.report_note}
          class="p-4 rounded border border-dashed border-ltrn-teacher-accent mt-4 text-sm text-center text-ltrn-subtle"
        >
          <%= gettext("No teacher comment") %>
        </div>
      </div> --%>
      <%!-- <div class="p-4 rounded mt-4 bg-ltrn-student-lightest">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2 font-bold text-sm">
            <.icon name="hero-chat-bubble-oval-left" class="w-6 h-6 text-ltrn-student-accent" />
            <span class="text-ltrn-student-dark">
              <%= gettext("%{student} comment", student: @student.name) %>
            </span>
          </div>
          <.button theme="ghost"><%= gettext("Edit") %></.button>
        </div>
        <%= if @entry.student_report_note do %>
          <.markdown text={@entry.student_report_note} size="sm" class="max-w-none mt-4" />
        <% else %>
          <div class="p-4 rounded border border-dashed border-ltrn-student-accent mt-4 text-sm text-center text-ltrn-subtle">
            <%= gettext("No student comment") %>
          </div>
        <% end %>
      </div> --%>
      <div class="p-4 mt-4 bg-white shadow-lg">
        Evidences
      </div>
      <%!-- <.form
        for={@form}
        phx-change="change"
        phx-target={@myself}
        class={[@class, if(@has_changes, do: "outline outline-4 outline-offset-1 outline-ltrn-dark")]}
        id={"entry-#{@id}-marking-form"}
      >
        <%= for marking_input <- @marking_input do %>
          <.marking_input
            scale={@assessment_point.scale}
            ordinal_value_options={@ordinal_value_options}
            form={@form}
            assessment_view={@assessment_view}
            style={if(!@has_changes, do: @ov_style)}
            ov_name={@ov_name}
            class={Map.get(marking_input, :class, "")}
          />
        <% end %>
      </.form>
      <.icon_button
        type="button"
        name="hero-pencil-square-mini"
        theme={@note_button_theme}
        rounded
        sr_text={gettext("Add entry note")}
        size="sm"
        class="ml-2"
        disabled={!@entry.id}
        phx-click="edit_note"
        phx-target={@myself}
      />
      <.modal
        :if={@is_editing_note}
        id={"entry-#{@id}-note-modal"}
        show
        on_cancel={JS.push("cancel_edit_note", target: @myself)}
      >
        <h5 class="mb-10 font-display font-black text-xl">
          <%= gettext("Entry report note") %>
        </h5>
        <.form for={@form} phx-submit="save_note" phx-target={@myself} id={"entry-#{@id}-note-form"}>
          <.input
            field={
              if @assessment_view == "student",
                do: @form[:student_report_note],
                else: @form[:report_note]
            }
            type="textarea"
            label={gettext("Note")}
            class="mb-1"
            phx-debounce="1500"
          />
          <.markdown_supported />
          <div class="flex justify-end mt-10">
            <.button type="submit"><%= gettext("Save note") %></.button>
          </div>
        </.form>
      </.modal> --%>
    </div>
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

  def comment_area(assigns) do
    new_assigns =
      case assigns.theme do
        "teacher" ->
          %{
            bg_lightest: "bg-ltrn-teacher-lightest",
            text_accent: "text-ltrn-teacher-accent",
            text_dark: "text-ltrn-teacher-dark",
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
      "p-4 rounded mt-4",
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
      <.markdown :if={!@is_editing && @note} text={@note} size="sm" class="max-w-none mt-4" />
      <div
        :if={!@is_editing && !@note}
        class="p-4 rounded border border-dashed border-ltrn-light mt-4 text-sm text-center text-ltrn-subtle"
      >
        <%= @no_comment_text %>
      </div>
    </div>
    """
  end

  # attr :scale, Scale, required: true
  # attr :ordinal_value_options, :list
  # attr :style, :string
  # attr :class, :any
  # attr :ov_name, :string
  # attr :form, :map, required: true
  # attr :assessment_view, :string, required: true

  # def marking_input(%{scale: %{type: "ordinal"}} = assigns) do
  #   field =
  #     case assigns.assessment_view do
  #       "student" -> assigns.form[:student_ordinal_value_id]
  #       _ -> assigns.form[:ordinal_value_id]
  #     end

  #   assigns = assign(assigns, :field, field)

  #   ~H"""
  #   <div class={@class}>
  #     <.select
  #       name={@field.name}
  #       prompt="—"
  #       options={@ordinal_value_options}
  #       value={@field.value}
  #       class={[
  #         "w-full h-full rounded-sm font-mono text-sm text-center truncate",
  #         @field.value in [nil, ""] && "bg-ltrn-lighter"
  #       ]}
  #       style={@style}
  #     />
  #   </div>
  #   """
  # end

  # def marking_input(%{scale: %{type: "numeric"}} = assigns) do
  #   field =
  #     case assigns.assessment_view do
  #       "student" -> assigns.form[:student_score]
  #       _ -> assigns.form[:score]
  #     end

  #   assigns = assign(assigns, :field, field)

  #   ~H"""
  #   <div class={@class}>
  #     <.base_input
  #       name={@field.name}
  #       type="number"
  #       phx-debounce="1000"
  #       value={@field.value}
  #       errors={@field.errors}
  #       class={[
  #         "h-full font-mono text-center",
  #         @field.value == nil && "bg-ltrn-lighter"
  #       ]}
  #       min={@scale.start}
  #       max={@scale.stop}
  #     />
  #   </div>
  #   """
  # end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:has_changes, false)
      |> assign(:is_editing_note, false)
      |> assign(:save_note_error, nil)
      |> assign(:save_student_note_error, nil)
      |> assign(:is_editing_student_note, false)

    {:ok, socket}
  end

  @impl true
  def update(%{entry: %AssessmentPointEntry{}} = assigns, socket) do
    %{
      student: student,
      assessment_point: assessment_point
    } =
      assigns.entry
      |> Lanttern.Repo.preload([
        :student,
        assessment_point: [curriculum_item: :curriculum_component]
      ])

    form =
      assigns.entry
      |> Assessments.change_assessment_point_entry()
      |> to_form()

    socket =
      socket
      |> assign(assigns)
      |> assign(:student, student)
      |> assign(:assessment_point, assessment_point)
      |> assign(:form, form)

    {:ok, socket}
  end

  def update(_assigns, socket), do: {:ok, socket}

  # @impl true
  # def update(assigns, socket) do
  #   %{
  #     student: student,
  #     assessment_point: assessment_point,
  #     entry: entry
  #   } = assigns

  #   entry = entry || new_assessment_point_entry(assessment_point, student.id)

  #   form =
  #     entry
  #     |> Assessments.change_assessment_point_entry()
  #     |> to_form()

  #   socket =
  #     socket
  #     |> assign(assigns)
  #     |> assign(:entry, entry)
  #     |> assign(:form, form)
  #     |> assign_ordinal_value_options()
  #     |> assign_entry_value()
  #     |> assign_entry_note()
  #     |> assign_ov_style_and_name()

  #   {:ok, socket}
  # end

  # event handlers

  @impl true
  def handle_event("edit_note", _, socket),
    do: {:noreply, assign(socket, :is_editing_note, true)}

  def handle_event("cancel_edit_note", _, socket),
    do: {:noreply, assign(socket, :is_editing_note, false)}

  def handle_event("edit_student_note", _, socket),
    do: {:noreply, assign(socket, :is_editing_student_note, true)}

  def handle_event("cancel_edit_student_note", _, socket),
    do: {:noreply, assign(socket, :is_editing_student_note, false)}

  # @impl true
  # def handle_event("change", %{"assessment_point_entry" => params}, socket) do
  #   %{
  #     entry: %{scale_type: scale_type} = entry,
  #     assessment_view: assessment_view,
  #     entry_value: entry_value
  #   } = socket.assigns

  #   form =
  #     entry
  #     |> Assessments.change_assessment_point_entry(params)
  #     |> to_form()

  #   entry_params =
  #     entry
  #     |> Map.from_struct()
  #     |> Map.take([:student_id, :assessment_point_id, :scale_id, :scale_type])
  #     |> Map.new(fn {k, v} -> {to_string(k), v} end)

  #   composite_id = "#{entry_params["student_id"]}_#{entry_params["assessment_point_id"]}"

  #   # add extra fields from entry
  #   params =
  #     params
  #     |> Enum.into(entry_params)

  #   param_value =
  #     case {params, assessment_view} do
  #       {%{"scale_type" => "ordinal"}, "student"} -> params["student_ordinal_value_id"]
  #       {%{"scale_type" => "numeric"}, "student"} -> params["student_score"]
  #       {%{"scale_type" => "ordinal"}, _teacher} -> params["ordinal_value_id"]
  #       {%{"scale_type" => "numeric"}, _teacher} -> params["score"]
  #     end

  #   # when in student view, other value
  #   # is the teacher value (and vice versa)
  #   other_entry_value =
  #     case {scale_type, assessment_view} do
  #       {"ordinal", "student"} -> entry.ordinal_value_id
  #       {"numeric", "student"} -> entry.score
  #       {"ordinal", _teacher} -> entry.student_ordinal_value_id
  #       {"numeric", _teacher} -> entry.student_score
  #     end

  #   # types: new, delete, edit, cancel
  #   {change_type, has_changes} =
  #     case {entry.id, "#{entry_value}", other_entry_value, param_value} do
  #       {_, entry_value, _, param_value} when entry_value == param_value ->
  #         {:cancel, false}

  #       {nil, _, _, param_value} when param_value != "" ->
  #         {:new, true}

  #       {entry_id, _, nil, ""} when not is_nil(entry_id) ->
  #         {:delete, true}

  #       _ ->
  #         {:edit, true}
  #     end

  #   notify(
  #     __MODULE__,
  #     {:change, change_type, composite_id, entry.id, params},
  #     socket.assigns
  #   )

  #   socket =
  #     socket
  #     |> assign(:has_changes, has_changes)
  #     |> assign(:form, form)

  #   {:noreply, socket}
  # end

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

            "student" ->
              socket
              |> assign(:is_editing_student_note, false)
              |> assign(:save_student_note_error, nil)
          end

        socket
        |> assign(:entry, entry)
        |> assign(:form, form)

      {:error, _} ->
        case type do
          "teacher" -> assign(socket, :save_note_error, gettext("Something went wrong"))
          "student" -> assign(socket, :save_student_note_error, gettext("Something went wrong"))
        end
    end
  end

  # defp new_assessment_point_entry(assessment_point, student_id) do
  #   %AssessmentPointEntry{
  #     student_id: student_id,
  #     assessment_point_id: assessment_point.id,
  #     scale_id: assessment_point.scale.id,
  #     scale_type: assessment_point.scale.type
  #   }
  # end

  # defp assign_ordinal_value_options(
  #        %{assigns: %{assessment_point: %{scale: %{type: "ordinal"}}}} = socket
  #      ) do
  #   ordinal_value_options =
  #     socket.assigns.assessment_point.scale.ordinal_values
  #     |> Enum.map(fn ov -> {:"#{ov.name}", ov.id} end)

  #   assign(socket, :ordinal_value_options, ordinal_value_options)
  # end

  # defp assign_ordinal_value_options(socket),
  #   do: assign(socket, :ordinal_value_options, [])

  # defp assign_entry_value(socket) do
  #   %{
  #     entry: entry,
  #     assessment_view: assessment_view,
  #     assessment_point: %{scale: %{type: scale_type}}
  #   } = socket.assigns

  #   entry_value =
  #     case {scale_type, assessment_view} do
  #       {"ordinal", "student"} -> entry.student_ordinal_value_id
  #       {"numeric", "student"} -> entry.student_score
  #       {"ordinal", _teacher} -> entry.ordinal_value_id
  #       {"numeric", _teacher} -> entry.score
  #     end

  #   assign(socket, :entry_value, entry_value)
  # end

  # defp assign_entry_note(socket) do
  #   %{
  #     entry: entry,
  #     assessment_view: assessment_view
  #   } = socket.assigns

  #   entry_note =
  #     case assessment_view do
  #       "student" -> entry.student_report_note
  #       _ -> entry.report_note
  #     end

  #   note_button_theme =
  #     cond do
  #       entry_note && assessment_view == "student" -> "student"
  #       entry_note -> "teacher"
  #       true -> "ghost"
  #     end

  #   socket
  #   |> assign(:entry_note, entry_note)
  #   |> assign(:note_button_theme, note_button_theme)
  # end

  # defp assign_ov_style_and_name(socket) do
  #   %{
  #     entry_value: entry_value,
  #     assessment_point: %{scale: %{ordinal_values: ordinal_values, type: scale_type}}
  #   } = socket.assigns

  #   {ov_style, ov_name} =
  #     case {scale_type, entry_value} do
  #       {"ordinal", ordinal_value_id} when not is_nil(ordinal_value_id) ->
  #         ov =
  #           ordinal_values
  #           |> Enum.find(&(&1.id == ordinal_value_id))

  #         {get_colors_style(ov), ov.name}

  #       _ ->
  #         {nil, nil}
  #     end

  #   socket
  #   |> assign(:ov_style, ov_style)
  #   |> assign(:ov_name, ov_name)
  # end

  # defp get_colors_style(%OrdinalValue{} = ordinal_value) do
  #   "background-color: #{ordinal_value.bg_color}; color: #{ordinal_value.text_color}"
  # end

  # defp get_colors_style(_), do: ""
end
