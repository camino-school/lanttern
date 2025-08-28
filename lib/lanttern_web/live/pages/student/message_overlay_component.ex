defmodule LantternWeb.MessageBoard.CardMessageOverlayComponent do
  @moduledoc """
  Renders a `message` form
  """

  use LantternWeb, :live_component
  import LantternWeb.DateTimeHelpers

  alias Lanttern.MessageBoard
  # alias Lanttern.SupabaseHelpers
  # import LantternWeb.TaxonomyHelpers

  # live components
  # alias LantternWeb.Form.MultiSelectComponent

  attr :tz, :string, default: nil
  attr :admin, :string, default: nil
  attr :full_w, :boolean, default: true

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over :if={@card_message} id={@id} show={true} on_cancel={@on_cancel} full_y={true} full_w={@full_w} bg_color={@card_message.color}>
        <div>
          <%!-- sm:-mx-6 --%>
          <div id={"#{@id}-header"} class="sticky top-0 z-50 w-full shadow-lg">
            <.action
              type="button"
              theme="subtle"
              size="md"
              class="p-4 pb-2"
              phx-click={JS.exec("data-cancel", to: "##{@id}")}
            >
              <.icon name="hero-arrow-left-solid" class="h-6 w-6" />
            </.action>
            <div class="flex items-center gap-4 pl-4">
              <h1 class="font-display font-black text-2xl">{@card_message.name}</h1>
            </div>
            <div class="flex sm:flex-row items-center gap-2 mt-1 ml-5 pb-5 text-xs">
              <.icon name="hero-calendar-mini" class="w-5 h-5" />
              <div class="flex-1 sm:flex sm:items-center sm:gap-2">
                <div class="mt-1 sm:mt-0 gap-1">
                  {"(#{gettext("Updated")} #{format_by_locale(@card_message.updated_at, @tz)})"}
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="relative">
          <%= if @card_message.cover &&  @card_message.cover != "" do %>
            <img class="w-full h-64 object-cover shadow-xl" src={@card_message.cover} alt="message cover image" />
          <% end %>
          <div class="mt-10 m-4 px-4">
            <%!-- <div class={"mt-10 px-4 sm:px-6"}>
              <h4 class="font-display font-bold text-base">{@card_message.subtitle}</h4>
              <p class="mt-2 font-display font-bold text-base text-ltrn-subtle">
              </p>
            </div> --%>
            <.markdown text={@card_message.description} />
            <hr style={"color: #CBD5E1"} class="my-4">
            <h4 class="font-display font-bold text-base">{gettext("Category")}</h4>
            <.badge
              color_map={@card_message.color}
              id={"category-#{@card_message.section_id}-#{@card_message.id}"}
            >
              {"##{@card_message.section_id}"}
            </.badge>
          </div>

        </div>
      </.slide_over>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:show_actions, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :cover, ref)}
  end

  def handle_event("replace-cover", _, socket) do
    {:noreply, assign(socket, :is_removing_cover, true)}
  end

  def handle_event("cancel-replace-cover", _, socket) do
    {:noreply, assign(socket, :is_removing_cover, false)}
  end

  def handle_event("validate", %{"card_message" => card_message_params}, socket) do
    changeset =
      socket.assigns.card_message
      |> MessageBoard.change_message(card_message_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
