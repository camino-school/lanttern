defmodule LantternWeb.StrandLive.ReportingComponent do
  use LantternWeb, :live_component

  alias Lanttern.Reporting

  # shared components
  import LantternWeb.ReportingComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container py-10 mx-auto lg:max-w-5xl">
      <%!-- <.markdown text={@strand.description} /> --%>
      <div class="flex items-end justify-between gap-6">
        <h3 class="mt-16 font-display font-black text-3xl"><%= gettext("Report cards") %></h3>
        <.collection_action
          type="button"
          icon_name="hero-plus-circle"
          phx-click="add_to_report"
          phx-target={@myself}
        >
          <%= gettext("Add to report card") %>
        </.collection_action>
      </div>
      <p class="mt-4">
        <%= gettext("List of report cards linked to this strand.") %>
      </p>
      <div id={@id} phx-update="stream" class="grid grid-cols-3 gap-10 mt-12">
        <.report_card_card
          :for={{dom_id, report_card} <- @streams.report_cards}
          id={dom_id}
          report_card={report_card}
          navigate={~p"/reporting/#{report_card}"}
        />
      </div>
    </div>
    """
  end

  # lifecycle

  # @impl true
  # def mount(socket) do
  #   {:ok,
  #    socket
  #    |> assign(:delete_assessment_point_error, nil)
  #    |> assign(:has_goal_position_change, false)}
  # end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> stream(
        :report_cards,
        Reporting.list_report_cards(preloads: :school_cycle, strands_ids: [assigns.strand.id])
      )

    {:ok, socket}
  end

  # event handlers

  @impl true
  def handle_event("add_to_report", _params, socket) do
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
