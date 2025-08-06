defmodule LantternWeb.Schools.StudentFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `Student` form

  ### Attrs

      attr :student, Student, required: true, doc: "requires virtual `email` loaded"
      attr :current_cycle, Cycle, doc: "used to separate current cycle from other classes"
      attr :title, :string, required: true
      attr :on_cancel, :any, required: true, doc: "`<.slide_over>` `on_cancel` attr"
      attr :notify_parent, :boolean
      attr :notify_component, Phoenix.LiveComponent.CID

  """

  use LantternWeb, :live_component

  alias Lanttern.Repo

  alias Lanttern.Schools
  alias Lanttern.Schools.Student
  alias Lanttern.StudentTags

  # shared

  alias LantternWeb.Schools.ClassesFieldComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over id={@id} show={true} on_cancel={@on_cancel}>
        <:title>{@title}</:title>
        <.form
          id={"student-form-#{@id}"}
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
          <.live_component
            module={ClassesFieldComponent}
            id={"student-form-classes-picker-#{@id}"}
            class="mb-6"
            label={gettext("Classes")}
            school_id={@student.school_id}
            current_cycle={@current_cycle}
            selected_classes_ids={@selected_classes_ids}
            notify_component={@myself}
          />
          <div class="mb-6">
            <.label>{gettext("Student tags")}</.label>
            <%= if @student_tags != [] do %>
              <.badge_button_picker
                id={"student-tags-picker-#{@id}"}
                on_select={
                  &(JS.push("toggle_student_tag", value: %{"id" => &1}, target: @myself)
                    |> JS.dispatch("change", to: "#student-form-#{@id}"))
                }
                items={@student_tags}
                selected_ids={@selected_student_tags_ids}
                use_color_map_as_active
              />
            <% else %>
              <.empty_state_simple>{gettext("No selected classes")}</.empty_state_simple>
            <% end %>
          </div>
          <.card_base class="p-4" bg_class="bg-ltrn-mesh-cyan">
            <.input
              field={@form[:email]}
              type="email"
              label={gettext("Lanttern user email")}
              phx-debounce="1500"
            />
            <p class="flex items-center gap-2 mt-4">
              <.icon name="hero-information-circle-mini" class="text-ltrn-subtle" />
              {gettext("Enables the user to login at Lanttern via Google Sign In")}
            </p>
          </.card_base>
        </.form>
        <:actions_left :if={@student.id}>
          <.action
            :if={is_nil(@student.deactivated_at)}
            type="button"
            theme="subtle"
            size="md"
            phx-click="deactivate"
            phx-target={@myself}
            data-confirm={gettext("Are you sure? You can reactive the student later.")}
          >
            {gettext("Deactivate")}
          </.action>
          <.action
            :if={@student.deactivated_at}
            type="button"
            theme="subtle"
            size="md"
            phx-click="delete"
            phx-target={@myself}
            data-confirm={gettext("Are you sure?")}
          >
            {gettext("Delete")}
          </.action>
          <.action
            :if={@student.deactivated_at}
            type="button"
            theme="subtle"
            size="md"
            phx-click="reactivate"
            phx-target={@myself}
          >
            {gettext("Reactivate")}
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
            form={"student-form-#{@id}"}
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
    |> assign_student_tags()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_form(socket) do
    student =
      socket.assigns.student
      |> ensure_classes_preload()
      |> ensure_tags_preload()
      |> ensure_student_tag_relationships_preload()

    changeset = Schools.change_student(student)

    selected_classes_ids = Enum.map(student.classes, & &1.id)
    selected_student_tags_ids = Enum.map(student.tags, & &1.id)

    socket
    |> assign(:student, student)
    |> assign(:form, to_form(changeset))
    |> assign(:selected_classes_ids, selected_classes_ids)
    |> assign(:selected_student_tags_ids, selected_student_tags_ids)
  end

  defp ensure_classes_preload(%Student{classes: classes} = student) when not is_list(classes) do
    Repo.preload(student, [:classes])
  end

  defp ensure_classes_preload(student), do: student

  defp ensure_tags_preload(%Student{tags: tags} = student) when not is_list(tags) do
    Repo.preload(student, [:tags])
  end

  defp ensure_tags_preload(student), do: student

  defp ensure_student_tag_relationships_preload(
         %Student{student_tag_relationships: student_tag_relationships} = student
       )
       when not is_list(student_tag_relationships) do
    Repo.preload(student, [:student_tag_relationships])
  end

  defp ensure_student_tag_relationships_preload(student), do: student

  defp assign_student_tags(socket) do
    student_tags = StudentTags.list_student_tags(school_id: socket.assigns.student.school_id)

    socket
    |> assign(:student_tags, student_tags)
  end

  # event handlers

  @impl true
  def handle_event("validate", %{"student" => student_params}, socket),
    do: {:noreply, assign_validated_form(socket, student_params)}

  def handle_event("toggle_student_tag", %{"id" => tag_id}, socket) do
    selected_student_tags_ids =
      if tag_id in socket.assigns.selected_student_tags_ids,
        do: Enum.filter(socket.assigns.selected_student_tags_ids, fn id -> id != tag_id end),
        else: [tag_id | socket.assigns.selected_student_tags_ids]

    {:noreply, assign(socket, :selected_student_tags_ids, selected_student_tags_ids)}
  end

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

  def handle_event("reactivate", _, socket) do
    Schools.reactivate_student(socket.assigns.student)
    |> case do
      {:ok, student} ->
        notify(__MODULE__, {:reactivated, student}, socket.assigns)
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
    |> Map.put("tags_ids", socket.assigns.selected_student_tags_ids)
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
