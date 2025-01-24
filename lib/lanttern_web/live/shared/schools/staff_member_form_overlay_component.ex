defmodule LantternWeb.Schools.StaffMemberFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `StaffMember` form

  ### Attrs

      attr :staff_member, Staff, required: true
      attr :title, :string, required: true
      attr :on_cancel, :any, required: true, doc: "`<.slide_over>` `on_cancel` attr"
      attr :notify_parent, :boolean
      attr :notify_component, Phoenix.LiveComponent.CID

  """

  use LantternWeb, :live_component

  alias Lanttern.Schools

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over id={@id} show on_cancel={@on_cancel}>
        <:title><%= @title %></:title>
        <.form
          id="staff-member-form"
          for={@form}
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
        >
          <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
            <%= gettext("Oops, something went wrong! Please check the errors below.") %>
          </.error_block>
          <.input
            field={@form[:name]}
            type="text"
            label={gettext("Name")}
            class="mb-6"
            phx-debounce="1500"
          />
          <.input field={@form[:role]} type="text" label={gettext("Role")} phx-debounce="1500" />
        </.form>
        <:actions_left :if={@staff_member.id}>
          <.button
            type="button"
            theme="ghost"
            phx-click="delete"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
          >
            <%= gettext("Delete") %>
          </.button>
        </:actions_left>
        <:actions>
          <.button type="button" theme="ghost" phx-click={JS.exec("data-cancel", to: "##{@id}")}>
            <%= gettext("Cancel") %>
          </.button>
          <.button type="submit" form="staff-member-form">
            <%= gettext("Save") %>
          </.button>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket = assign(socket, :initialized, false)
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
    staff_member = socket.assigns.staff_member
    changeset = Schools.change_staff_member(staff_member)

    socket
    |> assign(:form, to_form(changeset))
  end

  # event handlers

  @impl true
  def handle_event("validate", %{"staff_member" => staff_member_params}, socket),
    do: {:noreply, assign_validated_form(socket, staff_member_params)}

  def handle_event("save", %{"staff_member" => staff_member_params}, socket) do
    staff_member_params =
      inject_extra_params(socket, staff_member_params)

    save_staff_member(socket, socket.assigns.staff_member.id, staff_member_params)
  end

  def handle_event("delete", _, socket) do
    Schools.delete_staff_member(socket.assigns.staff_member)
    |> case do
      {:ok, staff_member} ->
        notify(__MODULE__, {:deleted, staff_member}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp assign_validated_form(socket, params) do
    params = inject_extra_params(socket, params)

    changeset =
      socket.assigns.staff_member
      |> Schools.change_staff_member(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  # inject params handled in backend
  defp inject_extra_params(socket, params) do
    params
    |> Map.put("school_id", socket.assigns.staff_member.school_id)
  end

  defp save_staff_member(socket, nil, staff_member_params) do
    Schools.create_staff_member(staff_member_params)
    |> case do
      {:ok, staff_member} ->
        notify(__MODULE__, {:created, staff_member}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_staff_member(socket, _id, staff_member_params) do
    Schools.update_staff_member(
      socket.assigns.staff_member,
      staff_member_params
    )
    |> case do
      {:ok, staff_member} ->
        notify(__MODULE__, {:updated, staff_member}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
