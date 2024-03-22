defmodule LantternWeb.GradesReports.StudentGradeReportEntryFormComponent do
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
        <.input
          :if={@scale_type == "ordinal"}
          field={@form[:ordinal_value_id]}
          type="select"
          label={gettext("Level")}
          options={@ordinal_value_options}
          prompt={gettext("Select a level")}
          class="mb-6"
        />
        <.input
          :if={@scale_type == "numeric"}
          field={@form[:score]}
          type="number"
          label={gettext("Score")}
          class="mb-6"
        />
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
  def update(assigns, socket) do
    %{
      student_grade_report_entry: student_grade_report_entry,
      scale_id: scale_id
    } = assigns

    changeset = GradesReports.change_student_grade_report_entry(student_grade_report_entry)

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
