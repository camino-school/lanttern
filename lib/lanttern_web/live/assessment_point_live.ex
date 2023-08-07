defmodule LantternWeb.AssessmentPointLive do
  use LantternWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    {:noreply, assign(socket, :id, id)}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <h1 class="font-display font-black text-3xl">Assessment points details <%= @id %></h1>
      <div class="flex items-center mt-2 font-display font-bold text-xs text-slate-400">
        <.link href={~p"/assessment-points"} class="underline">Assessment points</.link>
        <span class="mx-1">/</span>
        <.link href={~p"/assessment-points/explorer"} class="underline">Explorer</.link>
        <span class="mx-1">/</span>
        <span>Details</span>
      </div>
    </div>
    <div class="container mx-auto lg:max-w-5xl mt-10">
      <.link href={~p"/assessment-points/explorer"} class="flex items-center text-sm text-slate-400">
        <.icon name="hero-arrow-left-mini" class="text-cyan-400 mr-2" />
        <span class="underline">Back to explorer</span>
      </.link>
      <div class="w-full p-6 mt-4 rounded shadow-xl bg-white">
        <h2 class="font-display font-black text-2xl">Assessment point name</h2>
        <p class="mt-4 text-sm">
          Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        </p>
        <div class="flex items-center mt-10">
          <.icon name="hero-calendar" class="text-rose-500 mr-4" /> Aug 07, 2023, 09:30 am
        </div>
        <div class="flex items-center mt-4">
          <.icon name="hero-view-columns" class="text-rose-500 mr-4" /> Camino School Levels
          <div class="flex items-center">
            <%= for ov <- [%{name: "Lack of evidence"}, %{name: "Emerging"}, %{name: "Progressing"}, %{name: "Achieving"}, %{name: "Exceeding"}] do %>
              <.ordinal_value ordinal_value={ov} />
            <% end %>
          </div>
        </div>
        <table class="w-full mt-20">
          <thead>
            <tr>
              <th></th>
              <th>
                <div class="flex items-center font-display font-bold text-slate-400">
                  <.icon name="hero-view-columns" class="mr-4" /> Level
                </div>
              </th>
              <th>
                <div class="flex items-center font-display font-bold text-slate-400">
                  <.icon name="hero-pencil-square" class="mr-4" /> Notes and observations
                </div>
              </th>
            </tr>
          </thead>
          <tbody>
            <%= for i <- 1..9 do %>
              <.level_row student={%{id: i}} />
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  attr :ordinal_value, :map, required: true

  def ordinal_value(assigns) do
    ~H"""
    <div class="p-1 ml-2 rounded-[1px] font-mono text-xs bg-slate-200">
      <%= @ordinal_value.name %>
    </div>
    """
  end

  attr :student, :map, required: true

  def level_row(assigns) do
    ~H"""
    <tr>
      <td>Student <%= @student.id %></td>
      <td>Level</td>
      <td>Obs</td>
    </tr>
    """
  end
end
