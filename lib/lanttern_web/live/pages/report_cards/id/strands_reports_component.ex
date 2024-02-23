defmodule LantternWeb.ReportCardLive.StrandsReportsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Reporting
  alias Lanttern.Reporting.StrandReport

  # shared components
  alias LantternWeb.Reporting.StrandReportFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container py-10 mx-auto lg:max-w-5xl">
      <div class="flex items-end justify-between mb-4">
        <h3 class="font-display font-bold text-lg">
          <%= gettext("Strands reports") %>
        </h3>
        <div class="shrink-0 flex items-center gap-6">
          <%!-- <.collection_action
            :if={@moments_count > 1}
            type="button"
            phx-click={JS.exec("data-show", to: "#strand-moments-order-overlay")}
            icon_name="hero-arrows-up-down"
          >
            <%= gettext("Reorder") %>
          </.collection_action> --%>
          <.collection_action
            type="button"
            phx-click="add_strand"
            phx-target={@myself}
            icon_name="hero-plus-circle"
          >
            <%= gettext("Add strand to report") %>
          </.collection_action>
        </div>
      </div>
      <%= if length(@report_card.strand_reports) == 0 do %>
        <.empty_state>No strands linked to this report yet</.empty_state>
      <% else %>
        <div
          :for={strand_report <- @report_card.strand_reports}
          id={"strand-report-#{strand_report.id}"}
        >
          <%= strand_report.strand.name %>
        </div>
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
    </div>
    """
  end

  # lifecycle
  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> stream(
        :strand_reports,
        Reporting.list_strand_reports(report_card_id: assigns.report_card.id)
      )

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

  # def handle_event("new_goal", _params, socket) do
  #   {:noreply,
  #    socket
  #    |> assign(:assessment_point, %AssessmentPoint{
  #      strand_id: socket.assigns.strand.id,
  #      datetime: DateTime.utc_now()
  #    })
  #    |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/goal/new")}
  # end

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

  # def handle_event("swap_goal_position", %{"from" => i, "to" => j}, socket) do
  #   curriculum_items =
  #     socket.assigns.curriculum_items
  #     |> Enum.map(fn {ap, _i} -> ap end)
  #     |> swap(i, j)
  #     |> Enum.with_index()

  #   {:noreply,
  #    socket
  #    |> assign(:curriculum_items, curriculum_items)
  #    |> assign(:has_goal_position_change, true)}
  # end

  # def handle_event("save_order", _, socket) do
  #   assessment_points_ids =
  #     socket.assigns.curriculum_items
  #     |> Enum.map(fn {ci, _i} -> ci.assessment_point_id end)

  #   case Assessments.update_assessment_points_positions(assessment_points_ids) do
  #     {:ok, _assessment_points} ->
  #       {:noreply, assign(socket, :has_goal_position_change, false)}

  #     {:error, msg} ->
  #       {:noreply, put_flash(socket, :error, msg)}
  #   end
  # end

  # # helpers

  # # https://elixirforum.com/t/swap-elements-in-a-list/34471/4
  # defp swap(a, i1, i2) do
  #   e1 = Enum.at(a, i1)
  #   e2 = Enum.at(a, i2)

  #   a
  #   |> List.replace_at(i1, e2)
  #   |> List.replace_at(i2, e1)
  # end
end
