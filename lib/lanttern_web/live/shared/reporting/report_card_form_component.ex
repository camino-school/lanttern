defmodule LantternWeb.Reporting.ReportCardFormComponent do
  use LantternWeb, :live_component

  alias Lanttern.Reporting
  alias LantternWeb.SchoolsHelpers

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form
        for={@form}
        id="report-card-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:school_cycle_id]}
          type="select"
          label={gettext("Cycle")}
          options={@cycle_options}
          prompt={gettext("Select cycle")}
          phx-target={@myself}
          class="mb-6"
        />
        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Name")}
          class="mb-6"
          phx-debounce="1500"
        />
        <.input
          field={@form[:description]}
          type="textarea"
          label={gettext("Description (optional)")}
          phx-debounce="1500"
          class="mb-1"
        />
        <.markdown_supported class={if !@hide_submit, do: "mb-6"} />
        <.button :if={!@hide_submit} phx-disable-with={gettext("Saving...")}>
          <%= gettext("Save Report card") %>
        </.button>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    cycle_options = SchoolsHelpers.generate_cycle_options()

    socket =
      socket
      |> assign(:class, nil)
      |> assign(:cycle_options, cycle_options)
      |> assign(:hide_submit, false)

    {:ok, socket}
  end

  @impl true
  def update(%{report_card: report_card} = assigns, socket) do
    changeset = Reporting.change_report_card(report_card)

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"report_card" => report_card_params}, socket) do
    changeset =
      socket.assigns.report_card
      |> Reporting.change_report_card(report_card_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"report_card" => report_card_params}, socket) do
    save_report_card(socket, socket.assigns.report_card.id, report_card_params)
  end

  defp save_report_card(socket, nil, report_card_params) do
    case Reporting.create_report_card(report_card_params) do
      {:ok, report_card} ->
        notify_parent(__MODULE__, {:saved, report_card}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, "Report card created successfully")
          |> handle_navigation(report_card)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_report_card(socket, _report_card_id, report_card_params) do
    case Reporting.update_report_card(socket.assigns.report_card, report_card_params) do
      {:ok, report_card} ->
        notify_parent(__MODULE__, {:saved, report_card}, socket.assigns)

        socket =
          socket
          |> put_flash(:info, "Report card updated successfully")
          |> handle_navigation(report_card)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
