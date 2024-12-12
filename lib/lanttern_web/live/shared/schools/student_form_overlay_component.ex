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
  alias Lanttern.Schools.Cycle
  alias Lanttern.Schools.Student

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
          <div>
            <.label><%= gettext("Classes") %></.label>
            <%= if @selected_classes != [] do %>
              <.badge_button_picker
                id="current-class-picker"
                on_select={
                  &(JS.push("unselect_class", value: %{"id" => &1}, target: @myself)
                    |> JS.dispatch("change", to: "#student-form"))
                }
                items={@selected_classes}
                selected_ids={@selected_classes_ids}
                label_setter="class_with_cycle"
              />
            <% else %>
              <.empty_state_simple><%= gettext("No linked classes") %></.empty_state_simple>
            <% end %>
            <div :if={@cycle_classes != []} class="mt-6">
              <p class="mb-2"><%= gettext("%{cycle} cycle classes", cycle: @current_cycle.name) %></p>
              <.badge_button_picker
                id="class-cycle-select"
                on_select={
                  &(JS.push("select_cycle_class", value: %{"id" => &1}, target: @myself)
                    |> JS.dispatch("change", to: "#student-form"))
                }
                items={@cycle_classes}
                selected_ids={@selected_classes_ids}
              />
            </div>
            <.select
              name="other_classes"
              prompt={
                if @cycle_classes != [],
                  do: gettext("Other cycle classes"),
                  else: gettext("Select a class")
              }
              options={@other_cycle_classes_options}
              value=""
              phx-change="select_other_cycle_class"
              phx-target={@myself}
              class="mt-6"
            />
            <%!-- <div :if={@form.source.action in [:insert, :update]}>
              <.error :for={{msg, _} <- @form[:classes_ids].errors}><%= msg %></.error>
            </div> --%>
          </div>
        </.form>
        <:actions_left :if={@student.id}>
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
          <.button type="submit" form="student-form">
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
    |> assign_classes()
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

  defp assign_classes(socket) do
    school_id = socket.assigns.student.school_id
    all_classes = Schools.list_classes(schools_ids: [school_id])

    selected_classes =
      Enum.filter(all_classes, &(&1.id in socket.assigns.selected_classes_ids))

    socket
    |> assign(:all_classes, all_classes)
    |> assign(:selected_classes, selected_classes)
    |> assign_cycle_classes()
    |> assign_other_cycle_classes_options()
  end

  defp assign_cycle_classes(socket) do
    cycle_classes =
      case socket.assigns do
        %{current_cycle: %Cycle{} = cycle} ->
          Enum.filter(socket.assigns.all_classes, &(&1.cycle_id == cycle.id))

        _ ->
          []
      end
      |> Enum.filter(&(&1.id not in socket.assigns.selected_classes_ids))

    assign(socket, :cycle_classes, cycle_classes)
  end

  defp assign_other_cycle_classes_options(socket) do
    cycle_id =
      case socket.assigns do
        %{current_cycle: %Cycle{} = cycle} -> cycle.id
        _ -> nil
      end

    other_cycle_classes_options =
      socket.assigns.all_classes
      |> Enum.filter(fn class ->
        class.cycle_id != cycle_id &&
          class.id not in socket.assigns.selected_classes_ids
      end)
      |> Enum.map(&{"#{&1.name} (#{&1.cycle.name})", &1.id})

    assign(socket, :other_cycle_classes_options, other_cycle_classes_options)
  end

  # event handlers

  @impl true
  def handle_event("unselect_class", %{"id" => id}, socket) do
    selected_classes_ids =
      Enum.reject(socket.assigns.selected_classes_ids, &(&1 == id))

    selected_classes =
      socket.assigns.all_classes
      |> Enum.filter(&(&1.id in selected_classes_ids))

    socket =
      socket
      |> assign(:selected_classes_ids, selected_classes_ids)
      |> assign(:selected_classes, selected_classes)
      |> assign_cycle_classes()
      |> assign_other_cycle_classes_options()
      |> assign_validated_form(socket.assigns.form.params)

    {:noreply, socket}
  end

  def handle_event("select_cycle_class", %{"id" => id}, socket) do
    selected_classes_ids =
      [id | socket.assigns.selected_classes_ids]

    selected_classes =
      socket.assigns.all_classes
      |> Enum.filter(&(&1.id in selected_classes_ids))

    socket =
      socket
      |> assign(:selected_classes_ids, selected_classes_ids)
      |> assign(:selected_classes, selected_classes)
      |> assign_cycle_classes()
      |> assign_validated_form(socket.assigns.form.params)

    {:noreply, socket}
  end

  def handle_event("select_other_cycle_class", %{"other_classes" => id}, socket) do
    id = String.to_integer(id)

    selected_classes_ids =
      [id | socket.assigns.selected_classes_ids]

    selected_classes =
      socket.assigns.all_classes
      |> Enum.filter(&(&1.id in selected_classes_ids))

    socket =
      socket
      |> assign(:selected_classes_ids, selected_classes_ids)
      |> assign(:selected_classes, selected_classes)
      |> assign_other_cycle_classes_options()
      |> assign_validated_form(socket.assigns.form.params)

    {:noreply, socket}
  end

  def handle_event("validate", %{"student" => student_params}, socket),
    do: {:noreply, assign_validated_form(socket, student_params)}

  def handle_event("save", %{"student" => student_params}, socket) do
    student_params =
      inject_extra_params(socket, student_params)

    save_student(socket, socket.assigns.student.id, student_params)
  end

  def handle_event("delete", _, socket) do
    Schools.delete_student(socket.assigns.student)
    |> case do
      {:ok, student} ->
        notify(__MODULE__, {:deleted, student}, socket.assigns)
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
