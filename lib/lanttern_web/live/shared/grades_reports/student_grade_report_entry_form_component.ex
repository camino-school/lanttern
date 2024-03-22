defmodule LantternWeb.GradesReports.StudentGradeReportEntryFormComponent do
  use LantternWeb, :live_component

  alias Lanttern.GradesReports

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
        <.input
          field={@form[:comment]}
          type="textarea"
          label={gettext("Comment")}
          phx-debounce="1500"
          class="mb-1"
          show_optional
        />
        <.markdown_supported class={if !@hide_submit, do: "mb-6"} />
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
  def update(%{student_grade_report_entry: student_grade_report_entry} = assigns, socket) do
    changeset = GradesReports.change_student_grade_report_entry(student_grade_report_entry)

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "validate",
        %{"student_grade_report_entry" => student_grade_report_entry_params},
        socket
      ) do
    changeset =
      socket.assigns.student_grade_report_entry
      |> GradesReports.change_student_grade_report_entry(student_grade_report_entry_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event(
        "save",
        %{"student_grade_report_entry" => student_grade_report_entry_params},
        socket
      ) do
    save_student_grade_report_entry(
      socket,
      socket.assigns.student_grade_report_entry.id,
      student_grade_report_entry_params
    )
  end

  defp save_student_grade_report_entry(socket, nil, student_grade_report_entry_params) do
    case GradesReports.create_student_grade_report_entry(student_grade_report_entry_params) do
      {:ok, student_grade_report_entry} ->
        notify_parent(__MODULE__, {:saved, student_grade_report_entry}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Student grade report entry created successfully"))
          |> handle_navigation(student_grade_report_entry)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_student_grade_report_entry(
         socket,
         _student_grade_report_entry_id,
         student_grade_report_entry_params
       ) do
    case GradesReports.update_student_grade_report_entry(
           socket.assigns.student_grade_report_entry,
           student_grade_report_entry_params
         ) do
      {:ok, student_grade_report_entry} ->
        notify_parent(__MODULE__, {:saved, student_grade_report_entry}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, gettext("Student grade report entry updated successfully"))
          |> handle_navigation(student_grade_report_entry)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
