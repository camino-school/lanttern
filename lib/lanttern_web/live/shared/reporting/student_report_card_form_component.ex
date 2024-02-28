defmodule LantternWeb.Reporting.StudentReportCardFormComponent do
  use LantternWeb, :live_component

  alias Lanttern.Reporting

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form
        for={@form}
        id="student-report-card-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          :if={@is_admin}
          field={@form[:report_card_id]}
          type="number"
          label="Report card id"
          class="mb-6"
        />
        <.input
          :if={@is_admin}
          field={@form[:student_id]}
          type="number"
          label="Student id"
          class="mb-6"
        />
        <.input field={@form[:comment]} type="textarea" label="Comment" class="mb-1" show_optional />
        <.markdown_supported class="mb-6" />
        <.input field={@form[:footnote]} type="textarea" label="Footnote" class="mb-1" show_optional />
        <.markdown_supported class={if !@hide_submit, do: "mb-6"} />
        <.button :if={!@hide_submit} phx-disable-with="Saving...">Save Student report card</.button>
      </.form>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:is_admin, false)
      |> assign(:hide_submit, false)

    {:ok, socket}
  end

  @impl true
  def update(%{student_report_card: student_report_card} = assigns, socket) do
    changeset = Reporting.change_student_report_card(student_report_card)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"student_report_card" => student_report_card_params}, socket) do
    changeset =
      socket.assigns.student_report_card
      |> Reporting.change_student_report_card(student_report_card_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"student_report_card" => student_report_card_params}, socket) do
    student_report_card_params =
      case socket.assigns.is_admin do
        true ->
          student_report_card_params

        false ->
          student_report_card_params
          |> Map.put("id", socket.assigns.student_report_card.id)
          |> Map.put("report_card_id", socket.assigns.student_report_card.report_card_id)
          |> Map.put("student_id", socket.assigns.student_report_card.student_id)
      end

    save_student_report_card(
      socket,
      socket.assigns.student_report_card.id,
      student_report_card_params
    )
  end

  defp save_student_report_card(socket, nil, student_report_card_params) do
    case Reporting.create_student_report_card(student_report_card_params) do
      {:ok, student_report_card} ->
        notify_parent(__MODULE__, {:saved, student_report_card}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, "Student report card created successfully")
          |> handle_navigation(student_report_card)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_student_report_card(socket, _student_report_card_id, student_report_card_params) do
    case Reporting.update_student_report_card(
           socket.assigns.student_report_card,
           student_report_card_params
         ) do
      {:ok, student_report_card} ->
        notify_parent(__MODULE__, {:saved, student_report_card}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, "Student report card updated successfully")
          |> handle_navigation(student_report_card)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
