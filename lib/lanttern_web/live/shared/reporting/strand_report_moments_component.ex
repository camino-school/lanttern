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
  alias LantternWeb.Assessments.EntryParticleComponent
  import LantternWeb.AttachmentsComponents
  import LantternWeb.ReportingComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.responsive_container>
        <h2 class="font-display font-black text-2xl"><%= gettext("Strand moments") %></h2>
        <p class="mt-4">
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
                      <%= Gettext.dgettext(Lanttern.Gettext, "taxonomy", subject.name) %>
                    </.badge>
                  </div>
                  <.markdown
                    :if={moment.description}
                    text={moment.description}
                    class="mt-2 line-clamp-4"
                  />
                </div>
                <div
                  :if={entries != []}
                  class="flex flex-wrap gap-2 p-4 border-t border-ltrn-lighter md:border-t-0 md:p-6"
                >
                  <%= for entry <- entries, entry.ordinal_value_id || entry.score do %>
                    <%!-- <.assessment_point_entry_badge entry={entry} is_short /> --%>
                    <.live_component module={EntryParticleComponent} id={entry.id} entry={entry} />
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
        <.markdown :if={@moment.description} text={@moment.description} class="mb-10" />
        <h4 class="mb-4 font-display font-black text-lg text-ltrn-subtle">
          <%= gettext("Moment assessment") %>
        </h4>
        <%= if @moment_has_assessment_points do %>
          <div class="mb-10">
            <div id="moment-assessment-points-and-entries" phx-update="stream">
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
          </div>
        <% else %>
          <.empty_state_simple class="mb-10">
            <%= gettext("This moment does not have assessment entries yet") %>
          </.empty_state_simple>
        <% end %>
        <div :if={@moment_has_cards}>
          <h4 class="mb-4 font-display font-black text-lg text-ltrn-subtle">
            <%= gettext("More about this moment") %>
          </h4>
          <div id="moment-cards" phx-update="stream">
            <div :for={{dom_id, card} <- @streams.moment_cards} id={dom_id} class="py-6 border-t">
              <h5 class="font-display font-black text-base mb-4">
                <%= card.name %>
              </h5>
              <.markdown text={card.description} />
              <.attachments_list attachments={card.attachments} />
            </div>
          </div>
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
      |> initialize()
      |> assign_moment(assigns)

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> stream_moments_and_entries()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_moments_and_entries(socket) do
    moments_and_entries =
      Reporting.list_student_strand_report_moments_and_entries(
        socket.assigns.strand_report,
        socket.assigns.student_id
      )

    moments_ids =
      moments_and_entries
      |> Enum.map(fn {moment, _entry} -> "#{moment.id}" end)

    socket
    |> stream(:moments_and_entries, moments_and_entries)
    |> assign(:moments_ids, moments_ids)
    |> assign(:has_moments, moments_and_entries != [])
  end

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

    moment_cards =
      if moment do
        Reporting.list_moment_cards_and_attachments_shared_with_students(moment.id)
      end

    socket
    |> assign(:moment, moment)
    |> stream(:moment_assessment_points_and_entries, moment_assessment_points_and_entries)
    |> assign(:moment_has_assessment_points, moment_assessment_points_and_entries != [])
    |> stream(:moment_cards, moment_cards)
    |> assign(:moment_has_cards, moment_cards != [])
  end

  defp assign_moment(socket, _assigns), do: assign(socket, :moment, nil)
end
