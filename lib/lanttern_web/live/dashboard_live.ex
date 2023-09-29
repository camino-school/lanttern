defmodule LantternWeb.DashboardLive do
  @moduledoc """
  ### PubSub subscription topics

  - "dashboard:profile_id" on `handle_params`

  Expected broadcasted messages in `handle_info/2` documentation.
  """

  use LantternWeb, :live_view
  alias Phoenix.PubSub

  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <.page_title_with_menu>Dashboard 🚧</.page_title_with_menu>
      <div class="mt-40">
        <.link
          navigate={~p"/assessment_points"}
          class="flex items-center font-display font-black text-lg text-ltrn-subtle"
        >
          Assessment points <.icon name="hero-arrow-right" class="text-ltrn-primary ml-2" />
        </.link>
        <.link
          navigate={~p"/curriculum"}
          class="flex items-center mt-10 font-display font-black text-lg text-ltrn-subtle"
        >
          Curriculum <.icon name="hero-arrow-right" class="text-ltrn-primary ml-2" />
        </.link>
      </div>
      <div class="grid grid-cols-3 gap-10 mt-40">
        <.view_card />
        <.view_card />
        <.view_card />
        <.view_card />
        <.new_view_card />
      </div>
    </div>
    <.live_component
      module={LantternWeb.AssessmentPointsFilterViewOverlayComponent}
      id="create-assessment-points-filter-view-overlay"
      current_user={@current_user}
      show={@show_filter_view_overlay}
      topic={"dashboard:#{@current_user.current_profile_id}"}
      on_cancel={JS.push("cancel_filter_view")}
    />
    """
  end

  # view components

  def view_card(assigns) do
    ~H"""
    <.card_base>
      <:upper_block>
        <.link
          navigate={~p"/assessment_points/explorer"}
          class="font-display font-black text-2xl line-clamp-3 underline hover:text-ltrn-subtle"
          title="Grade 2A Portuguese Grade 2A Portuguese Grade 2A Portuguese Grade 2A Portuguese"
        >
          Grade 2A
        </.link>
      </:upper_block>
      <:lower_block>
        <div class="flex flex-wrap gap-2">
          <.badge>Grade 2A</.badge>
        </div>
        <div class="flex flex-wrap gap-2 mt-2">
          <.badge>Portuguese</.badge>
        </div>
      </:lower_block>
    </.card_base>
    """
  end

  def new_view_card(assigns) do
    ~H"""
    <.card_base>
      <:upper_block>
        <button
          type="button"
          class="font-display font-black text-2xl text-ltrn-subtle text-left underline hover:text-ltrn-primary"
          phx-click="add_filter_view"
        >
          Create a<br />new view
        </button>
      </:upper_block>
      <:lower_block>
        <.icon name="hero-plus-circle" class="w-6 h-6 text-ltrn-primary" />
      </:lower_block>
    </.card_base>
    """
  end

  slot :upper_block
  slot :lower_block

  def card_base(assigns) do
    ~H"""
    <div class="flex flex-col justify-between min-h-[15rem] p-6 rounded bg-white shadow-xl">
      <%= render_slot(@upper_block) %>
      <div class="mt-10">
        <%= render_slot(@lower_block) %>
      </div>
    </div>
    """
  end

  # lifecycle

  def mount(_params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(
        Lanttern.PubSub,
        "dashboard:#{socket.assigns.current_user.current_profile_id}"
      )
    end

    socket =
      socket
      |> assign(:show_filter_view_overlay, false)

    {:ok, socket}
  end

  # event handlers

  def handle_event("add_filter_view", _params, socket) do
    {:noreply, assign(socket, :show_filter_view_overlay, true)}
  end

  def handle_event("cancel_filter_view", _params, socket) do
    {:noreply, assign(socket, :show_filter_view_overlay, false)}
  end

  # info handlers

  @doc """
  Handles sent or broadcasted messages from children Live Components.

  ## Clauses

  #### Assessment points filter view create success

  Broadcasted to `"dashboard:profile_id"` from `LantternWeb.AssessmentPointsFilterViewOverlayComponent`.

      handle_info({:assessment_points_filter_view_created, assessment_points_filter_view}, socket)

  """

  def handle_info(
        {:assessment_points_filter_view_created, _assessment_points_filter_view},
        socket
      ) do
    socket =
      socket
      |> put_flash(:info, "Assessment points filter view created!")
      |> assign(:show_filter_view_overlay, false)

    {:noreply, socket}
  end
end
