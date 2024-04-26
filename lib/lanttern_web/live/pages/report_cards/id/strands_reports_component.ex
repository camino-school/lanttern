defmodule LantternWeb.ReportCardLive.StrandsReportsComponent do
  alias Lanttern.LearningContext
  use LantternWeb, :live_component

  alias Lanttern.Reporting
  alias Lanttern.Reporting.StrandReport

  import Lanttern.Utils, only: [swap: 3]

  # shared components
  alias LantternWeb.LearningContext.StrandSearchComponent
  alias LantternWeb.Reporting.StrandReportFormComponent
  import LantternWeb.LearningContextComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.responsive_container>
        <div class="flex items-end justify-between mb-4">
          <h3 class="font-display font-bold text-lg">
            <%= gettext("Strands linked to report") %>
          </h3>
          <div class="shrink-0 flex items-center gap-6">
            <.collection_action
              type="link"
              patch={~p"/report_cards/#{@report_card}?tab=strands&is_reordering=true"}
              icon_name="hero-arrows-up-down"
            >
              <%= gettext("Reorder") %>
            </.collection_action>
            <.collection_action
              type="link"
              patch={~p"/report_cards/#{@report_card}?tab=strands&is_creating_strand_report=true"}
              icon_name="hero-plus-circle"
            >
              <%= gettext("Link strand") %>
            </.collection_action>
          </div>
        </div>
      </.responsive_container>
      <%= if @has_strands_reports do %>
        <.responsive_grid id="strands-reports-grid" phx-update="stream">
          <.strand_card
            :for={{dom_id, strand_report} <- @streams.strands_reports}
            id={dom_id}
            strand={strand_report.strand}
            cover_image_url={strand_report.cover_image_url}
            navigate={~p"/strands/#{strand_report.strand}?tab=reporting"}
            open_in_new
            hide_description
            on_edit={
              JS.patch(
                ~p"/report_cards/#{@report_card}?tab=strands&is_editing_strand_report=#{strand_report.id}"
              )
            }
            class="shrink-0 w-64 sm:w-auto"
          />
        </.responsive_grid>
      <% else %>
        <.empty_state><%= gettext("No strands linked to this report yet") %></.empty_state>
      <% end %>
      <.slide_over
        :if={@show_strand_report_form}
        id="strand-report-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/report_cards/#{@report_card}?tab=strands")}
      >
        <:title><%= @form_overlay_title %></:title>
        <%= if @strand do %>
          <div class="flex items-center gap-4 p-4 mb-6 rounded font-display bg-white shadow-lg">
            <div class="flex-1">
              <p class="font-black"><%= @strand.name %></p>
              <p :if={@strand.type} class="text-sm text-ltrn-subtle"><%= @strand.type %></p>
              <div class="flex flex-wrap gap-1 mt-4">
                <.badge :for={subject <- @strand.subjects}><%= subject.name %></.badge>
                <.badge :for={year <- @strand.years}><%= year.name %></.badge>
              </div>
            </div>
            <button
              :if={!@strand_report.id}
              type="button"
              class="shrink-0 block text-ltrn-subtle hover:text-ltrn-dark"
              phx-click="remove_strand"
              phx-target={@myself}
            >
              <.icon name="hero-x-circle" class="w-10 h-10" />
            </button>
          </div>
          <.live_component
            module={StrandReportFormComponent}
            id={@strand_report.id || :new}
            strand_report={@strand_report}
            navigate={~p"/report_cards/#{@report_card}?tab=strands"}
            hide_submit
          />
        <% else %>
          <p class="mb-2"><%= gettext("Which strand do you want to link to this report?") %></p>
          <.live_component
            module={StrandSearchComponent}
            id="strand-search"
            render_form
            selected_strands_ids={@selected_strands_ids}
            notify_component={@myself}
          />
        <% end %>
        <:actions_left :if={@strand && @strand_report.id}>
          <.button
            type="button"
            theme="ghost"
            phx-click="delete_strand_report"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
          >
            <%= gettext("Delete") %>
          </.button>
        </:actions_left>
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#strand-report-form-overlay")}
          >
            <%= gettext("Cancel") %>
          </.button>
          <.button type="submit" form="strand-report-form" disabled={!@strand}>
            <%= gettext("Save") %>
          </.button>
        </:actions>
      </.slide_over>
      <.slide_over
        :if={@is_reordering}
        id="strands-reports-reorder-overlay"
        show={true}
        on_cancel={JS.patch(~p"/report_cards/#{@report_card}?tab=strands")}
      >
        <:title><%= gettext("Reorder strands reports") %></:title>
        <ol>
          <li
            :for={{sortable_strand_report, i} <- @sortable_strands_reports}
            id={"sortable-strand-report-#{sortable_strand_report.id}"}
            class="mb-4"
          >
            <.sortable_card
              is_move_up_disabled={i == 0}
              on_move_up={
                JS.push("swap_strands_reports_position",
                  value: %{from: i, to: i - 1},
                  target: @myself
                )
              }
              is_move_down_disabled={i + 1 == length(@sortable_strands_reports)}
              on_move_down={
                JS.push("swap_strands_reports_position",
                  value: %{from: i, to: i + 1},
                  target: @myself
                )
              }
              class="font-display font-bold"
            >
              <p><%= i + 1 %>. <%= sortable_strand_report.name %></p>
              <p :if={sortable_strand_report.type} class="mt-2 text-sm text-ltrn-subtle">
                <%= sortable_strand_report.type %>
              </p>
            </.sortable_card>
          </li>
        </ol>
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#strands-reports-reorder-overlay")}
          >
            <%= gettext("Cancel") %>
          </.button>
          <.button type="button" phx-click="save_order" phx-target={@myself}>
            <%= gettext("Save") %>
          </.button>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  # lifecycle
  @impl true
  def update(%{action: {StrandSearchComponent, {:strand_selected, id}}}, socket) do
    strand = LearningContext.get_strand(id, preloads: [:subjects, :years])

    strand_report = %StrandReport{
      report_card_id: socket.assigns.report_card.id,
      strand_id: strand.id
    }

    socket =
      socket
      |> assign(:strand, strand)
      |> assign(:strand_report, strand_report)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_strands_reports(assigns)
      |> assign_show_strand_report_form(assigns)
      |> assign_is_reordering(assigns)

    {:ok, socket}
  end

  # fetch strands reports and assign only if the assigns do not exist
  # (something like assign_new, but for multiple assigns)
  defp assign_strands_reports(%{assigns: %{streams: %{strands_reports: _}}} = socket, _),
    do: socket

  defp assign_strands_reports(socket, assigns) do
    strands_reports =
      Reporting.list_strands_reports(
        report_card_id: assigns.report_card.id,
        preloads: [strand: [:subjects, :years]]
      )

    # map to keep data to a minimum
    sortable_strands_reports =
      strands_reports
      |> Enum.map(&%{id: &1.id, name: &1.strand.name, type: &1.strand.type})
      |> Enum.with_index()

    selected_strands_ids =
      strands_reports
      |> Enum.map(& &1.strand_id)

    socket
    |> assign(assigns)
    |> stream(:strands_reports, strands_reports)
    |> assign(:sortable_strands_reports, sortable_strands_reports)
    |> assign(:has_strands_reports, length(strands_reports) > 0)
    |> assign(:selected_strands_ids, selected_strands_ids)
  end

  defp assign_show_strand_report_form(socket, %{
         params: %{"is_creating_strand_report" => "true"}
       }) do
    socket
    |> assign(:strand, nil)
    |> assign(:form_overlay_title, gettext("Create strand report"))
    |> assign(:show_strand_report_form, true)
  end

  defp assign_show_strand_report_form(socket, %{
         params: %{"is_editing_strand_report" => id}
       }) do
    report_card_id = socket.assigns.report_card.id

    cond do
      String.match?(id, ~r/[0-9]+/) ->
        case Reporting.get_strand_report(id, preloads: [strand: [:subjects, :years]]) do
          %StrandReport{report_card_id: ^report_card_id} = strand_report ->
            strand = strand_report.strand

            socket
            |> assign(:form_overlay_title, gettext("Edit strand report"))
            |> assign(:strand_report, strand_report)
            |> assign(:strand, strand)
            |> assign(:show_strand_report_form, true)

          _ ->
            assign(socket, :show_strand_report_form, false)
        end

      true ->
        assign(socket, :show_strand_report_form, false)
    end
  end

  defp assign_show_strand_report_form(socket, _),
    do: assign(socket, :show_strand_report_form, false)

  defp assign_is_reordering(socket, %{params: %{"is_reordering" => "true"}}),
    do: assign(socket, :is_reordering, true)

  defp assign_is_reordering(socket, _),
    do: assign(socket, :is_reordering, false)

  # event handlers

  @impl true
  def handle_event("remove_strand", _, socket) do
    {:noreply, assign(socket, :strand, nil)}
  end

  def handle_event("delete_strand_report", _params, socket) do
    case Reporting.delete_strand_report(socket.assigns.strand_report) do
      {:ok, _strand_report} ->
        socket =
          socket
          |> put_flash(:info, gettext("Strand report deleted"))
          |> push_navigate(to: ~p"/report_cards/#{socket.assigns.report_card}?tab=strands")

        {:noreply, socket}

      {:error, _changeset} ->
        socket =
          socket
          |> put_flash(:error, gettext("Error deleting strand report"))

        {:noreply, socket}
    end
  end

  def handle_event("swap_strands_reports_position", %{"from" => i, "to" => j}, socket) do
    sortable_strands_reports =
      socket.assigns.sortable_strands_reports
      |> Enum.map(fn {sr, _i} -> sr end)
      |> swap(i, j)
      |> Enum.with_index()

    {:noreply, assign(socket, :sortable_strands_reports, sortable_strands_reports)}
  end

  def handle_event("save_order", _, socket) do
    strands_reports_ids =
      socket.assigns.sortable_strands_reports
      |> Enum.map(fn {sr, _i} -> sr.id end)

    case Reporting.update_strands_reports_positions(strands_reports_ids) do
      :ok ->
        report_card = socket.assigns.report_card
        {:noreply, push_navigate(socket, to: ~p"/report_cards/#{report_card}?tab=strands")}

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}
    end
  end
end
