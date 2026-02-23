defmodule LantternWeb.Students.StudentTagFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `StudentTags.Tag` form

  ### Attrs

      attr :tag, Tag, required: true
      attr :title, :string, required: true
      attr :on_cancel, :any, required: true, doc: "`<.slide_over>` `on_cancel` attr"
      attr :notify_parent, :boolean
      attr :notify_component, Phoenix.LiveComponent.CID

  """

  use LantternWeb, :live_component

  alias Lanttern.StudentTags

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over id={@id} show on_cancel={@on_cancel}>
        <:title>{@title}</:title>
        <.form
          id="student-tag-form"
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
            field={@form[:bg_color]}
            type="color"
            label={gettext("Background color")}
            class="mb-6"
          />
          <.input
            field={@form[:text_color]}
            type="color"
            label={gettext("Text color")}
            class="mb-6"
          />
        </.form>
        <.card_base class="p-6">
          <p class="mb-4 text-ltrn-subtle">{gettext("Preview")}</p>
          <.badge color_map={
            %{bg_color: @form[:bg_color].value, text_color: @form[:text_color].value}
          }>
            {@form[:name].value}
          </.badge>
        </.card_base>
        <:actions_left :if={@tag.id}>
          <.action
            type="button"
            theme="subtle"
            size="md"
            phx-click="delete"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
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
            form="student-tag-form"
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
    changeset = StudentTags.change_student_tag(tag)

    socket
    |> assign(:form, to_form(changeset))
  end

  # event handlers

  @impl true
  def handle_event("validate", %{"tag" => tag_params}, socket),
    do: {:noreply, assign_validated_form(socket, tag_params)}

  def handle_event("save", %{"tag" => tag_params}, socket) do
    tag_params = inject_extra_params(socket, tag_params)
    save_tag(socket, socket.assigns.tag.id, tag_params)
  end

  def handle_event("delete", _, socket) do
    StudentTags.delete_student_tag(socket.assigns.tag)
    |> case do
      {:ok, tag} ->
        notify(__MODULE__, {:deleted, tag}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp assign_validated_form(socket, params) do
    params = inject_extra_params(socket, params)

    changeset =
      socket.assigns.tag
      |> StudentTags.change_student_tag(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  # inject params handled in backend
  defp inject_extra_params(socket, params) do
    params
    |> Map.put("school_id", socket.assigns.tag.school_id)
  end

  defp save_tag(socket, nil, tag_params) do
    StudentTags.create_student_tag(tag_params)
    |> case do
      {:ok, tag} ->
        notify(__MODULE__, {:created, tag}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_tag(socket, _id, tag_params) do
    StudentTags.update_student_tag(
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
