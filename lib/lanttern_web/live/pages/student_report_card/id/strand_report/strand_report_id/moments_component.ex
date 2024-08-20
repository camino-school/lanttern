defmodule LantternWeb.StudentStrandReportLive.MomentsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Reporting

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-10">
      <.responsive_container>
        <h3 class="font-display font-black text-xl"><%= gettext("Strand moments") %></h3>
      </.responsive_container>
      <.responsive_grid id="strand-moments-and-entries" phx-update="stream">
        <.card_base
          :for={{dom_id, {moment, _entries}} <- @streams.moments_and_entries}
          id={dom_id}
          class="p-6"
        >
          <%= moment.name %>
        </.card_base>
      </.responsive_grid>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> stream_configure(
        :moments_and_entries,
        dom_id: fn
          {moment, _entries} -> "moment-#{moment.id}"
          _ -> ""
        end
      )

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    moments_and_entries =
      Reporting.list_student_strand_report_moments_and_entries(
        assigns.strand_report,
        assigns.student_id
      )

    socket =
      socket
      |> assign(assigns)
      |> stream(:moments_and_entries, moments_and_entries)

    {:ok, socket}
  end
end
