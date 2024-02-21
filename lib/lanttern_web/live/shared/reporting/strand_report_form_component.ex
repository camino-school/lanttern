defmodule LantternWeb.Reporting.StrandReportFormComponent do
  use LantternWeb, :live_component

  alias Lanttern.Reporting

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form
        for={@form}
        id="strand-report-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:report_card_id]}
          type="number"
          label={gettext("Report card id")}
          class="mb-6"
        />
        <.input field={@form[:strand_id]} type="number" label={gettext("Strand id")} class="mb-6" />
        <.input field={@form[:position]} type="number" label={gettext("Position")} class="mb-6" />
        <.input
          field={@form[:description]}
          type="textarea"
          label={gettext("Description (optional)")}
          phx-debounce="1500"
          class="mb-1"
        />
        <.markdown_supported class={if !@hide_submit, do: "mb-6"} />
        <.button :if={!@hide_submit} type="submit" phx-disable-with={gettext("Saving...")}>
          <%= gettext("Save Strand report") %>
        </.button>
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
      |> assign(:hide_submit, false)

    {:ok, socket}
  end

  @impl true
  def update(%{strand_report: strand_report} = assigns, socket) do
    changeset = Reporting.change_strand_report(strand_report)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"strand_report" => strand_report_params}, socket) do
    changeset =
      socket.assigns.strand_report
      |> Reporting.change_strand_report(strand_report_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"strand_report" => strand_report_params}, socket) do
    save_strand_report(socket, socket.assigns.strand_report.id, strand_report_params)
  end

  defp save_strand_report(socket, nil, strand_report_params) do
    case Reporting.create_strand_report(strand_report_params) do
      {:ok, strand_report} ->
        notify_parent(__MODULE__, {:saved, strand_report}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, "Strand report created successfully")
          |> handle_navigation(strand_report)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_strand_report(socket, _strand_report_id, strand_report_params) do
    case Reporting.update_strand_report(socket.assigns.strand_report, strand_report_params) do
      {:ok, strand_report} ->
        notify_parent(__MODULE__, {:saved, strand_report}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, "Strand report updated successfully")
          |> handle_navigation(strand_report)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
