defmodule LantternWeb.SchoolLive.MomentCardsTemplatesComponent do
  @moduledoc """
  ### Supported attrs/assigns

  - `is_content_manager` (required, bool)
  """
  use LantternWeb, :live_component

  alias Lanttern.SchoolConfig
  alias Lanttern.SchoolConfig.MomentCardTemplate

  import Lanttern.Utils, only: [swap: 3]

  # shared components
  alias LantternWeb.SchoolConfig.MomentCardTemplateOverlayComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.action_bar class="flex items-center justify-between gap-4">
        <p>
          <%= gettext("Templates for new moment cards") %>
        </p>
        <div class="flex gap-4">
          <.action
            :if={@templates_count > 1}
            type="link"
            patch={~p"/school/moment_cards_templates?reorder=true"}
            icon_name="hero-arrows-up-down-mini"
          >
            <%= gettext("Reorder") %>
          </.action>
          <.action
            :if={@is_content_manager}
            type="link"
            patch={~p"/school/moment_cards_templates?new=true"}
            icon_name="hero-plus-circle-mini"
          >
            <%= gettext("Add card template") %>
          </.action>
        </div>
      </.action_bar>
      <%= if @templates_count == 0 do %>
        <div class="p-4">
          <.card_base class="p-10">
            <.empty_state><%= gettext("No templates created yet") %></.empty_state>
          </.card_base>
        </div>
      <% else %>
        <.responsive_grid phx-update="stream" id="moment-cards-templates" class="p-4" is_full_width>
          <.card_base :for={{dom_id, template} <- @streams.templates} id={dom_id} class="p-6">
            <.link
              patch={~p"/school/moment_cards_templates?id=#{template.id}"}
              class="font-display font-black text-xl hover:text-ltrn-subtle"
            >
              <%= template.name %>
            </.link>
            <div class="mt-6 line-clamp-4">
              <.markdown text={template.template} />
            </div>
          </.card_base>
        </.responsive_grid>
      <% end %>
      <.live_component
        :if={@template}
        module={MomentCardTemplateOverlayComponent}
        moment_card_template={@template}
        id="moment-card-template-overlay"
        on_cancel={JS.patch(~p"/school/moment_cards_templates")}
        allow_edit={@is_content_manager}
        notify_component={@myself}
      />
      <.slide_over
        :if={@is_reordering}
        show
        id="moment-cards-templates-order-overlay"
        on_cancel={JS.patch(~p"/school/moment_cards_templates")}
      >
        <:title><%= gettext("Moment cards templates order") %></:title>
        <ol>
          <li
            :for={{template, i} <- @sortable_templates}
            id={"sortable-template-#{template.id}"}
            class="mb-4"
          >
            <.sortable_card
              is_move_up_disabled={i == 0}
              on_move_up={
                JS.push("set_template_position", value: %{from: i, to: i - 1}, target: @myself)
              }
              is_move_down_disabled={i + 1 == @templates_count}
              on_move_down={
                JS.push("set_template_position", value: %{from: i, to: i + 1}, target: @myself)
              }
            >
              <%= "#{i + 1}. #{template.name}" %>
            </.sortable_card>
          </li>
        </ol>
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#moment-cards-templates-order-overlay")}
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
    {:ok, assign(socket, :initialized, false)}
  end

  @impl true
  def update(%{action: {MomentCardTemplateOverlayComponent, {:created, template}}}, socket) do
    socket =
      socket
      |> stream_insert(:templates, template)
      |> assign(:templates_count, socket.assigns.templates_count + 1)

    {:ok, socket}
  end

  def update(%{action: {MomentCardTemplateOverlayComponent, {:updated, template}}}, socket),
    do: {:ok, stream_insert(socket, :templates, template)}

  def update(%{action: {MomentCardTemplateOverlayComponent, {:deleted, template}}}, socket) do
    socket =
      socket
      |> stream_delete(:templates, template)
      |> assign(:templates_count, socket.assigns.templates_count - 1)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_template()
      |> assign_sortable_templates()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> stream_templates()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_templates(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id

    templates =
      SchoolConfig.list_moment_cards_templates(schools_ids: [school_id])

    socket
    |> stream(:templates, templates)
    |> assign(:templates_count, length(templates))
  end

  defp assign_template(
         %{assigns: %{params: %{"new" => "true"}, is_content_manager: true}} = socket
       ) do
    template = %MomentCardTemplate{
      school_id: socket.assigns.current_user.current_profile.school_id
    }

    socket
    |> assign(:template, template)
  end

  defp assign_template(%{assigns: %{params: %{"id" => id}}} = socket) do
    template =
      SchoolConfig.get_moment_card_template(id)

    socket
    |> assign(:template, template)
  end

  defp assign_template(socket), do: assign(socket, :template, nil)

  defp assign_sortable_templates(
         %{assigns: %{params: %{"reorder" => "true"}, is_content_manager: true}} = socket
       ) do
    school_id = socket.assigns.current_user.current_profile.school_id

    templates =
      SchoolConfig.list_moment_cards_templates(schools_ids: [school_id])
      # remove unnecessary fields to save memory
      |> Enum.map(&%MomentCardTemplate{id: &1.id, name: &1.name})

    socket
    |> assign(:sortable_templates, Enum.with_index(templates))
    |> assign(:is_reordering, true)
  end

  defp assign_sortable_templates(socket), do: assign(socket, :is_reordering, false)

  # event handlers

  @impl true
  def handle_event("set_template_position", %{"from" => i, "to" => j}, socket) do
    sortable_templates =
      socket.assigns.sortable_templates
      |> Enum.map(fn {mct, _i} -> mct end)
      |> swap(i, j)
      |> Enum.with_index()

    {:noreply, assign(socket, :sortable_templates, sortable_templates)}
  end

  def handle_event("save_order", _, socket) do
    templates_ids =
      socket.assigns.sortable_templates
      |> Enum.map(fn {mct, _i} -> mct.id end)

    case SchoolConfig.update_moment_cards_templates_positions(templates_ids) do
      :ok ->
        socket =
          socket
          |> push_navigate(to: ~p"/school/moment_cards_templates")

        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end
end
