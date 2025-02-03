defmodule LantternWeb.Schools.StudentFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `Student` form

  ### Attrs

      attr :student, Student, required: true, doc: "requires `classes` preload"
      attr :current_cycle, Cycle, doc: "used to separate current cycle from other classes"
      attr :title, :string, required: true
      attr :on_cancel, :any, required: true, doc: "`<.slide_over>` `on_cancel` attr"
      attr :notify_parent, :boolean
      attr :notify_component, Phoenix.LiveComponent.CID

  """

  use LantternWeb, :live_component

  alias Lanttern.Schools
  alias Lanttern.Schools.Student

  # shared

  alias LantternWeb.Schools.ClassesFieldComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over id={@id} show={true} on_cancel={@on_cancel}>
        <:title><%= @title %></:title>
        <.form
          id="student-form"
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
          <.live_component
            module={ClassesFieldComponent}
            id="student-form-classes-picker"
            class="mb-6"
            label={gettext("Classes")}
            school_id={@student.school_id}
            current_cycle={@current_cycle}
            selected_classes_ids={@selected_classes_ids}
            notify_component={@myself}
          />
          <.card_base class="p-4" bg_class="bg-ltrn-mesh-cyan">
            <.input
              field={@form[:email]}
              type="email"
              label={gettext("Lanttern user email")}
              phx-debounce="1500"
            />
            <p class="flex items-center gap-2 mt-4">
              <.icon name="hero-information-circle-mini" class="text-ltrn-subtle" />
              <%= gettext("Enables the user to login at Lanttern via Google Sign In") %>
            </p>
          </.card_base>
        </.form>
        <:actions_left :if={@student.id}>
          <.action
            type="button"
            theme="subtle"
            size="md"
            phx-click="deactivate"
            phx-target={@myself}
            data-confirm={gettext("Are you sure? You can reactive the student later.")}
          >
            <%= gettext("Deactivate") %>
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
          <.action type="submit" theme="primary" size="md" icon_name="hero-check" form="student-form">
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
  def update(
        %{action: {ClassesFieldComponent, {:changed, selected_classes_ids}}},
        socket
      ),
      do: {:ok, assign(socket, :selected_classes_ids, selected_classes_ids)}

  def update(%{student: %Student{}} = assigns, socket) do
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
    student = socket.assigns.student
    changeset = Schools.change_student(student)

    selected_classes_ids = Enum.map(student.classes, & &1.id)

    socket
    |> assign(:form, to_form(changeset))
    |> assign(:selected_classes_ids, selected_classes_ids)
  end

  # event handlers

  @impl true
  def handle_event("validate", %{"student" => student_params}, socket),
    do: {:noreply, assign_validated_form(socket, student_params)}

  def handle_event("save", %{"student" => student_params}, socket) do
    student_params =
      inject_extra_params(socket, student_params)

    save_student(socket, socket.assigns.student.id, student_params)
  end

  def handle_event("deactivate", _, socket) do
    Schools.deactivate_student(socket.assigns.student)
    |> case do
      {:ok, student} ->
        notify(__MODULE__, {:deactivated, student}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp assign_validated_form(socket, params) do
    params = inject_extra_params(socket, params)

    changeset =
      socket.assigns.student
      |> Schools.change_student(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  # inject params handled in backend
  defp inject_extra_params(socket, params) do
    params
    |> Map.put("school_id", socket.assigns.student.school_id)
    |> Map.put("classes_ids", socket.assigns.selected_classes_ids)
  end

  defp save_student(socket, nil, student_params) do
    Schools.create_student(student_params)
    |> case do
      {:ok, student} ->
        notify(__MODULE__, {:created, student}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_student(socket, _id, student_params) do
    Schools.update_student(
      socket.assigns.student,
      student_params
    )
    |> case do
      {:ok, student} ->
        notify(__MODULE__, {:updated, student}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
