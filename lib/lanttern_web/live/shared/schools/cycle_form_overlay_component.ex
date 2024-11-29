defmodule LantternWeb.Schools.CycleFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `Cycle` form
  """

  use LantternWeb, :live_component

  alias Lanttern.Schools
  alias Lanttern.Schools.Cycle
  import LantternWeb.SchoolsHelpers, only: [generate_cycle_options: 1]

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over id={@id} show={true} on_cancel={@on_cancel}>
        <:title><%= @title %></:title>
        <.form
          id="cycle-form"
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
            label={gettext("Cycle name")}
            class="mb-6"
            phx-debounce="1500"
          />
          <.input field={@form[:start_at]} type="date" label={gettext("Start at")} class="mb-6" />
          <.input field={@form[:end_at]} type="date" label={gettext("End at")} class="mb-6" />
          <.input
            field={@form[:parent_cycle_id]}
            type="select"
            label={gettext("Parent cycle")}
            prompt={gettext("Select parent cycle")}
            options={@cycle_options}
          />
        </.form>
        <:actions_left :if={@cycle.id}>
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
          <.button type="submit" form="cycle-form">
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
  def update(%{cycle: %Cycle{}} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_form()
      |> assign(:initialized, true)

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    cycle_options =
      generate_cycle_options(
        schools_ids: [socket.assigns.cycle.school_id],
        parent_cycles_only: true
      )

    socket
    |> assign(:cycle_options, cycle_options)
    |> assign(:initalized, true)
  end

  defp initialize(socket), do: socket

  defp assign_form(socket) do
    cycle = socket.assigns.cycle
    changeset = Schools.change_cycle(cycle)

    socket
    |> assign(:form, to_form(changeset))
  end

  # event handlers

  @impl true
  def handle_event("validate", %{"cycle" => cycle_params}, socket),
    do: {:noreply, assign_validated_form(socket, cycle_params)}

  def handle_event("save", %{"cycle" => cycle_params}, socket) do
    cycle_params =
      inject_extra_params(socket, cycle_params)

    save_cycle(socket, socket.assigns.cycle.id, cycle_params)
  end

  def handle_event("delete", _, socket) do
    Schools.delete_cycle(socket.assigns.cycle)
    |> case do
      {:ok, cycle} ->
        notify(__MODULE__, {:deleted, cycle}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp assign_validated_form(socket, params) do
    params = inject_extra_params(socket, params)

    changeset =
      socket.assigns.cycle
      |> Schools.change_cycle(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  # inject params handled in backend
  defp inject_extra_params(socket, params) do
    params
    |> Map.put("school_id", socket.assigns.cycle.school_id)
  end

  defp save_cycle(socket, nil, cycle_params) do
    Schools.create_cycle(cycle_params)
    |> case do
      {:ok, cycle} ->
        notify(__MODULE__, {:created, cycle}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_cycle(socket, _id, cycle_params) do
    Schools.update_cycle(
      socket.assigns.cycle,
      cycle_params
    )
    |> case do
      {:ok, cycle} ->
        notify(__MODULE__, {:updated, cycle}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
