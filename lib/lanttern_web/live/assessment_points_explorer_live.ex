defmodule LantternWeb.AssessmentPointsExplorerLive do
  use LantternWeb, :live_view

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint

  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <h1 class="font-display font-black text-3xl">Assessment points explorer</h1>
      <div class="flex items-center mt-2 font-display font-bold text-xs text-ltrn-subtle">
        <.link patch={~p"/assessment_points"} class="underline">Assessment points</.link>
        <span class="mx-1">/</span>
        <span>Explorer</span>
      </div>
    </div>
    <div class="container mx-auto lg:max-w-5xl mt-10">
      <div class="flex items-center text-sm">
        <p>Exploring: all disciplines | all grade 4 classes | this bimester</p>
        <button class="flex items-center ml-4 text-ltrn-subtle">
          <.icon name="hero-funnel-mini" class="text-ltrn-primary mr-2" />
          <span class="underline">Change</span>
        </button>
      </div>
    </div>
    <div class="relative w-full max-h-screen pb-6 mt-6 rounded shadow-xl bg-white overflow-x-auto">
      <div class="sticky top-0 z-20 flex items-stretch gap-4 pr-6 mb-2 bg-white">
        <div class="sticky left-0 z-20 shrink-0 w-40 bg-white"></div>
        <.assessment_point :for={ap <- @assessment_points} assessment_point={ap} />
        <div class="shrink-0 w-2"></div>
      </div>
      <.student_and_entries
        :for={{student, entries} <- @students_and_entries}
        student={student}
        entries={entries}
      />
    </div>
    """
  end

  attr :assessment_point, AssessmentPoint, required: true

  def assessment_point(assigns) do
    ~H"""
    <div class="shrink-0 w-40 pt-6 pb-2 bg-white">
      <div class="flex gap-1 items-center mb-1 text-xs text-ltrn-subtle">
        <.icon name="hero-calendar-mini" />
        <%= Timex.format!(@assessment_point.datetime, "{Mshort} {0D}") %>
      </div>
      <.link
        patch={~p"/assessment_points/#{@assessment_point.id}"}
        class="text-xs hover:underline line-clamp-2"
      >
        <%= @assessment_point.name %>
      </.link>
    </div>
    """
  end

  attr :student, Lanttern.Schools.Student, required: true
  attr :entries, :list, required: true

  def student_and_entries(assigns) do
    ~H"""
    <div class="flex items-stretch gap-4">
      <.icon_with_name
        class="sticky left-0 z-10 shrink-0 w-40 px-6 bg-white"
        profile_name={@student.name}
      />
      <%= for entry <- @entries do %>
        <div class="shrink-0 w-40 min-h-[4rem] py-1">
          <%= if entry == nil do %>
            <.base_input
              class="w-full h-full rounded-sm font-mono text-center bg-ltrn-subtle"
              value="N/A"
              name="na"
              readonly
            />
          <% else %>
            <.live_component
              module={LantternWeb.AssessmentPointEntryEditorComponent}
              id={entry.id}
              entry={entry}
              class="w-full h-full"
              wrapper_class="w-full h-full"
            >
              <:marking_input class="w-full h-full" />
            </.live_component>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # lifecycle

  def mount(_params, _session, socket) do
    {:ok, socket, temporary_assigns: [assessment_points: []]}
  end

  def handle_params(_params, _uri, socket) do
    %{
      assessment_points: assessment_points,
      students_and_entries: students_and_entries
    } =
      Assessments.list_students_assessment_points_grid()

    socket =
      socket
      |> assign(:assessment_points, assessment_points)
      |> assign(:students_and_entries, students_and_entries)

    {:noreply, socket}
  end

  # info handlers

  def handle_info(
        {:assessment_point_entry_save_error,
         %Ecto.Changeset{errors: [score: {score_error, _}]} = _changeset},
        socket
      ) do
    socket =
      socket
      |> put_flash(:error, score_error)

    {:noreply, socket}
  end

  def handle_info({:assessment_point_entry_save_error, _changeset}, socket) do
    socket =
      socket
      |> put_flash(:error, "Something is not right")

    {:noreply, socket}
  end
end
