defmodule LantternWeb.SchoolConfigLive.MomentCardsTemplatesComponent do
  @moduledoc """
  ### Supported attrs/assigns

  - `is_content_manager` (required, bool)
  """
  use LantternWeb, :live_component

  alias Lanttern.SchoolConfig
  alias Lanttern.SchoolConfig.MomentCardTemplate

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
        <.action
          :if={@is_content_manager}
          type="link"
          patch={~p"/school_config/moment_cards_templates?new=true"}
          icon_name="hero-plus-circle-mini"
        >
          <%= gettext("Add card template") %>
        </.action>
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
              patch={~p"/school_config/moment_cards_templates?id=#{template.id}"}
              class="font-display font-black text-xl hover:text-ltrn-subtle"
            >
              <%= template.name %>
            </.link>
            <div class="mt-6 line-clamp-6">
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
        on_cancel={JS.patch(~p"/school_config/moment_cards_templates")}
        allow_edit={@is_content_manager}
        notify_component={@myself}
      />
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

  # def update(%{action: {CycleFormOverlayComponent, {:updated, cycle}}}, socket) do
  #   nav_opts = [
  #     put_flash: {:info, gettext("Cycle updated successfully")},
  #     push_navigate: [to: ~p"/school/cycles"]
  #   ]

  #   socket =
  #     socket
  #     |> delegate_navigation(nav_opts)
  #     |> stream_insert(:cycles, cycle)

  #   {:ok, socket}
  # end

  # def update(%{action: {CycleFormOverlayComponent, {:deleted, cycle}}}, socket) do
  #   nav_opts = [
  #     put_flash: {:info, gettext("Cycle deleted successfully")},
  #     push_patch: [to: ~p"/school/cycles"]
  #   ]

  #   socket =
  #     socket
  #     |> delegate_navigation(nav_opts)
  #     |> stream_delete(:cycles, cycle)

  #   {:ok, socket}
  # end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_template()

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
end
