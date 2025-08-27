defmodule LantternWeb.StudentsInsights.SparksTagFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `StudentsInsights.Tag` form

  ### Attrs

      attr :tag, Tag, required: true
      attr :title, :string, required: true
      attr :on_cancel, :any, required: true, doc: "`<.slide_over>` `on_cancel` attr"
      attr :current_user, User, required: true
      attr :notify_parent, :boolean, default: false

  """

  use LantternWeb, :live_component

  alias Lanttern.StudentsInsights

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over id={@id} show on_cancel={@on_cancel}>
        <:title>{@title}</:title>
        <.form
          id="sparks-tag-form"
          for={@form}
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
        >
          <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
            {gettext("Oops, something went wrong! Please check the errors below.")}
          </.error_block>
          <.input
            field={@form[:name]}
            type="text"
            label={gettext("Name")}
            class="mb-6"
            phx-debounce="1500"
          />
          <.input
            field={@form[:description]}
            type="markdown"
            label={gettext("Tag description")}
            class="mb-6"
            phx-debounce="1500"
            show_optional
          />
          <div class="flex items-start gap-4 mb-6">
            <.input
              field={@form[:bg_color]}
              type="text"
              label={gettext("Background color (hex)")}
              placeholder="#000000"
              phx-debounce="1500"
              class="flex-1"
            />
            <.input
              field={@form[:text_color]}
              type="text"
              label={gettext("Text color (hex)")}
              placeholder="#ffffff"
              phx-debounce="1500"
              class="flex-1"
            />
          </div>
        </.form>
        <.card_base class="p-6">
          <p class="mb-4 text-ltrn-subtle">{gettext("Preview")}</p>
          <.badge
            :if={@form[:name].value && @form[:name].value != ""}
            color_map={
              %{
                bg_color: @form[:bg_color].value || "#3b82f6",
                text_color: @form[:text_color].value || "#ffffff"
              }
            }
          >
            {@form[:name].value}
          </.badge>
          <div :if={!@form[:name].value || @form[:name].value == ""} class="text-ltrn-subtle text-sm">
            {gettext("Enter a tag name to see preview")}
          </div>
        </.card_base>
        <:actions_left :if={@tag.id}>
          <.action
            type="button"
            theme="subtle"
            size="md"
            phx-click="delete"
            phx-target={@myself}
            data-confirm={gettext("Are you sure? This action cannot be undone.")}
          >
            {gettext("Delete")}
          </.action>
        </:actions_left>
        <:actions>
          <.action
            type="button"
            theme="subtle"
            size="md"
            phx-click={JS.exec("data-cancel", to: "##{@id}")}
          >
            {gettext("Cancel")}
          </.action>
          <.action
            type="submit"
            theme="primary"
            size="md"
            icon_name="hero-check"
            form="sparks-tag-form"
          >
            {gettext("Save")}
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
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_form()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_form(socket) do
    tag = socket.assigns.tag
    changeset = StudentsInsights.change_tag(socket.assigns.current_user, tag)

    socket
    |> assign(:form, to_form(changeset))
  end

  # event handlers

  @impl true
  def handle_event("validate", %{"tag" => tag_params}, socket),
    do: {:noreply, assign_validated_form(socket, tag_params)}

  def handle_event("save", %{"tag" => tag_params}, socket) do
    save_tag(socket, socket.assigns.tag.id, tag_params)
  end

  def handle_event("delete", _, socket) do
    StudentsInsights.delete_tag(socket.assigns.current_user, socket.assigns.tag)
    |> case do
      {:ok, tag} ->
        notify(__MODULE__, {:deleted, tag}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp assign_validated_form(socket, params) do
    changeset =
      StudentsInsights.change_tag(socket.assigns.current_user, socket.assigns.tag, params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  defp save_tag(socket, nil, tag_params) do
    StudentsInsights.create_tag(socket.assigns.current_user, tag_params)
    |> case do
      {:ok, tag} ->
        notify(__MODULE__, {:created, tag}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_tag(socket, _id, tag_params) do
    StudentsInsights.update_tag(
      socket.assigns.current_user,
      socket.assigns.tag,
      tag_params
    )
    |> case do
      {:ok, tag} ->
        notify(__MODULE__, {:updated, tag}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
