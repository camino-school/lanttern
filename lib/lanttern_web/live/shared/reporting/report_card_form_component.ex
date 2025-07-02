defmodule LantternWeb.Reporting.ReportCardFormComponent do
  @moduledoc """
  Renders a `ReportCard` form
  """

  use LantternWeb, :live_component

  alias Lanttern.Reporting
  alias Lanttern.SupabaseHelpers
  alias LantternWeb.GradesReportsHelpers
  alias LantternWeb.SchoolsHelpers
  alias LantternWeb.TaxonomyHelpers

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
        <.image_field
          current_image_url={@report_card.cover_image_url}
          is_removing={@is_removing_cover}
          upload={@uploads.cover}
          on_cancel_replace={JS.push("cancel-replace-cover", target: @myself)}
          on_cancel_upload={JS.push("cancel-upload", target: @myself)}
          on_replace={JS.push("replace-cover", target: @myself)}
          class="mb-6"
        />
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
          field={@form[:year_id]}
          type="select"
          label={gettext("Year")}
          options={@year_options}
          prompt={gettext("Select year")}
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
          label={gettext("Description")}
          show_optional
          phx-debounce="1500"
          class="mb-1"
        />
        <.markdown_supported class="mb-6" />
        <.input
          field={@form[:grading_info]}
          type="textarea"
          label={gettext("About grades")}
          show_optional
          phx-debounce="1500"
          class="mb-1"
        />
        <.markdown_supported class="mb-6" />
        <.input
          field={@form[:grades_report_id]}
          type="select"
          label={gettext("Grades report")}
          options={@grades_report_options}
          prompt={gettext("Select grades report")}
          phx-target={@myself}
          class={if !@hide_submit, do: "mb-6"}
        />
        <.button :if={!@hide_submit} phx-disable-with={gettext("Saving...")}>
          <%= gettext("Save Report card") %>
        </.button>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    year_options = TaxonomyHelpers.generate_year_options()

    socket =
      socket
      |> assign(:class, nil)
      |> assign(:year_options, year_options)
      |> assign(:parent_cycle_id, nil)
      |> assign(:hide_submit, false)
      |> assign(:is_removing_cover, false)
      |> allow_upload(:cover,
        accept: ~w(.jpg .jpeg .png .webp),
        max_file_size: 5_000_000,
        max_entries: 1
      )
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    changeset = Reporting.change_report_card(socket.assigns.report_card)

    socket
    |> assign_cycle_options()
    |> assign_grades_report_options()
    |> assign_form(changeset)
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_cycle_options(socket) do
    opts = [subcycles_only: true]

    opts =
      case socket.assigns.parent_cycle_id do
        parent_cycle_id when is_integer(parent_cycle_id) ->
          [{:subcycles_of_parent_id, parent_cycle_id} | opts]

        _ ->
          opts
      end

    cycle_options = SchoolsHelpers.generate_cycle_options(opts)
    assign(socket, :cycle_options, cycle_options)
  end

  defp assign_grades_report_options(socket) do
    opts =
      case socket.assigns.parent_cycle_id do
        parent_cycle_id when is_integer(parent_cycle_id) -> [school_cycle_id: parent_cycle_id]
        _ -> []
      end

    grades_report_options = GradesReportsHelpers.generate_grades_report_options(opts)
    assign(socket, :grades_report_options, grades_report_options)
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :cover, ref)}
  end

  def handle_event("replace-cover", _, socket) do
    {:noreply, assign(socket, :is_removing_cover, true)}
  end

  def handle_event("cancel-replace-cover", _, socket) do
    {:noreply, assign(socket, :is_removing_cover, false)}
  end

  def handle_event("validate", %{"report_card" => report_card_params}, socket) do
    changeset =
      socket.assigns.report_card
      |> Reporting.change_report_card(report_card_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"report_card" => report_card_params}, socket) do
    cover_image_url =
      consume_uploaded_entries(socket, :cover, fn %{path: file_path}, entry ->
        {:ok, object} =
          SupabaseHelpers.upload_object(
            "covers",
            entry.client_name,
            file_path,
            %{content_type: entry.client_type}
          )

        image_url =
          "#{SupabaseHelpers.config().base_url}/storage/v1/object/public/#{URI.encode(object.key)}"

        {:ok, image_url}
      end)
      |> case do
        [] -> nil
        [image_url] -> image_url
      end

    # besides "consumed" cover image, we should also consider is_removing_cover flag
    cover_image_url =
      cond do
        cover_image_url -> cover_image_url
        socket.assigns.is_removing_cover -> nil
        true -> socket.assigns.report_card.cover_image_url
      end

    # add cover to params
    report_card_params = Map.put(report_card_params, "cover_image_url", cover_image_url)

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
