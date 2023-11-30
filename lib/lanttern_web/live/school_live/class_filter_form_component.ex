defmodule LantternWeb.SchoolLive.ClassFilterFormComponent do
  @moduledoc """
  Class filter form component.

  This form is used inside a `<.slide_over>` component,
  where the "submit" button is rendered.
  """

  use LantternWeb, :live_component
  alias Lanttern.Schools
  import LantternWeb.Helpers.NotifyHelpers

  def render(assigns) do
    ~H"""
    <div>
      <.form id="class-filter-form" for={@form} phx-submit="save" phx-target={@myself}>
        <div class="flex gap-6">
          <fieldset class="flex-1">
            <legend class="text-base font-semibold leading-6 text-ltrn-subtle">Classes</legend>
            <div class="mt-4 divide-y divide-ltrn-lighter border-b border-t border-ltrn-lighter">
              <.check_field
                :for={opt <- @classes}
                id={"class-#{opt.id}"}
                field={@form[:classes_ids]}
                opt={opt}
              />
            </div>
          </fieldset>
        </div>
      </.form>
    </div>
    """
  end

  # lifecycle

  def update(%{current_user: current_user} = assigns, socket) do
    classes_ids = Map.get(assigns, :classes_ids, [])

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:classes, Schools.list_user_classes(current_user))
     |> assign(:form, to_form(%{"classes_ids" => classes_ids}, as: :classes))}
  end

  # event handlers

  def handle_event("save", params, socket) do
    params = Map.get(params, "classes", %{"classes_ids" => []})
    notify_parent(__MODULE__, {:save, params}, socket.assigns)
    notify_component(__MODULE__, {:save, params}, socket.assigns)
    {:noreply, socket}
  end
end
