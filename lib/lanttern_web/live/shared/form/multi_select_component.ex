defmodule LantternWeb.Form.MultiSelectComponent do
  @moduledoc """
  Renders a multi select form component
  """

  use LantternWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.input
        field={@field}
        type="select"
        label={@label}
        options={@options}
        prompt={@prompt}
        phx-change="selected"
        phx-target={@myself}
        show_optional={@show_optional}
      />
      <div class="flex flex-wrap gap-1 mt-2">
        <.badge :if={length(@selected_options) == 0}>
          <%= @empty_message %>
        </.badge>
        <.badge
          :for={{name, id} <- @selected_options}
          id={"#{name}-#{id}"}
          theme="cyan"
          on_remove={JS.push("remove", value: %{id: id}, target: @myself)}
          phx-target={@myself}
        >
          <%= name %>
        </.badge>
      </div>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:class, nil)
     |> assign(:show_optional, false)
     |> assign(:selected_options, [])}
  end

  @impl true
  def update(%{selected_ids: selected_ids, options: options} = assigns, socket) do
    selected_options =
      selected_ids
      |> Enum.reduce([], fn id, selected_options ->
        selected = extract_from_options(options, id)

        selected_options
        |> merge_with_selected(selected)
      end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:selected_options, selected_options)}
  end

  # event handlers

  @impl true
  def handle_event("selected", params, socket) do
    field = socket.assigns.field.field |> Atom.to_string()

    case params[socket.assigns.field.form.name][field] do
      "" ->
        {:noreply, socket}

      id ->
        id = String.to_integer(id)
        selected = extract_from_options(socket.assigns.options, id)

        selected_options =
          socket.assigns.selected_options
          |> merge_with_selected(selected)

        notify_component(
          __MODULE__,
          {:change, socket.assigns.multi_field, options_to_ids(selected_options)},
          socket.assigns
        )

        {:noreply, socket}
    end
  end

  def handle_event("remove", %{"id" => id}, socket) do
    selected_options =
      socket.assigns.selected_options
      |> remove_from_selected(id)

    notify_component(
      __MODULE__,
      {:change, socket.assigns.multi_field, options_to_ids(selected_options)},
      socket.assigns
    )

    {:noreply, socket}
  end

  # helpers

  defp extract_from_options(options, id) do
    Enum.find(
      options,
      fn {_key, value} -> value == id end
    )
  end

  defp merge_with_selected(selected, new) do
    (selected ++ [new])
    |> Enum.uniq()
  end

  defp remove_from_selected(selected, id) do
    Enum.filter(
      selected,
      fn {_key, value} -> value != id end
    )
  end

  defp options_to_ids(options),
    do: Enum.map(options, fn {_key, value} -> value end)
end
