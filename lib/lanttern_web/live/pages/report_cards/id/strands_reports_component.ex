defmodule LantternWeb.ReportCardLive.StrandsReportsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Reporting
  alias Lanttern.Reporting.StrandReport

  import Lanttern.Utils, only: [swap: 3]

  # shared components
  alias LantternWeb.Reporting.StrandReportFormComponent
  import LantternWeb.LearningContextComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container py-10 mx-auto lg:max-w-5xl">
      <div class="flex items-end justify-between mb-4">
        <h3 class="font-display font-bold text-lg">
          <%= gettext("Strands linked to report") %>
        </h3>
        <div class="shrink-0 flex items-center gap-6">
          <.collection_action
            type="button"
            phx-click={JS.exec("data-show", to: "#strands-reports-reorder-overlay")}
            phx-target={@myself}
            icon_name="hero-arrows-up-down"
          >
            <%= gettext("Reorder") %>
          </.collection_action>
          <.collection_action
            type="button"
            phx-click="add_strand"
            phx-target={@myself}
            icon_name="hero-plus-circle"
          >
            <%= gettext("Link strand") %>
          </.collection_action>
        </div>
      </div>
      <%= if @has_strands_reports do %>
        <div id="strands-reports-grid" class="grid grid-cols-3 gap-10 mt-10" phx-update="stream">
          <.strand_card
            :for={{dom_id, strand_report} <- @streams.strands_reports}
            id={dom_id}
            strand={strand_report.strand}
            navigate={~p"/strands/#{strand_report.strand}?tab=reporting"}
            hide_description
          />
        </div>
      <% else %>
        <.empty_state><%= gettext("No strands linked to this report yet") %></.empty_state>
      <% end %>
      <.slide_over
        :if={@live_action == :edit_strand_report}
        id="strand-report-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/report_cards/#{@report_card}?tab=strands")}
      >
        <:title><%= gettext("Create strand report") %></:title>
        <.live_component
          module={StrandReportFormComponent}
          id={@strand_report.id || :new}
          strand_report={@strand_report}
          navigate={~p"/report_cards/#{@report_card}"}
          hide_submit
        />
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#strand-report-form-overlay")}
          >
            <%= gettext("Cancel") %>
          </.button>
          <.button type="submit" form="strand-report-form">
            <%= gettext("Save") %>
          </.button>
        </:actions>
      </.slide_over>
      <.slide_over id="strands-reports-reorder-overlay">
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
  def mount(socket) do
    {:ok, assign(socket, :is_reordering, false)}
  end

  @impl true
  def update(assigns, socket) do
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

    socket =
      socket
      |> assign(assigns)
      |> stream(:strands_reports, strands_reports)
      |> assign(:sortable_strands_reports, sortable_strands_reports)
      |> assign(:has_strands_reports, length(strands_reports) > 0)

    {:ok, socket}
  end

  # event handlers

  @impl true
  def handle_event("add_strand", _params, socket) do
    report_card = socket.assigns.report_card

    strand_report = %StrandReport{
      report_card_id: report_card.id
    }

    socket =
      socket
      |> assign(:strand_report, strand_report)
      |> push_patch(to: ~p"/report_cards/#{report_card}/edit_strand_report")

    {:noreply, socket}
  end

  # def handle_event("edit_goal", %{"id" => assessment_point_id}, socket) do
  #   assessment_point = Assessments.get_assessment_point(assessment_point_id)

  #   {:noreply,
  #    socket
  #    |> assign(:assessment_point, assessment_point)
  #    |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/goal/edit")}
  # end

  # def handle_event("delete_assessment_point", _params, socket) do
  #   case Assessments.delete_assessment_point(socket.assigns.assessment_point) do
  #     {:ok, _assessment_point} ->
  #       {:noreply,
  #        socket
  #        |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}?tab=about")}

  #     {:error, _changeset} ->
  #       # we may have more error types, but for now we are handling only this one
  #       message =
  #         gettext("This goal already have some entries. Deleting it will cause data loss.")

  #       {:noreply, socket |> assign(:delete_assessment_point_error, message)}
  #   end
  # end

  # def handle_event("delete_assessment_point_and_entries", _, socket) do
  #   case Assessments.delete_assessment_point_and_entries(socket.assigns.assessment_point) do
  #     {:ok, _} ->
  #       {:noreply,
  #        socket
  #        |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}?tab=about")}

  #     {:error, _} ->
  #       {:noreply, socket}
  #   end
  # end

  # def handle_event("dismiss_assessment_point_error", _, socket) do
  #   {:noreply,
  #    socket
  #    |> assign(:delete_assessment_point_error, nil)}
  # end

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
