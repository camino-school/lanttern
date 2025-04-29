defmodule LantternWeb.GradesReports.StudentGradesReportEntryFormComponent do
  @moduledoc """
  Renders a `StudentGradesReportEntry` form
  """

  use LantternWeb, :live_component

  alias Lanttern.GradesReports
  alias Lanttern.Grading

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form
        for={@form}
        id="student-grade-report-entry-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="mb-6">
          <.input
            :if={@scale_type == "ordinal"}
            field={@form[:ordinal_value_id]}
            type="select"
            label={gettext("Level")}
            options={@ordinal_value_options}
            prompt={gettext("Select a level")}
          />
          <.input
            :if={@scale_type == "numeric"}
            field={@form[:score]}
            type="number"
            label={gettext("Score")}
          />
          <p
            :if={@has_manual_edit}
            class="p-2 rounded-xs border border-ltrn-staff-accent mt-2 text-sm bg-ltrn-staff-lightest"
          >
            <%= gettext(
              "Different from grade composition. Use comments field to justify it if needed."
            ) %>
          </p>
          <%= if @has_manual_edit || @has_normalized_value_edit do %>
            <div class="p-4 rounded-sm mt-2 bg-ltrn-alert-lighter">
              <.input
                field={@form[:normalized_value]}
                type="number"
                label={gettext("Normalized value")}
                phx-debounce="1500"
                min="0"
                max="1"
                step="0.00001"
              />
              <p class="mt-4 text-sm">
                <%= gettext(
                  "Normalized values are used to calculate final grades — when levels are changed manually without normalized values adjustments, final grades calculation can be misaligned with related subcycle grades."
                ) %>
              </p>
              <p :if={@has_normalized_value_edit} class="mt-2 text-sm">
                <%= gettext("Composition normalized value (reference)") %>: <%= @student_grades_report_entry.composition_normalized_value %>
              </p>
            </div>
          <% else %>
            <.input
              name={@form[:normalized_value].name}
              value={@form[:composition_normalized_value].value}
              type="hidden"
            />
          <% end %>
        </div>
        <.input
          field={@form[:comment]}
          type="textarea"
          label={gettext("Comment")}
          phx-debounce="1500"
          class="mb-1"
          show_optional
        />
        <.markdown_supported class="mb-6" />
        <div class={[
          "p-4 rounded-sm",
          if(!@hide_submit, do: "mb-6"),
          if(@has_retake_history,
            do: "bg-ltrn-alert-lighter",
            else: "bg-ltrn-lighter"
          )
        ]}>
          <.input
            :if={@scale_type == "ordinal"}
            field={@form[:pre_retake_ordinal_value_id]}
            type="select"
            label={gettext("Level before retake")}
            options={@ordinal_value_options}
            prompt={gettext("Select a level")}
          />
          <.input
            :if={@scale_type == "numeric"}
            field={@form[:pre_retake_score]}
            type="number"
            label={gettext("Score before retake")}
          />
          <p class="mt-4 text-sm">
            <%= gettext("If needed, use this area to keep the student grade history before retake.") %>
          </p>
        </div>
        <.button :if={!@hide_submit} phx-disable-with={gettext("Saving...")}>
          <%= gettext("Save student grade report entry") %>
        </.button>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:hide_submit, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    %{
      student_grades_report_entry: student_grades_report_entry,
      scale_id: scale_id
    } = assigns

    changeset = GradesReports.change_student_grades_report_entry(student_grades_report_entry)

    scale = Grading.get_scale!(scale_id, preloads: :ordinal_values)

    ordinal_value_options =
      scale.ordinal_values
      |> Enum.map(&{&1.name, &1.id})

    socket =
      socket
      |> assign(assigns)
      |> assign(:ordinal_value_options, ordinal_value_options)
      |> assign(:scale_type, scale.type)
      |> assign_form(changeset)
      |> assign_has_manual_edit()
      |> assign_has_normalized_value_edit()
      |> assign_has_retake_history(changeset)

    {:ok, socket}
  end

  defp assign_has_manual_edit(socket) do
    %{
      form: form,
      student_grades_report_entry: student_grades_report_entry,
      scale_type: scale_type
    } = socket.assigns

    has_manual_edit =
      cond do
        scale_type == "ordinal" &&
            "#{form[:ordinal_value_id].value}" !=
              "#{student_grades_report_entry.composition_ordinal_value_id}" ->
          true

        scale_type == "numeric" &&
            "#{form[:score].value}" != "#{student_grades_report_entry.composition_score}" ->
          true

        true ->
          false
      end

    assign(socket, :has_manual_edit, has_manual_edit)
  end

  defp assign_has_normalized_value_edit(socket) do
    %{
      form: form,
      student_grades_report_entry: student_grades_report_entry
    } = socket.assigns

    has_normalized_value_edit =
      case form[:normalized_value].value do
        form_normalized_value when is_float(form_normalized_value) ->
          Float.round(form_normalized_value, 5) !=
            Float.round(student_grades_report_entry.composition_normalized_value, 5)

        "" ->
          true

        form_normalized_value when is_binary(form_normalized_value) ->
          Float.round(String.to_float(form_normalized_value), 5) !=
            Float.round(student_grades_report_entry.composition_normalized_value, 5)
      end

    assign(socket, :has_normalized_value_edit, has_normalized_value_edit)
  end

  defp assign_has_retake_history(%{assigns: %{scale_type: scale_type}} = socket, changeset) do
    pre_retake_ordinal_value_id =
      Ecto.Changeset.get_field(changeset, :pre_retake_ordinal_value_id)

    pre_retake_score = Ecto.Changeset.get_field(changeset, :pre_retake_score)

    has_retake_history =
      case {scale_type, pre_retake_ordinal_value_id, pre_retake_score} do
        {"ordinal", nil, _} -> false
        {"ordinal", _, _} -> true
        {"numeric", _, nil} -> false
        {"numeric", _, _} -> true
      end

    assign(socket, :has_retake_history, has_retake_history)
  end

  @impl true
  def handle_event(
        "validate",
        %{"student_grades_report_entry" => student_grades_report_entry_params},
        socket
      ) do
    changeset =
      socket.assigns.student_grades_report_entry
      |> GradesReports.change_student_grades_report_entry(student_grades_report_entry_params)
      |> Map.put(:action, :validate)

    socket =
      socket
      |> assign_form(changeset)
      |> assign_has_manual_edit()
      |> assign_has_normalized_value_edit()
      |> assign_has_retake_history(changeset)

    {:noreply, socket}
  end

  def handle_event(
        "save",
        %{"student_grades_report_entry" => student_grades_report_entry_params},
        socket
      ) do
    save_student_grades_report_entry(
      socket,
      socket.assigns.student_grades_report_entry.id,
      student_grades_report_entry_params
    )
  end

  defp save_student_grades_report_entry(socket, nil, student_grades_report_entry_params) do
    case GradesReports.create_student_grades_report_entry(student_grades_report_entry_params) do
      {:ok, student_grades_report_entry} ->
        notify_parent(__MODULE__, {:saved, student_grades_report_entry}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Student grade report entry created successfully"))
          |> handle_navigation(student_grades_report_entry)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_student_grades_report_entry(
         socket,
         _student_grades_report_entry_id,
         student_grades_report_entry_params
       ) do
    case GradesReports.update_student_grades_report_entry(
           socket.assigns.student_grades_report_entry,
           student_grades_report_entry_params
         ) do
      {:ok, student_grades_report_entry} ->
        notify_parent(__MODULE__, {:saved, student_grades_report_entry}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Student grade report entry updated successfully"))
          |> handle_navigation(student_grades_report_entry)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
