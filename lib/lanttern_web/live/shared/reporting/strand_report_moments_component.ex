defmodule LantternWeb.Reporting.StrandReportMomentsComponent do
  @moduledoc """
  Renders moments info related to a `StrandReport`.

  ### Required attrs:

  -`strand_report` - `%StrandReport{}`
  -`student_id`
  -`student_report_card_id`
  -`params` - the URL params from parent view `handle_params/3`
  -`base_path` - the base URL path for overlay navigation control
  """

  alias Lanttern.LearningContext
  use LantternWeb, :live_component

  alias Lanttern.Reporting

  # shared components
  import LantternWeb.ReportingComponents
  import LantternWeb.AssessmentsComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.responsive_container>
        <p>
          <%= gettext("Here you'll find information about the strand learning journey.") %>
        </p>
        <p class="mt-4 mb-10">
          <%= gettext(
            "You can click the moment card to view more details about it, including information about formative assessment."
          ) %>
        </p>
        <%= if @has_moments do %>
          <div id="strand-moments-and-entries" phx-update="stream">
            <.link
              :for={{dom_id, {moment, entries}} <- @streams.moments_and_entries}
              id={dom_id}
              patch={"#{@base_path}&moment_id=#{moment.id}"}
              class="group block mt-4"
            >
              <.card_base class={[
                "flex flex-col group-hover:bg-ltrn-mesh-cyan",
                "md:flex-row md:items-center md:justify-between"
              ]}>
                <div class="p-4 md:p-6">
                  <h5 class="font-display font-black text-lg" title={moment.name}>
                    <%= moment.name %>
                  </h5>
                  <div :if={moment.subjects != []} class="flex gap-2 mt-2">
                    <.badge :for={subject <- moment.subjects}>
                      <%= Gettext.dgettext(LantternWeb.Gettext, "taxonomy", subject.name) %>
                    </.badge>
                  </div>
                </div>
                <div
                  :if={entries != []}
                  class="flex flex-wrap gap-2 p-4 border-t border-ltrn-lighter md:border-t-0 md:p-6"
                >
                  <%= for entry <- entries, entry.ordinal_value || entry.score do %>
                    <.assessment_point_entry_badge entry={entry} is_short />
                  <% end %>
                </div>
              </.card_base>
            </.link>
          </div>
        <% else %>
          <.empty_state>
            <%= gettext("No moments registered for this strand") %>
          </.empty_state>
        <% end %>
      </.responsive_container>
      <.slide_over :if={@moment} id="moment-overlay" show={true} on_cancel={JS.patch(@base_path)}>
        <:title><%= @moment.name %></:title>
        <div id="moment-assessment-points-and-entries">
          <.moment_assessment_point_entry
            :for={
              {dom_id, {assessment_point, entry}} <- @streams.moment_assessment_points_and_entries
            }
            id={dom_id}
            class="py-4 border-t border-ltrn-lighter"
            assessment_point={assessment_point}
            entry={entry}
          />
        </div>
      </.slide_over>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:moment, nil)
      |> assign(:initialized, false)
      |> stream_configure(
        :moments_and_entries,
        dom_id: fn
          {moment, _entries} -> "moment-#{moment.id}"
          _ -> ""
        end
      )
      |> stream_configure(
        :moment_assessment_points_and_entries,
        dom_id: fn
          {assessment_point, _entry} -> "assessment-point-#{assessment_point.id}"
          _ -> ""
        end
      )

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> stream_moments_and_entries(assigns)
      |> assign_moment(assigns)
      |> assign(:initialized, true)

    {:ok, socket}
  end

  defp stream_moments_and_entries(%{assigns: %{initialized: false}} = socket, assigns) do
    moments_and_entries =
      Reporting.list_student_strand_report_moments_and_entries(
        assigns.strand_report,
        assigns.student_id
      )

    moments_ids =
      moments_and_entries
      |> Enum.map(fn {moment, _entry} -> "#{moment.id}" end)

    socket
    |> assign(assigns)
    |> stream(:moments_and_entries, moments_and_entries)
    |> assign(:moments_ids, moments_ids)
    |> assign(:has_moments, moments_and_entries != [])
  end

  defp stream_moments_and_entries(socket, _assigns), do: socket

  defp assign_moment(socket, %{params: %{"moment_id" => moment_id}}) do
    # simple guard to prevent viewing details from unrelated moments
    moment =
      if moment_id in socket.assigns.moments_ids do
        LearningContext.get_moment(moment_id)
      end

    moment_assessment_points_and_entries =
      if moment do
        Reporting.list_moment_assessment_points_and_student_entries(
          moment.id,
          socket.assigns.student_id
        )
      end

    socket
    |> assign(:moment, moment)
    |> stream(:moment_assessment_points_and_entries, moment_assessment_points_and_entries)
  end

  defp assign_moment(socket, _assigns), do: assign(socket, :moment, nil)
end
