defmodule LantternWeb.Schools.StudentFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `Student` form
  """

  use LantternWeb, :live_component

  alias Lanttern.Schools
  alias Lanttern.Schools.Student
  # alias Lanttern.Taxonomy

  # shared
  # alias LantternWeb.Schools.StudentSearchComponent

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
            <.badge_button_picker
              id="class-cycle-select"
              on_select={
                &(JS.push("select_class", value: %{"id" => &1}, target: @myself)
                  |> JS.dispatch("change", to: "#student-form"))
              }
              items={@classes}
              selected_ids={@selected_classes_ids}
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
  # def update(%{action: {StudentSearchComponent, {:selected, student}}}, socket) do
  #   students =
  #     [student | socket.assigns.students]
  #     |> Enum.uniq()
  #     |> Enum.sort_by(& &1.name)

  #   {:ok, assign(socket, :students, students)}
  # end

  def update(%{student: %Student{}} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_form()
      |> assign_classes()
      |> assign(:initialized, true)

    {:ok, socket}
  end

  defp assign_form(socket) do
    student = socket.assigns.student
    changeset = Schools.change_student(student)

    selected_classes_ids = Enum.map(student.classes, & &1.id)

    socket
    |> assign(:form, to_form(changeset))
    |> assign(:selected_classes_ids, selected_classes_ids)
  end

  defp assign_classes(%{assigns: %{initialized: false}} = socket) do
    school_id = socket.assigns.student.school_id
    classes = Schools.list_classes(schools_ids: [school_id])
    assign(socket, :classes, classes)
  end

  # event handlers

  @impl true
  def handle_event("select_class", %{"id" => id}, socket) do
    selected_classes_ids =
      if id in socket.assigns.selected_classes_ids,
        do: Enum.reject(socket.assigns.selected_classes_ids, &(&1 == id)),
        else: [id | socket.assigns.selected_classes_ids]

    socket =
      socket
      |> assign(:selected_classes_ids, selected_classes_ids)
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
