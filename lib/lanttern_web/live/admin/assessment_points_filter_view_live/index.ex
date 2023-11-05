defmodule LantternWeb.Admin.AssessmentPointsFilterViewLive.Index do
  use LantternWeb, {:live_view, layout: :admin}

  alias Lanttern.Explorer
  alias Lanttern.Explorer.AssessmentPointsFilterView

  @impl true
  def mount(_params, _session, socket) do
    assessment_points_filter_views =
      Explorer.list_assessment_points_filter_views(
        preloads: [:classes, :subjects, profile: [:teacher, :student]]
      )

    {:ok, stream(socket, :assessment_points_filter_views, assessment_points_filter_views)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Assessment points filter view")
    |> assign(
      :assessment_points_filter_view,
      Explorer.get_assessment_points_filter_view!(id,
        preloads: [:classes, :subjects, profile: [:teacher, :student]]
      )
    )
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Assessment points filter view")
    |> assign(:assessment_points_filter_view, %AssessmentPointsFilterView{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Assessment points filter views")
    |> assign(:assessment_points_filter_view, nil)
  end

  @impl true
  def handle_info(
        {LantternWeb.Admin.AssessmentPointsFilterViewLive.FormComponent,
         {:saved, assessment_points_filter_view}},
        socket
      ) do
    assessment_points_filter_view =
      Explorer.get_assessment_points_filter_view!(assessment_points_filter_view.id,
        preloads: [:classes, :subjects, profile: [:teacher, :student]]
      )

    {:noreply,
     stream_insert(socket, :assessment_points_filter_views, assessment_points_filter_view)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    assessment_points_filter_view = Explorer.get_assessment_points_filter_view!(id)
    {:ok, _} = Explorer.delete_assessment_points_filter_view(assessment_points_filter_view)

    {:noreply,
     stream_delete(socket, :assessment_points_filter_views, assessment_points_filter_view)}
  end

  def profile_name(%{type: "teacher"} = profile),
    do: profile.teacher.name

  def profile_name(%{type: "student"} = profile),
    do: profile.student.name
end
