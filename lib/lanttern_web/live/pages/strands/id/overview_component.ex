defmodule LantternWeb.StrandLive.OverviewComponent do
  use LantternWeb, :live_component

  alias Lanttern.Reporting
  alias Lanttern.Strands

  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]
  import Lanttern.Utils, only: [reorder: 3]

  # shared components
  alias LantternWeb.Curricula.CurriculumItemSearchComponent
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
        <div class="flex items-end justify-between gap-6 mt-16">
          <h3 class="font-display font-black text-3xl">{gettext("Strand Curriculum")}</h3>
          <.button
            type="button"
            id="new-curriculum-item-button"
            phx-click={JS.push("new_curriculum_item", target: @myself)}
          >
            {gettext("New")}
          </.button>
        </div>
        <div
          :if={@curriculum_item_ids != []}
          phx-hook="Sortable"
          id="sortable-strand-curriculum-items"
          data-sortable-handle=".sortable-handle"
          data-sortable-event="sortable_update"
          phx-update="stream"
          phx-target={@myself}
        >
          <.draggable_card
            :for={{dom_id, sci} <- @streams.curriculum_items}
            class="mt-4"
            id={dom_id}
          >
            <div class="flex items-center gap-4">
              <div class="flex-1 min-w-0">
                <p>{sci.curriculum_item.name}</p>
                <p class="mt-2 font-sans text-sm text-ltrn-subtle truncate">
                  {sci.curriculum_item.curriculum_component.name}
                </p>
              </div>
              <div class="relative shrink-0">
                <.button type="button" theme="ghost" size="sm" id={"#{dom_id}-edit-button"}>
                  {gettext("Edit")}
                </.button>
                <.dropdown_menu
                  id={"#{dom_id}-edit"}
                  button_id={"#{dom_id}-edit-button"}
                  position="right"
                >
                  <:item
                    on_click={
                      JS.push("replace_curriculum_item", value: %{id: sci.id}, target: @myself)
                    }
                    text={gettext("Replace")}
                  />
                  <:item
                    on_click={
                      JS.push("remove_curriculum_item", value: %{id: sci.id}, target: @myself)
                    }
                    text={gettext("Remove")}
                    theme="alert"
                    confirm_msg={gettext("Are you sure?")}
                  />
                </.dropdown_menu>
              </div>
            </div>
          </.draggable_card>
        </div>
        <.empty_state :if={@curriculum_item_ids == []} class="mt-10">
          {gettext("No curriculum items linked to this strand")}
        </.empty_state>
      </.responsive_container>
      <.modal
        :if={@show_search_modal}
        id="curriculum-item-search-modal"
        show={true}
        on_cancel={JS.push("close_search_modal", target: @myself)}
      >
        <:title>{gettext("Add curriculum item")}</:title>
        <form>
          <.live_component
            module={CurriculumItemSearchComponent}
            id="curriculum-item-search"
            current_scope={@current_scope}
            notify_component={@myself}
          />
        </form>
        <.error_block :if={@curriculum_error} class="mt-6">
          <p>{@curriculum_error}</p>
        </.error_block>
      </.modal>
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
    socket =
      socket
      |> assign(:initialized, false)
      |> assign(:show_search_modal, false)
      |> assign(:editing_strand_curriculum_item, nil)
      |> assign(:curriculum_error, nil)

    {:ok, socket}
  end

  @impl true
  def update(
        %{action: {CurriculumItemSearchComponent, {:selected, curriculum_item}}},
        socket
      ) do
    socket = assign(socket, :curriculum_error, nil)

    socket =
      case socket.assigns.editing_strand_curriculum_item do
        nil ->
          attrs = %{
            strand_id: socket.assigns.strand.id,
            curriculum_item_id: curriculum_item.id
          }

          case Strands.create_strand_curriculum_item(socket.assigns.current_scope, attrs) do
            {:ok, sci} ->
              sci = Map.put(sci, :curriculum_item, curriculum_item)

              socket
              |> stream_insert(:curriculum_items, sci)
              |> update(:curriculum_item_ids, &(&1 ++ [sci.id]))
              |> assign(show_search_modal: false, editing_strand_curriculum_item: nil)

            {:error, changeset} ->
              assign(socket, :curriculum_error, changeset_error_string(changeset))
          end

        sci ->
          attrs = %{curriculum_item_id: curriculum_item.id}

          case Strands.update_strand_curriculum_item(socket.assigns.current_scope, sci, attrs) do
            {:ok, updated} ->
              updated = Map.put(updated, :curriculum_item, curriculum_item)

              socket
              |> stream_insert(:curriculum_items, updated)
              |> assign(show_search_modal: false, editing_strand_curriculum_item: nil)

            {:error, changeset} ->
              assign(socket, :curriculum_error, changeset_error_string(changeset))
          end
      end

    {:ok, socket}
  end

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
    |> stream_curriculum_items()
    |> stream_report_cards()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_curriculum_items(socket) do
    curriculum_items =
      Strands.list_strand_curriculum_items(
        socket.assigns.current_scope,
        socket.assigns.strand.id,
        preloads: [curriculum_item: :curriculum_component]
      )

    socket
    |> stream(:curriculum_items, curriculum_items)
    |> assign(:curriculum_item_ids, Enum.map(curriculum_items, & &1.id))
  end

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

  # event handlers

  @impl true
  def handle_event("new_curriculum_item", _params, socket) do
    socket =
      socket
      |> assign(:show_search_modal, true)
      |> assign(:editing_strand_curriculum_item, nil)
      |> assign(:curriculum_error, nil)

    {:noreply, socket}
  end

  def handle_event("replace_curriculum_item", %{"id" => id}, socket) do
    sci = Strands.get_strand_curriculum_item!(socket.assigns.current_scope, id)

    socket =
      socket
      |> assign(:show_search_modal, true)
      |> assign(:editing_strand_curriculum_item, sci)
      |> assign(:curriculum_error, nil)

    {:noreply, socket}
  end

  def handle_event("remove_curriculum_item", %{"id" => id}, socket) do
    sci = Strands.get_strand_curriculum_item!(socket.assigns.current_scope, id)
    {:ok, _} = Strands.delete_strand_curriculum_item(socket.assigns.current_scope, sci)

    socket =
      socket
      |> stream_delete(:curriculum_items, sci)
      |> update(:curriculum_item_ids, &List.delete(&1, sci.id))

    {:noreply, socket}
  end

  def handle_event("close_search_modal", _params, socket) do
    {:noreply, assign(socket, show_search_modal: false, editing_strand_curriculum_item: nil)}
  end

  def handle_event("sortable_update", payload, socket) do
    %{"oldIndex" => old_index, "newIndex" => new_index} = payload

    curriculum_item_ids = reorder(socket.assigns.curriculum_item_ids, old_index, new_index)
    Strands.update_strand_curriculum_items_positions(curriculum_item_ids)

    {:noreply, assign(socket, :curriculum_item_ids, curriculum_item_ids)}
  end
end
