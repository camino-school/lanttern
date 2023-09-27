defmodule LantternWeb.AssessmentPointsExplorerLive do
  use LantternWeb, :live_view

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Schools
  alias Lanttern.Taxonomy

  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <.page_title_with_menu>Assessment points explorer</.page_title_with_menu>
      <div class="flex items-center mt-2 font-display font-bold text-xs text-ltrn-subtle">
        <.link navigate={~p"/assessment_points"} class="underline">Assessment points</.link>
        <span class="mx-1">/</span>
        <span>Explorer</span>
      </div>
    </div>
    <div class="container mx-auto lg:max-w-5xl mt-10">
      <div class="flex items-center text-sm">
        <p class="flex items-center gap-2">
          1 result in
          <%= if @current_classes == [] do %>
            <.badge>all classes</.badge>
          <% else %>
            <.badge :for={class <- @current_classes}>
              <%= class.name %>
            </.badge>
          <% end %>
          <span>|</span>
          <%= if @current_subjects == [] do %>
            <.badge>all subjects</.badge>
          <% else %>
            <.badge :for={sub <- @current_subjects}>
              <%= sub.name %>
            </.badge>
          <% end %>
        </p>
        <button class="flex items-center ml-4 text-ltrn-subtle" phx-click={show_filter()}>
          <.icon name="hero-funnel-mini" class="text-ltrn-primary mr-2" />
          <span class="underline">Filter</span>
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
    <.slide_over id="explorer-filters">
      <:title>Filter Assessment Points</:title>
      <.form id="explorer-filters-form" for={@form} phx-submit={filter()} class="flex gap-6">
        <fieldset class="flex-1">
          <legend class="text-base font-semibold leading-6 text-ltrn-subtle">Classes</legend>
          <div class="mt-4 divide-y divide-ltrn-hairline border-b border-t border-ltrn-hairline">
            <.check_field
              :for={opt <- @classes}
              id={"class-#{opt.id}"}
              field={@form[:classes_ids]}
              opt={opt}
            />
          </div>
        </fieldset>
        <fieldset class="flex-1">
          <legend class="text-base font-semibold leading-6 text-ltrn-subtle">Subjects</legend>
          <div class="mt-4 divide-y divide-ltrn-hairline border-b border-t border-ltrn-hairline">
            <.check_field
              :for={opt <- @subjects}
              id={"subject-#{opt.id}"}
              field={@form[:subjects_ids]}
              opt={opt}
            />
          </div>
        </fieldset>
      </.form>
      <:actions>
        <.button
          type="button"
          theme="ghost"
          phx-click={JS.exec("data-cancel", to: "#explorer-filters")}
        >
          Cancel
        </.button>
        <.button type="submit" form="explorer-filters-form" phx-disable-with="Applying filters...">
          Apply filters
        </.button>
      </:actions>
    </.slide_over>
    """
  end

  # function components

  attr :id, :string, required: true

  attr :opt, :map,
    required: true,
    doc: "Instance of `Lanttern.Taxonomy.Subject` or `Lanttern.Schools.Class`"

  attr :field, Phoenix.HTML.FormField, required: true

  def check_field(assigns) do
    ~H"""
    <div class="relative flex items-start py-4">
      <div class="min-w-0 flex-1 text-sm leading-6">
        <label for={@id} class="select-none text-ltrn-text">
          <%= @opt.name %>
        </label>
      </div>
      <div class="ml-3 flex h-6 items-center">
        <input
          id={@id}
          name={@field.name <> "[]"}
          type="checkbox"
          value={@opt.id}
          class="h-4 w-4 rounded border-ltrn-subtle text-ltrn-primary focus:ring-ltrn-primary"
          checked={"#{@opt.id}" in @field.value}
        />
      </div>
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
        navigate={~p"/assessment_points/#{@assessment_point.id}"}
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

  def handle_params(params, _uri, socket) do
    %{
      assessment_points: assessment_points,
      students_and_entries: students_and_entries
    } =
      Assessments.list_students_assessment_points_grid()

    params_classes_ids =
      case Map.get(params, "classes_ids") do
        ids when is_list(ids) -> ids
        _ -> nil
      end

    params_subjects_ids =
      case Map.get(params, "subjects_ids") do
        ids when is_list(ids) -> ids
        _ -> nil
      end

    form =
      %{
        "classes_ids" => params_classes_ids || [],
        "subjects_ids" => params_subjects_ids || []
      }
      |> Phoenix.Component.to_form()

    classes = Schools.list_classes()
    subjects = Taxonomy.list_subjects()

    current_classes =
      case params_classes_ids do
        nil -> []
        ids -> classes |> Enum.filter(&("#{&1.id}" in ids))
      end

    current_subjects =
      case params_subjects_ids do
        nil -> []
        ids -> subjects |> Enum.filter(&("#{&1.id}" in ids))
      end

    socket =
      socket
      |> assign(:assessment_points, assessment_points)
      |> assign(:students_and_entries, students_and_entries)
      |> assign(:form, form)
      |> assign(:classes, classes)
      |> assign(:subjects, subjects)
      |> assign(:current_classes, current_classes)
      |> assign(:current_subjects, current_subjects)

    {:noreply, socket}
  end

  # event handlers

  def handle_event("filter", params, socket) do
    path_params =
      %{
        classes_ids: Map.get(params, "classes_ids"),
        subjects_ids: Map.get(params, "subjects_ids")
      }

    socket =
      socket
      |> push_navigate(to: path(socket, ~p"/assessment_points/explorer?#{path_params}"))

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

  # helpers

  defp show_filter(js \\ %JS{}) do
    js
    # |> JS.push("show-filter")
    |> JS.exec("data-show", to: "#explorer-filters")
  end

  defp filter(js \\ %JS{}) do
    js
    |> JS.push("filter")
    |> JS.exec("data-cancel", to: "#explorer-filters")
  end
end
