defmodule LantternWeb.AssessmentPointsLive do
  use LantternWeb, :live_view

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Schools
  alias Lanttern.Taxonomy

  # shared components
  alias LantternWeb.Assessments.AssessmentPointEntryEditorComponent
  alias LantternWeb.Assessments.AssessmentPointCreateFormComponent

  # function components

  attr :items, :list, required: true
  attr :type, :string, required: true

  def filter_buttons(%{items: []} = assigns) do
    ~H"""
    <button type="button" phx-click={show_filter()} class="underline hover:text-ltrn-primary">
      all <%= @type %>
    </button>
    """
  end

  def filter_buttons(%{items: items, type: type} = assigns) do
    items =
      if length(items) > 3 do
        {first_two, rest} = Enum.split(items, 2)

        first_two
        |> Enum.map_join(" / ", & &1.name)
        |> Kernel.<>(" / + #{length(rest)} #{type}")
      else
        items
        |> Enum.map_join(" / ", & &1.name)
      end

    assigns = assign(assigns, :items, items)

    ~H"""
    <button type="button" phx-click={show_filter()} class="underline hover:text-ltrn-primary">
      <%= @items %>
    </button>
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
      <.profile_icon_with_name
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
              module={AssessmentPointEntryEditorComponent}
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
    # 🚧 disable this view temporarily (see issues #112 and #123)
    if !socket.assigns.current_user.is_root_admin,
      do: raise(LantternWeb.NotFoundError)

    socket =
      socket
      |> assign(:page_title, gettext("Assessment points explorer"))

    {:ok, socket, temporary_assigns: [assessment_points: []]}
  end

  def handle_params(params, _uri, socket) do
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
    {subjects_in_assessments, other_subjects} = Taxonomy.list_assessment_points_subjects()
    all_subjects = subjects_in_assessments ++ other_subjects

    current_classes =
      case params_classes_ids do
        nil -> []
        ids -> classes |> Enum.filter(&("#{&1.id}" in ids))
      end

    current_subjects =
      case params_subjects_ids do
        nil -> []
        ids -> all_subjects |> Enum.filter(&("#{&1.id}" in ids))
      end

    %{
      assessment_points: assessment_points,
      students_and_entries: students_and_entries
    } =
      Assessments.list_students_assessment_points_grid(
        classes_ids: params_classes_ids,
        subjects_ids: params_subjects_ids
      )

    socket =
      socket
      |> assign(:assessment_points, assessment_points)
      |> assign(:students_and_entries, students_and_entries)
      |> assign(:form, form)
      |> assign(:classes, classes)
      |> assign(:subjects_in_assessments, subjects_in_assessments)
      |> assign(:other_subjects, other_subjects)
      |> assign(:subjects, all_subjects)
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
      |> push_navigate(to: path(socket, ~p"/assessment_points?#{path_params}"))

    {:noreply, socket}
  end

  def handle_event("clear_filters", _params, socket) do
    socket =
      socket
      |> push_navigate(to: path(socket, ~p"/assessment_points"))

    {:noreply, socket}
  end

  # info handlers

  def handle_info({AssessmentPointCreateFormComponent, {:created, assessment_point}}, socket),
    do: {:noreply, push_navigate(socket, to: ~p"/assessment_points/#{assessment_point.id}")}

  def handle_info(
        {
          AssessmentPointEntryEditorComponent,
          {
            :error,
            %Ecto.Changeset{errors: [score: {score_error, _}]} = _changeset
          }
        },
        socket
      ) do
    socket =
      socket
      |> put_flash(:error, score_error)

    {:noreply, socket}
  end

  def handle_info({AssessmentPointEntryEditorComponent, {:error, _changeset}}, socket) do
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

  defp clear_filters(js \\ %JS{}) do
    js
    |> JS.push("clear_filters")
    |> JS.exec("data-cancel", to: "#explorer-filters")
  end
end
