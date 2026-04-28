defmodule LantternWeb.StrandLive.OverviewComponent do
  use LantternWeb, :live_component

  alias Lanttern.Reporting

  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]

  # shared components
  import LantternWeb.ReportingComponents, only: [report_card_card: 1]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-4">
      <.cover_image
        image_url={@cover_image_url}
        alt_text={gettext("Strand cover image")}
        empty_state_text={gettext("Edit strand to add a cover image")}
      />
      <.responsive_container class="mt-10">
        <hgroup>
          <h1 class="font-display font-black text-ltrn-darkest text-4xl sm:text-5xl">
            {@strand.name}
          </h1>
          <p :if={@strand.type} class="mt-2 font-bold text-xl sm:text-2xl">{@strand.type}</p>
        </hgroup>
        <div class="flex flex-wrap gap-2 mt-6">
          <.badge :for={subject <- @strand.subjects} theme="dark">
            {Gettext.dgettext(Lanttern.Gettext, "taxonomy", subject.name)}
          </.badge>
          <.badge :for={year <- @strand.years} theme="dark">
            {Gettext.dgettext(Lanttern.Gettext, "taxonomy", year.name)}
          </.badge>
        </div>
        <.markdown text={@strand.description} class="mt-10" />
        <div
          :if={@strand.teacher_instructions}
          class="p-4 rounded-xs mt-10 bg-ltrn-staff-lightest"
        >
          <p class="mb-4 font-bold text-ltrn-staff-dark">
            {gettext("Teacher instructions")}
          </p>
          <.markdown text={@strand.teacher_instructions} />
        </div>
      </.responsive_container>
      <.responsive_container class="mt-16">
        <h3 class="font-display font-black text-3xl">{gettext("Report cards")}</h3>
        <p class="flex gap-1 mt-4">
          {gettext("List of report cards linked to this strand.")}
        </p>
      </.responsive_container>
      <%= if @has_report_cards do %>
        <.responsive_grid id="report-cards" phx-update="stream" class="px-6 py-10 sm:px-10">
          <.report_card_card
            :for={{dom_id, report_card} <- @streams.report_cards}
            id={dom_id}
            report_card={report_card}
            navigate={~p"/report_cards/#{report_card}"}
          />
        </.responsive_grid>
      <% else %>
        <.empty_state class="mt-10">
          {gettext("No report cards linked to this strand")}
        </.empty_state>
      <% end %>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :initialized, false)}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_cover_image_url()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> stream_report_cards()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_report_cards(socket) do
    report_cards =
      Reporting.list_report_cards(
        preloads: :school_cycle,
        strands_ids: [socket.assigns.strand.id],
        school_id: socket.assigns.current_user.current_profile.school_id
      )

    socket
    |> stream(:report_cards, report_cards)
    |> assign(:has_report_cards, report_cards != [])
  end

  defp assign_cover_image_url(socket) do
    assign(
      socket,
      :cover_image_url,
      object_url_to_render_url(socket.assigns.strand.cover_image_url, width: 1280, height: 640)
    )
  end
end
