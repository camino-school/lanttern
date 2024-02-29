defmodule LantternWeb.ReportCardLive.GradesComponent do
  use LantternWeb, :live_component

  alias Lanttern.Schools
  alias Lanttern.Taxonomy

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-10">
      <div class="container mx-auto lg:max-w-5xl">
        <h3 class="font-display font-bold text-2xl">
          <%= gettext("Grades report grid") %>
        </h3>
        <p class="mt-4">
          <%= gettext("Select subjects and cycles to build the grades report grid.") %>
        </p>
        <div class="flex items-start gap-6 mt-6">
          <div class="flex-1 flex flex-wrap gap-2">
            <.badge :for={subject <- @subjects}>
              <%= subject.name %>
            </.badge>
          </div>
          <div class="flex-1 flex flex-wrap gap-2">
            <.badge :for={cycle <- @cycles}>
              <%= cycle.name %>
            </.badge>
          </div>
        </div>
        <div class="mt-10 p-10 rounded bg-white shadow-lg">
          TBD
        </div>
      </div>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:subjects, Taxonomy.list_subjects())
      |> assign(:cycles, Schools.list_cycles(order_by: [asc: :end_at, desc: :start_at]))

    {:ok, socket}
  end
end
