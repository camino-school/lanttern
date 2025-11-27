defmodule LantternWeb.StrandLive.LessonsComponent do
  use LantternWeb, :live_component

  alias Lanttern.LearningContext
  alias Lanttern.LearningContext.Moment

  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]
  import Lanttern.Utils, only: [reorder: 3]

  # shared components
  alias LantternWeb.LearningContext.MomentFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-4">
      <.responsive_container class="pb-10">
        <.cover_image
          image_url={@cover_image_url}
          alt_text={gettext("Strand cover image")}
          empty_state_text={gettext("Edit strand to add a cover image")}
          size="sm"
        />
        <hgroup class="mt-10 font-display font-black">
          <h1 class="text-4xl sm:text-5xl">{@strand.name}</h1>
          <p :if={@strand.type} class="mt-2 text-xl sm:text-2xl">{@strand.type}</p>
        </hgroup>
        <div class="flex flex-wrap gap-2 mt-6">
          <.badge :for={subject <- @strand.subjects} theme="dark">
            {Gettext.dgettext(Lanttern.Gettext, "taxonomy", subject.name)}
          </.badge>
          <.badge :for={year <- @strand.years} theme="dark">
            {Gettext.dgettext(Lanttern.Gettext, "taxonomy", year.name)}
          </.badge>
        </div>
        <.markdown text={@strand.description} class="mt-10 line-clamp-3" strip_tags />
        <.button type="link" navigate={~p"/strands/#{@strand.id}/overview"} class="mt-4">
          {gettext("Full overview")}
        </.button>
        <section class="mt-20">
          <h2 class="font-display font-black text-2xl">{gettext("Strand lessons")}</h2>
          <div class="flex items-center gap-4 mt-6">
            <.button
              type="button"
              icon_name="hero-funnel-mini"
            >
              {gettext("All moments and lessons")}
            </.button>
            <div class="relative">
              <.button
                type="button"
                id="new-in-lesson-options-button"
                icon_name="hero-plus-mini"
                theme="primary"
              >
                {gettext("New")}
              </.button>
              <.dropdown_menu
                id="new-in-lesson-options"
                button_id="new-in-lesson-options-button"
                z_index="30"
              >
                <:item type="link" patch="?moment=new" text={gettext("Create new moment")} />
                <:item type="link" patch="?lesson=new" text={gettext("Create new lesson")} />
              </.dropdown_menu>
            </div>
          </div>
          <%= if @moments_ids == [] do %>
            <.card_base class="p-10">
              <.empty_state>{gettext("No moments for this strand yet")}</.empty_state>
            </.card_base>
          <% else %>
            <div
              id="strand-moments"
              phx-hook="Sortable"
              id="sortable-moments"
              data-sortable-handle=".drag-handle"
              phx-update="ignore"
            >
              <div
                :for={{dom_id, moment} <- @streams.moments}
                class="flex items-start gap-4 mt-12"
                id={dom_id}
              >
                <div class="py-3 hover:cursor-move drag-handle">
                  <hr class="w-6 h-1 border-0 rounded-full bg-ltrn-dark" />
                </div>
                <div class="flex-1">
                  <div class="flex items-center gap-4">
                    <.link
                      navigate={~p"/strands/moment/#{moment.id}"}
                      class="font-display font-bold text-xl hover:text-ltrn-subtle"
                    >
                      {moment.name}
                    </.link>
                    <.action
                      type="link"
                      patch={"?moment=#{moment.id}"}
                      icon_name="hero-pencil-mini"
                      theme="subtle"
                    >
                      {gettext("Edit")}
                    </.action>
                  </div>
                  <.markdown text={moment.description} strip_tags class="mt-4 line-clamp-3" />
                </div>
              </div>
            </div>
          <% end %>
        </section>
      </.responsive_container>
      <.slide_over
        :if={@moment}
        id="moment-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/strands/#{@strand}")}
      >
        <:title>{@moment_overlay_title}</:title>
        <.live_component
          module={MomentFormComponent}
          id={:new}
          moment={@moment}
          strand_id={@strand.id}
          action={:new}
          navigate={fn _moment -> ~p"/strands/#{@strand}" end}
          notify_parent
        />
        <:actions_left>
          <.button
            type="button"
            theme="ghost"
            phx-click="delete_moment"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
          >
            {gettext("Delete")}
          </.button>
        </:actions_left>
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#moment-form-overlay")}
          >
            {gettext("Cancel")}
          </.button>
          <.button type="submit" form="moment-form">
            {gettext("Save")}
          </.button>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  # lifecycle
  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_moment()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    strand = socket.assigns.strand

    socket
    |> assign(
      :cover_image_url,
      object_url_to_render_url(strand.cover_image_url, width: 1280, height: 640)
    )
    |> stream_moments()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_moments(socket) do
    moments =
      LearningContext.list_moments(strands_ids: [socket.assigns.strand.id])

    socket
    |> stream(:moments, moments)
    |> assign(:moments_ids, Enum.map(moments, &"#{&1.id}"))
  end

  defp assign_moment(%{assigns: %{params: %{"moment" => "new"}}} = socket) do
    moment = %Moment{strand_id: socket.assigns.strand.id, subjects: []}

    socket
    |> assign(:moment, moment)
    |> assign(:moment_overlay_title, gettext("New moment"))
  end

  defp assign_moment(%{assigns: %{params: %{"moment" => moment_id}}} = socket) do
    if moment_id in socket.assigns.moments_ids do
      moment = LearningContext.get_moment(moment_id, preloads: :subjects)

      socket
      |> assign(:moment, moment)
      |> assign(:moment_overlay_title, gettext("Edit moment"))
    else
      assign(socket, :moment, nil)
    end
  end

  defp assign_moment(socket), do: assign(socket, :moment, nil)

  # event handlers

  @impl true
  def handle_event("delete_moment", _params, socket) do
    case LearningContext.delete_moment(socket.assigns.moment) do
      {:ok, _moment} ->
        nav_opts = [
          put_flash: {:info, gettext("Moment deleted")},
          push_navigate: [to: ~p"/strands/#{socket.assigns.strand}"]
        ]

        {:noreply, delegate_navigation(socket, nav_opts)}

      {:error, _changeset} ->
        nav_opts = [
          put_flash:
            {:error,
             gettext("Moment has linked assessments. Deleting it would cause some data loss.")},
          push_patch: [
            to: ~p"/strands/#{socket.assigns.strand}?moment=#{socket.assigns.moment.id}"
          ]
        ]

        {:noreply, delegate_navigation(socket, nav_opts)}
    end
  end

  # view Sortable hook for payload info
  def handle_event("sortable_update", payload, socket) do
    %{
      "oldIndex" => old_index,
      "newIndex" => new_index
    } = payload

    moments_ids = reorder(socket.assigns.moments_ids, old_index, new_index)

    # the inteface was already updated (optimistic update), just persist the new order
    LearningContext.update_strand_moments_positions(socket.assigns.strand.id, moments_ids)

    {:noreply, assign(socket, :moments_ids, moments_ids)}
  end
end
