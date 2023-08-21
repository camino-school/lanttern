defmodule LantternWeb.AssessmentPointLive do
  use LantternWeb, :live_view

  alias Lanttern.Assessments
  alias Lanttern.Grading

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
      <div class="relative w-full p-6 mt-4 rounded shadow-xl bg-white">
        <.button class="absolute top-2 right-2" theme="ghost" phx-click="update">
          Edit
        </.button>
        <div class="max-w-screen-sm">
          <h2 class="font-display font-black text-2xl"><%= @assessment_point.name %></h2>
          <p :if={@assessment_point.description} class="mt-4 text-sm">
            <%= @assessment_point.description %>
          </p>
        </div>
        <div class="flex items-center mt-10">
          <.icon name="hero-calendar" class="text-rose-500 mr-4" /> Date: <%= @formatted_datetime %>
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
        <div :if={length(@assessment_point.classes) > 0} class="flex items-center mt-4">
          <.icon name="hero-squares-2x2" class="text-rose-500 mr-4" /> Classes:
          <.classes classes={@assessment_point.classes} />
        </div>
        <div class="mt-20">
          <div class="flex items-center gap-2">
            <div class="shrink-0 w-1/4"></div>
            <div class={[
              "flex items-center gap-2 font-display font-bold text-slate-400",
              if(
                @assessment_point.scale.type == "ordinal",
                do: "flex-[2_0]",
                else: "flex-[1_0]"
              )
            ]}>
              <.icon name="hero-view-columns" />
              <span>Marking</span>
            </div>
            <div class="flex-[2_0] items-center gap-2 font-display font-bold text-slate-400">
              <.icon name="hero-pencil-square" />
              <span>Notes and observations</span>
            </div>
          </div>
          <.live_component
            :for={entry <- @entries}
            module={LantternWeb.AssessmentPointEntryRowFormComponent}
            id={entry.id}
            entry={entry}
            ordinal_value_options={@ordinal_value_options}
            scale={@assessment_point.scale}
          />
        </div>
      </div>
    </div>
    <.live_component
      module={LantternWeb.AssessmentPointUpdateOverlayComponent}
      id={@assessment_point_id}
      show={@is_updating}
    />
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    try do
      Assessments.get_assessment_point!(id, [
        :curriculum_item,
        :scale,
        :classes
      ])
    rescue
      _ ->
        socket =
          socket
          |> put_flash(:error, "Couldn't find assessment point")
          |> redirect(to: ~p"/assessment_points")

        {:noreply, socket}
    else
      assessment_point ->
        entries =
          Assessments.list_assessment_point_entries(
            preloads: [:student, :ordinal_value],
            assessment_point_id: assessment_point.id
          )
          |> Enum.sort_by(& &1.student.name)

        ordinal_values =
          if assessment_point.scale.type == "ordinal" do
            Grading.list_ordinal_values_from_scale(assessment_point.scale.id)
          else
            nil
          end

        ordinal_value_options =
          if is_list(ordinal_values) do
            ordinal_values |> Enum.map(fn ov -> {:"#{ov.name}", ov.id} end)
          else
            []
          end

        formatted_datetime =
          Timex.format!(
            Timex.local(assessment_point.datetime),
            "{Mshort} {D}, {YYYY}, {h12}:{m} {am}"
          )

        socket =
          socket
          |> assign(:assessment_point, assessment_point)
          |> assign(:entries, entries)
          |> assign(:ordinal_values, ordinal_values)
          |> assign(:ordinal_value_options, ordinal_value_options)
          |> assign(:formatted_datetime, formatted_datetime)
          |> assign(:assessment_point_id, id)
          |> assign(:is_updating, false)

        {:noreply, socket}
    end
  end

  def handle_event("update", _params, socket) do
    {:noreply, assign(socket, :is_updating, true)}
  end

  def handle_event("cancel-assessment-point-update", _params, socket) do
    {:noreply, assign(socket, :is_updating, false)}
  end

  def handle_info({:assessment_point_updated, assessment_point}, socket) do
    socket =
      socket
      |> assign(:is_updating, false)
      |> put_flash(:info, "Assessment point updated!")
      |> push_navigate(to: ~p"/assessment_points/#{assessment_point.id}", replace: true)

    {:noreply, socket}
  end

  def handle_info(
        {:save_error, %Ecto.Changeset{errors: [score: {score_error, _}]} = _changeset},
        socket
      ) do
    socket =
      socket
      |> put_flash(:error, score_error)

    {:noreply, socket}
  end

  def handle_info({:save_error, _changeset}, socket) do
    socket =
      socket
      |> put_flash(:error, "Something is not right")

    {:noreply, socket}
  end

  attr :ordinal_values, :list, required: true

  def ordinal_values(assigns) do
    ~H"""
    <div :if={@ordinal_values} class="flex items-center gap-2 ml-2">
      <%= for ov <- @ordinal_values do %>
        <.badge get_bagde_color_from={ov}>
          <%= ov.name %>
        </.badge>
      <% end %>
    </div>
    """
  end

  attr :classes, :list, required: true

  def classes(assigns) do
    ~H"""
    <div class="flex items-center gap-2 ml-2">
      <%= for c <- @classes do %>
        <.badge>
          <%= c.name %>
        </.badge>
      <% end %>
    </div>
    """
  end
end
