defmodule LantternWeb.ILP.StudentILPFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `StudentILP` form

  ### Attrs

      attr :ilp, StudentILP, required: true
      attr :title, :string, required: true
      attr :current_profile, Profile, required: true
      attr :on_cancel, :any, required: true, doc: "`<.slide_over>` `on_cancel` attr"
      attr :notify_parent, :boolean
      attr :notify_component, Phoenix.LiveComponent.CID

  """

  use LantternWeb, :live_component

  alias Lanttern.ILP
  alias Lanttern.ILP.StudentILP

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over id={@id} show={true} on_cancel={@on_cancel}>
        <:title><%= @title %></:title>
        <.form
          id="student-ilp-form"
          for={@form}
          phx-change="validate"
          phx-submit="save"
          phx-target={@myself}
        >
          <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
            <%= gettext("Oops, something went wrong! Please check the errors below.") %>
          </.error_block>
          <.input
            field={@form[:teacher_notes]}
            type="textarea"
            label={gettext("Teacher notes")}
            class="mb-1"
            phx-debounce="1500"
            show_optional
          />
          <.markdown_supported class="mb-6" />
          <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
            <%= gettext("Oops, something went wrong! Please check the errors above.") %>
          </.error_block>
        </.form>
        <:actions_left :if={@ilp.id}>
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
            form="student-ilp-form"
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
    socket = assign(socket, :initialized, false)
    {:ok, socket}
  end

  @impl true
  def update(%{ilp: %StudentILP{}} = assigns, socket) do
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
    ilp = socket.assigns.ilp
    changeset = ILP.change_student_ilp(ilp)

    socket
    |> assign(:form, to_form(changeset))
  end

  # event handlers

  @impl true
  def handle_event("validate", %{"student_ilp" => ilp_params}, socket),
    do: {:noreply, assign_validated_form(socket, ilp_params)}

  def handle_event("save", %{"student_ilp" => ilp_params}, socket) do
    ilp_params =
      inject_extra_params(socket, ilp_params)

    save_ilp(socket, socket.assigns.ilp.id, ilp_params)
  end

  def handle_event("delete", _, socket) do
    ILP.delete_student_ilp(socket.assigns.ilp)
    |> case do
      {:ok, ilp} ->
        notify(__MODULE__, {:deleted, ilp}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp assign_validated_form(socket, params) do
    params = inject_extra_params(socket, params)

    changeset =
      socket.assigns.ilp
      |> ILP.change_student_ilp(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  # inject params handled in backend
  defp inject_extra_params(socket, params) do
    params
    |> Map.put("school_id", socket.assigns.ilp.school_id)
    |> Map.put("template_id", socket.assigns.ilp.template_id)
    |> Map.put("cycle_id", socket.assigns.ilp.cycle_id)
    |> Map.put("student_id", socket.assigns.ilp.student_id)
  end

  defp save_ilp(socket, nil, ilp_params) do
    ILP.create_student_ilp(ilp_params)
    |> case do
      {:ok, ilp} ->
        notify(__MODULE__, {:created, ilp}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset)
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_ilp(socket, _id, ilp_params) do
    ILP.update_student_ilp(
      socket.assigns.ilp,
      ilp_params
    )
    |> case do
      {:ok, message} ->
        notify(__MODULE__, {:updated, message}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
