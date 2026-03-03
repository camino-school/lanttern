defmodule LantternWeb.Schools.GuardianFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `Guardian` form

  ### Attrs

      attr :guardian, Guardian, required: true
      attr :title, :string, required: true
      attr :on_cancel, :any, required: true, doc: "`<.slide_over>` `on_cancel` attr"
      attr :current_scope, Lanttern.Accounts.Scope, required: true

  ## Notification and navigation

  After successful save or delete, the component uses `notify/3` and `handle_navigation/2`
  with a tagged tuple:

  - `{:created, guardian}` — after creation
  - `{:updated, guardian}` — after update
  - `{:deleted, guardian}` — after deletion

  """

  use LantternWeb, :live_component

  alias Lanttern.Repo
  alias Lanttern.Schools

  # shared
  alias LantternWeb.Schools.StudentSearchComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.slide_over id={@id} show on_cancel={@on_cancel}>
        <:title>{@title}</:title>
        <.form
          id="guardian-form"
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
          <div class="mb-6">
            <.live_component
              module={StudentSearchComponent}
              id="student-search"
              notify_component={@myself}
              label={gettext("Students")}
              refocus_on_select="true"
              school_id={@guardian.school_id}
            />
            <%= if @students != [] do %>
              <ol class="mt-4 text-sm leading-relaxed list-decimal list-inside">
                <li :for={student <- @students} id={"selected-student-#{student.id}"}>
                  {student.name}
                  <.button
                    type="button"
                    icon_name="hero-x-mark-mini"
                    class="align-middle"
                    size="sm"
                    theme="ghost"
                    rounded
                    phx-click={
                      JS.push("remove_student", value: %{"id" => student.id}, target: @myself)
                    }
                  />
                </li>
              </ol>
            <% else %>
              <.empty_state_simple class="mt-4">
                {gettext("No students added to this guardian")}
              </.empty_state_simple>
            <% end %>
          </div>
        </.form>
        <:actions_left :if={@guardian.id}>
          <.button
            type="button"
            theme="ghost"
            phx-click={
              JS.push("delete", target: @myself)
              |> JS.exec("phx-remove", to: "##{@id}")
            }
            data-confirm={gettext("Are you sure?")}
          >
            {gettext("Delete")}
          </.button>
        </:actions_left>
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={@on_cancel}
          >
            {gettext("Cancel")}
          </.button>
          <.button
            type="submit"
            theme="primary"
            size="md"
            icon_name="hero-check"
            form="guardian-form"
          >
            {gettext("Save")}
          </.button>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  @impl true
  def update(
        %{action: {StudentSearchComponent, {:selected, student}}},
        socket
      ) do
    students =
      [student | socket.assigns.students]
      |> Enum.uniq()
      |> Enum.sort_by(& &1.name)

    selected_students_ids = Enum.map(students, & &1.id)

    {:ok, assign(socket, students: students, selected_students_ids: selected_students_ids)}
  end

  def update(%{guardian: guardian} = assigns, socket) do
    changeset = Schools.change_guardian(assigns.current_scope, guardian)

    socket =
      socket
      |> assign(assigns)
      |> assign(:current_scope, assigns.current_scope)
      |> assign_form(changeset)
      |> assign_students()

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"guardian" => params}, socket) do
    changeset =
      Schools.change_guardian(
        socket.assigns.current_scope,
        socket.assigns.guardian,
        params
      )
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"guardian" => params}, socket) do
    save_guardian(socket, socket.assigns.guardian.id, params)
  end

  def handle_event("remove_student", %{"id" => id}, socket) do
    students =
      socket.assigns.students
      |> Enum.reject(&(&1.id == id))

    selected_students_ids = Enum.map(students, & &1.id)

    {:noreply, assign(socket, students: students, selected_students_ids: selected_students_ids)}
  end

  def handle_event("delete", _params, socket) do
    case Schools.delete_guardian(
           socket.assigns.current_scope,
           socket.assigns.guardian
         ) do
      {:ok, guardian} ->
        msg = {:deleted, guardian}
        notify(__MODULE__, msg, socket.assigns)
        {:noreply, handle_navigation(socket, msg)}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  defp save_guardian(socket, nil, params) do
    changeset = socket.assigns.form.source
    params = changeset_to_params(changeset, params)
    scope = socket.assigns.current_scope

    case Schools.create_guardian(scope, params) do
      {:ok, guardian} ->
        {:ok, _} =
          Schools.set_guardian_students(scope, guardian, socket.assigns.selected_students_ids)

        msg = {:created, guardian}
        notify(__MODULE__, msg, socket.assigns)
        {:noreply, handle_navigation(socket, msg)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_guardian(socket, _id, params) do
    changeset = socket.assigns.form.source
    params = changeset_to_params(changeset, params)
    scope = socket.assigns.current_scope

    case Schools.update_guardian(scope, socket.assigns.guardian, params) do
      {:ok, guardian} ->
        {:ok, _} =
          Schools.set_guardian_students(scope, guardian, socket.assigns.selected_students_ids)

        msg = {:updated, guardian}
        notify(__MODULE__, msg, socket.assigns)
        {:noreply, handle_navigation(socket, msg)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp changeset_to_params(%Ecto.Changeset{} = changeset, params) do
    data = changeset.data

    %{
      name: Ecto.Changeset.get_field(changeset, :name, params["name"] || data.name)
    }
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp assign_students(socket) do
    # Load students that are currently associated with the guardian
    students =
      case socket.assigns.guardian.students do
        students when is_list(students) ->
          students

        _ ->
          socket.assigns.guardian
          |> Repo.preload(:students)
          |> Map.get(:students, [])
      end

    selected_students_ids = Enum.map(students, & &1.id)

    socket
    |> assign(:students, students)
    |> assign(:selected_students_ids, selected_students_ids)
  end
end
