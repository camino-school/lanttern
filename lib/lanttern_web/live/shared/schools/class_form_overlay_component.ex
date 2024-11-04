defmodule LantternWeb.Schools.ClassFormOverlayComponent do
  @moduledoc """
  Renders an overlay with a `Class` form
  """

  use LantternWeb, :live_component

  alias Lanttern.Schools
  alias Lanttern.Schools.Class
  alias Lanttern.Taxonomy

  # shared
  alias LantternWeb.Schools.StudentSearchComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.slide_over id="class-form-overlay" show={true} on_cancel={@on_cancel}>
        <:title><%= @title %></:title>
        <.form
          id="class-form"
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
          <div class="mb-6">
            <.label><%= gettext("Cycle") %></.label>
            <.badge_button_picker
              id="class-cycle-select"
              on_select={
                &(JS.push("select_cycle", value: %{"id" => &1}, target: @myself)
                  |> JS.dispatch("change", to: "#class-form"))
              }
              items={@cycles}
              selected_ids={[@selected_cycle_id]}
            />
            <div :if={@form.source.action in [:insert, :update]}>
              <.error :for={{msg, _} <- @form[:cycle_id].errors}><%= msg %></.error>
            </div>
          </div>
          <div class="mb-6">
            <.label><%= gettext("Year") %></.label>
            <.badge_button_picker
              id="class-year-select"
              on_select={
                &(JS.push("select_year", value: %{"id" => &1}, target: @myself)
                  |> JS.dispatch("change", to: "#class-form"))
              }
              items={@years}
              selected_ids={@selected_years_ids}
            />
            <div :if={@form.source.action in [:insert, :update]}>
              <.error :for={{msg, _} <- @form[:years_ids].errors}><%= msg %></.error>
            </div>
          </div>
          <div class="mb-6">
            <.live_component
              module={StudentSearchComponent}
              id="student-search"
              notify_component={@myself}
              label={gettext("Students in this class")}
              refocus_on_select="true"
            />
            <%= if @students != [] do %>
              <ol class="mt-4 text-sm leading-relaxed list-decimal list-inside">
                <li :for={student <- @students} id={"selected-student-#{student.id}"}>
                  <%= student.name %>
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
                <%= gettext("No students added to this class") %>
              </.empty_state_simple>
            <% end %>
            <%!-- <div :if={@form.source.action in [:insert, :update]}>
              <.error :for={{msg, _} <- @form[:students_ids].errors}><%= msg %></.error>
            </div> --%>
          </div>
        </.form>
        <:actions_left :if={@class.id}>
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
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#class-form-overlay")}
          >
            <%= gettext("Cancel") %>
          </.button>
          <.button type="submit" form="class-form">
            <%= gettext("Save") %>
          </.button>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:show_delete, false)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(%{action: {StudentSearchComponent, {:selected, student}}}, socket) do
    students =
      [student | socket.assigns.students]
      |> Enum.uniq()
      |> Enum.sort_by(& &1.name)

    {:ok, assign(socket, :students, students)}
  end

  def update(%{class: %Class{}} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      # |> assign_selected_students()
      |> assign_form()
      |> assign_cycles()
      |> assign_years()
      |> assign_students()
      |> assign(:initialized, true)

    {:ok, socket}
  end

  defp assign_form(socket) do
    class = socket.assigns.class
    changeset = Schools.change_class(class)

    selected_years_ids = Enum.map(class.years, & &1.id)

    socket
    |> assign(:form, to_form(changeset))
    |> assign(:selected_cycle_id, class.cycle_id)
    |> assign(:selected_years_ids, selected_years_ids)
  end

  defp assign_cycles(%{assigns: %{initialized: false}} = socket) do
    school_id = socket.assigns.current_user.current_profile.school_id
    cycles = Schools.list_cycles(schools_ids: [school_id])
    assign(socket, :cycles, cycles)
  end

  defp assign_cycles(socket), do: socket

  defp assign_years(%{assigns: %{initialized: false}} = socket) do
    # school_id = socket.assigns.current_user.current_profile.scho
    years = Taxonomy.list_years()
    assign(socket, :years, years)
  end

  defp assign_years(socket), do: socket

  defp assign_students(%{assigns: %{initialized: false}} = socket) do
    students =
      case socket.assigns.class.id do
        nil -> []
        class_id -> Schools.list_students(class_id: class_id)
      end

    assign(socket, :students, students)
  end

  defp assign_students(socket), do: socket

  # event handlers

  @impl true
  def handle_event("remove_student", %{"id" => id}, socket) do
    students =
      socket.assigns.students
      |> Enum.reject(&(&1.id == id))

    {:noreply, assign(socket, :students, students)}
  end

  def handle_event("select_cycle", %{"id" => id}, socket) do
    socket =
      socket
      |> assign(:selected_cycle_id, id)
      |> assign_validated_form(socket.assigns.form.params)

    {:noreply, socket}
  end

  def handle_event("select_year", %{"id" => id}, socket) do
    selected_years_ids =
      if id in socket.assigns.selected_years_ids,
        do: Enum.reject(socket.assigns.selected_years_ids, &(&1 == id)),
        else: [id | socket.assigns.selected_years_ids]

    socket =
      socket
      |> assign(:selected_years_ids, selected_years_ids)
      |> assign_validated_form(socket.assigns.form.params)

    {:noreply, socket}
  end

  def handle_event("validate", %{"class" => class_params}, socket),
    do: {:noreply, assign_validated_form(socket, class_params)}

  def handle_event("save", %{"class" => class_params}, socket) do
    class_params =
      inject_extra_params(socket, class_params)

    save_class(socket, socket.assigns.class.id, class_params)
  end

  def handle_event("delete", _, socket) do
    Schools.delete_class(socket.assigns.class)
    |> case do
      {:ok, class} ->
        notify(__MODULE__, {:deleted, class}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp assign_validated_form(socket, params) do
    params = inject_extra_params(socket, params)

    changeset =
      socket.assigns.class
      |> Schools.change_class(params)
      |> Map.put(:action, :validate)

    assign(socket, :form, to_form(changeset))
  end

  # inject params handled in backend
  defp inject_extra_params(socket, params) do
    params
    |> Map.put("school_id", socket.assigns.current_user.current_profile.school_id)
    |> Map.put("cycle_id", socket.assigns.selected_cycle_id)
    |> Map.put("years_ids", socket.assigns.selected_years_ids)
    |> Map.put("students_ids", socket.assigns.students |> Enum.map(& &1.id))

    # |> Map.put("students_ids", socket.assigns.selected_students_ids)
  end

  defp save_class(socket, nil, class_params) do
    Schools.create_class(class_params)
    |> case do
      {:ok, class} ->
        notify(__MODULE__, {:created, class}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  defp save_class(socket, _id, class_params) do
    Schools.update_class(
      socket.assigns.class,
      class_params
    )
    |> case do
      {:ok, class} ->
        notify(__MODULE__, {:updated, class}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end
end
