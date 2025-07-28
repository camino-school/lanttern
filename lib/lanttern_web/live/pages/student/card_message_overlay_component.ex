defmodule LantternWeb.MessageBoard.CardMessageOverlayComponent do
  @moduledoc """
  Renders a `card_message` form
  """

  use LantternWeb, :live_component
  import LantternWeb.DateTimeHelpers

  alias Lanttern.MessageBoard
  # alias Lanttern.SupabaseHelpers
  # import LantternWeb.TaxonomyHelpers

  # live components
  # alias LantternWeb.Form.MultiSelectComponent

  attr :tz, :string, default: nil

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over :if={@card_message} id={@id} show={true} on_cancel={@on_cancel}>
        <div class="p-4">
          <h1 class="font-display font-black text-4xl"><%= @card_message.title %></h1>

          <div class="flex flex-row-reverse sm:flex-row items-center gap-2 mt-2 text-xs">
            <.icon name="hero-calendar-mini" class="w-5 h-5 text-ltrn-subtle" />
            <div class="flex-1 sm:flex sm:items-center sm:gap-2">
              <%= format_by_locale(@card_message.inserted_at, @tz) %>
              <%= if @card_message.inserted_at != @card_message.updated_at do %>
                <div class="mt-1 sm:mt-0 text-ltrn-subtle">
                  <%= "(#{gettext("Updated")} #{format_by_locale(@card_message.updated_at, @tz)})" %>
                </div>
              <% end %>
            </div>
          </div>

          <.cover_image
            image_url={@card_message.cover}
            alt_text={gettext("Message cover image")}
            empty_state_text={gettext("Message without cover image")}
            theme="lime"
            size="sm"
          />
          <.responsive_container class="mt-10">
            <h4 class="font-display font-black text-4xl"><%= @card_message.subtitle %></h4>
            <p class="mt-2 font-display font-black text-2xl text-ltrn-subtle">
              <%!-- <%= gettext("card_message of %{strand}", strand: @strand.subtitle) %> --%>
            </p>
            <%!-- <div class="flex flex-wrap gap-2 mt-4">
                <.badge :for={subject <- @card_message.subjects} theme="dark">
                  <%= Gettext.dgettext(Lanttern.Gettext, "taxonomy", subject.name) %>
                </.badge>
              </div> --%>

            <%!-- <h3 class="mt-16 font-display font-black text-3xl"><%= gettext("Attachments") %></h3> --%>
            <%!-- <div id="card_message-curriculum-items" phx-update="stream">
                <div :for={{dom_id, curriculum_item} <- @streams.curriculum_items} id={dom_id} class="mt-6">
                  <.badge theme="dark"><%= curriculum_item.curriculum_component.name %></.badge>
                  <p class="mt-4"><%= curriculum_item.name %></p>
                </div>
              </div> --%>
          </.responsive_container>
          <.markdown text={@card_message.content} class="mt-10" />
        </div>

        <:actions_left :if={@card_message.id}>
          <.action
            type="button"
            theme="subtle"
            size="md"
            phx-click="delete"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
          >
            <%= gettext("Delete") %>
          </.action>
        </:actions_left>
        <:actions>
          <.action
            type="button"
            theme="subtle"
            size="md"
            phx-click={JS.exec("data-cancel", to: "##{@id}")}
          >
            <%= gettext("Cancel") %>
          </.action>
          <.action
            type="submit"
            theme="primary"
            size="md"
            icon_name="hero-check"
            form="ilp-comment-form"
            id="save-action-ilp-comment"
          >
            <%= gettext("Save") %>
          </.action>
        </:actions>
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
      |> MessageBoard.change_card_message(card_message_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
