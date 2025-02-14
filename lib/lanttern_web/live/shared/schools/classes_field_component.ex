defmodule LantternWeb.Schools.ClassesFieldComponent do
  @moduledoc """
  Renders a classes picker to use in forms.

  The component displays the user school and current cycle classes by default,
  but also handles classes from other cycles search and rendering.

  This component uses the `selected_classes_ids` to handle the UI rendering. On change,
  it notifies the parent view/component with the updated selected classes ids but doesn't
  "save" it internally — it expects the parent updated `selected_classes_ids` to rerender
  the updated UI.

  ### Attrs

      attr :label, :string, required: true
      attr :selected_classes_ids, :list, required: true, doc: "the selected classes ids list"
      attr :school_id, :integer, required: true, doc: "used to filter classes"
      attr :current_cycle, Cycle, required: true, doc: "used to manage the classes lists"
      attr :notify_parent, :boolean
      attr :notify_component, Phoenix.LiveComponent.CID
      attr :class, :any

  """

  use LantternWeb, :live_component

  alias Lanttern.Schools
  alias Lanttern.Schools.Cycle

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.label><%= @label %></.label>
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
          current_user_or_cycle={@current_cycle}
        />
      <% else %>
        <.empty_state_simple><%= gettext("No selected classes") %></.empty_state_simple>
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
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_classes()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_all_classes()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_all_classes(socket) do
    all_classes = Schools.list_classes(schools_ids: [socket.assigns.school_id])
    assign(socket, :all_classes, all_classes)
  end

  defp assign_classes(socket) do
    selected_classes =
      Enum.filter(
        socket.assigns.all_classes,
        &(&1.id in socket.assigns.selected_classes_ids)
      )

    socket
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
    updated_selected_classes_ids =
      Enum.reject(socket.assigns.selected_classes_ids, &(&1 == id))

    notify_change(socket, updated_selected_classes_ids)

    {:noreply, socket}
  end

  def handle_event("select_cycle_class", %{"id" => id}, socket) do
    updated_selected_classes_ids =
      [id | socket.assigns.selected_classes_ids]

    notify_change(socket, updated_selected_classes_ids)

    {:noreply, socket}
  end

  def handle_event("select_other_cycle_class", %{"other_classes" => id}, socket) do
    id = String.to_integer(id)

    updated_selected_classes_ids =
      [id | socket.assigns.selected_classes_ids]

    notify_change(socket, updated_selected_classes_ids)

    {:noreply, socket}
  end

  defp notify_change(socket, selected_classes_ids),
    do:
      notify(
        __MODULE__,
        {:changed, selected_classes_ids},
        socket.assigns
      )
end
