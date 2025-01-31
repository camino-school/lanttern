defmodule LantternWeb.StudentsRecords.StudentRecordStatusFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `StudentRecordStatus` form

  ### Attrs

      attr :status, StudentRecordStatus, required: true
      attr :title, :string, required: true
      attr :on_cancel, :any, required: true, doc: "`<.slide_over>` `on_cancel` attr"
      attr :notify_parent, :boolean
      attr :notify_component, Phoenix.LiveComponent.CID

  """

  use LantternWeb, :live_component

  alias Lanttern.StudentsRecords

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over id={@id} show on_cancel={@on_cancel}>
        <:title><%= @title %></:title>
        <.form
          id="student-record-status-form"
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
          <.input
            field={@form[:bg_color]}
            type="text"
            label={gettext("Background color (hex)")}
            class="mb-6"
            phx-debounce="1500"
          />
          <.input
            field={@form[:text_color]}
            type="text"
            label={gettext("Text color (hex)")}
            class="mb-6"
            phx-debounce="1500"
          />
          <div class="p-4 rounded-sm bg-ltrn-mesh-cyan">
            <.input
              field={@form[:is_closed]}
              type="toggle"
              label={gettext("Use status to close student record")}
            />
            <p class="mt-4">
              <%= gettext(
                "If active, assigning this status to an existing record will close it and calculate the time since its creation."
              ) %>
            </p>
            <p class="mt-2">
              <%= gettext(
                "When activating, previous records with this status will not change: records already closed will remain closed, and open records will be considered \"closed on creation\"."
              ) %>
            </p>
          </div>
        </.form>
        <.card_base class="p-6 mt-10">
          <p class="mb-4 text-ltrn-subtle"><%= gettext("Preview") %></p>
          <.badge
            color_map={%{bg_color: @form[:bg_color].value, text_color: @form[:text_color].value}}
            icon_name={if(@form[:is_closed].value, do: "hero-check-circle-mini")}
          >
            <%= @form[:name].value %>
          </.badge>
        </.card_base>
        <:actions_left :if={@status.id}>
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
            form="student-record-status-form"
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
    status = socket.assigns.status
    changeset = StudentsRecords.change_student_record_status(status)

    socket
    |> assign(:form, to_form(changeset))
  end

  # event handlers

  @impl true
  def handle_event("validate", %{"student_record_status" => status_params}, socket),
    do: {:noreply, assign_validated_form(socket, status_params)}

  def handle_event("save", %{"student_record_status" => status_params}, socket) do
    status_params = inject_extra_params(socket, status_params)
    save_status(socket, socket.assigns.status.id, status_params)
  end

  def handle_event("delete", _, socket) do
    StudentsRecords.delete_student_record_status(socket.assigns.status)
    |> case do
      {:ok, status} ->
        notify(__MODULE__, {:deleted, status}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp assign_validated_form(socket, params) do
    params = inject_extra_params(socket, params)

    changeset =
      socket.assigns.status
      |> StudentsRecords.change_student_record_status(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  # inject params handled in backend
  defp inject_extra_params(socket, params) do
    params
    |> Map.put("school_id", socket.assigns.status.school_id)
  end

  defp save_status(socket, nil, status_params) do
    StudentsRecords.create_student_record_status(status_params)
    |> case do
      {:ok, status} ->
        notify(__MODULE__, {:created, status}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_status(socket, _id, status_params) do
    StudentsRecords.update_student_record_status(
      socket.assigns.status,
      status_params
    )
    |> case do
      {:ok, status} ->
        notify(__MODULE__, {:updated, status}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
