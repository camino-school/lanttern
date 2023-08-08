defmodule LantternWeb.AssessmentPointLive do
  use LantternWeb, :live_view

  alias Lanttern.Assessments
  alias Lanttern.Grading

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    try do
      Assessments.get_assessment_point!(id, [:curriculum_item, :scale])
    rescue
      _ ->
        socket =
          socket
          |> put_flash(:error, "Couldn't find assessment point \"#{id}\"")
          |> redirect(to: ~p"/assessment_points")

        {:noreply, socket}
    else
      assessment_point ->
        ordinal_values =
          if assessment_point.scale.type == "ordinal" do
            Grading.list_ordinal_values_from_scale(assessment_point.scale.id)
          else
            nil
          end

        socket =
          socket
          |> assign(:assessment_point, assessment_point)
          |> assign(:ordinal_values, ordinal_values)

        {:noreply, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <h1 class="font-display font-black text-3xl">Assessment point details</h1>
      <div class="flex items-center mt-2 font-display font-bold text-xs text-slate-400">
        <.link patch={~p"/assessment_points"} class="underline">Assessment points</.link>
        <span class="mx-1">/</span>
        <.link patch={~p"/assessment_points/explorer"} class="underline">Explorer</.link>
        <span class="mx-1">/</span>
        <span>Details</span>
      </div>
    </div>
    <div class="container mx-auto lg:max-w-5xl mt-10">
      <.link patch={~p"/assessment_points/explorer"} class="flex items-center text-sm text-slate-400">
        <.icon name="hero-arrow-left-mini" class="text-cyan-400 mr-2" />
        <span class="underline">Back to explorer</span>
      </.link>
      <div class="w-full p-6 mt-4 rounded shadow-xl bg-white">
        <div class="max-w-screen-sm">
          <h2 class="font-display font-black text-2xl"><%= @assessment_point.name %></h2>
          <p :if={@assessment_point.description} class="mt-4 text-sm">
            <%= @assessment_point.description %>
          </p>
        </div>
        <div class="flex items-center mt-10">
          <.icon name="hero-calendar" class="text-rose-500 mr-4" />
          Date: <%= Timex.format!(@assessment_point.date, "{Mshort} {D}, {YYYY}, {h12}:{m} {am}") %>
        </div>
        <div class="flex items-center mt-4">
          <.icon name="hero-bookmark" class="text-rose-500 mr-4" />
          Curriculum: <%= @assessment_point.curriculum_item.name %>
        </div>
        <div class="flex items-center mt-4">
          <.icon name="hero-view-columns" class="text-rose-500 mr-4" />
          Scale: <%= @assessment_point.scale.name %>
          <.ordinal_values ordinal_values={@ordinal_values} />
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

  attr :ordinal_values, :list, required: true

  def ordinal_values(assigns) do
    ~H"""
    <div :if={@ordinal_values} class="flex items-center">
      <%= for ov <- @ordinal_values do %>
        <div class="p-1 ml-2 rounded-[1px] font-mono text-xs bg-slate-200">
          <%= ov.name %>
        </div>
      <% end %>
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