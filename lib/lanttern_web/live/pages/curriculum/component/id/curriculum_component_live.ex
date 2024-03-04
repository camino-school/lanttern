defmodule LantternWeb.CurriculumComponentLive do
  use LantternWeb, :live_view

  alias Lanttern.Curricula
  alias Lanttern.Personalization
  alias Lanttern.Taxonomy

  @impl true
  def mount(_params, _session, socket) do
    subjects = Taxonomy.list_subjects()
    years = Taxonomy.list_years()

    current_filters =
      case Personalization.get_profile_settings(socket.assigns.current_user.current_profile_id) do
        %{current_filters: current_filters} -> current_filters
        _ -> %{}
      end

    selected_subjects_ids = Map.get(current_filters, :subjects_ids, [])
    selected_years_ids = Map.get(current_filters, :years_ids, [])

    selected_subjects = Enum.filter(subjects, &(&1.id in selected_subjects_ids))
    selected_years = Enum.filter(years, &(&1.id in selected_years_ids))

    socket =
      socket
      |> assign(:subjects, subjects)
      |> assign(:years, years)
      |> assign(:selected_subjects_ids, selected_subjects_ids)
      |> assign(:selected_years_ids, selected_years_ids)
      |> assign(:selected_subjects, selected_subjects)
      |> assign(:selected_years, selected_years)
      |> assign(:show_subjects_filter, false)
      |> assign(:show_years_filter, false)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    socket =
      socket
      |> assign(
        :curriculum_component,
        Curricula.get_curriculum_component!(id, preloads: :curriculum)
      )
      |> stream_curriculum_items()

    {:noreply, socket}
  end

  defp stream_curriculum_items(socket) do
    curriculum_items =
      Curricula.list_curriculum_items(
        components_ids: [socket.assigns.curriculum_component.id],
        subjects_ids: socket.assigns.selected_subjects_ids,
        years_ids: socket.assigns.selected_years_ids
      )

    socket
    |> stream(
      :curriculum_items,
      curriculum_items,
      reset: true
    )
    |> assign(:curriculum_items_count, length(curriculum_items))
  end

  @impl true
  def handle_event("show_subjects_filter", _, socket) do
    {:noreply, assign(socket, :show_subjects_filter, true)}
  end

  def handle_event("hide_subjects_filter", _, socket) do
    {:noreply, assign(socket, :show_subjects_filter, false)}
  end

  def handle_event("toggle_subject_id", %{"id" => id}, socket) do
    selected_subjects_ids =
      case id in socket.assigns.selected_subjects_ids do
        true ->
          socket.assigns.selected_subjects_ids
          |> Enum.filter(&(&1 != id))

        false ->
          [id | socket.assigns.selected_subjects_ids]
      end

    {:noreply, assign(socket, :selected_subjects_ids, selected_subjects_ids)}
  end

  def handle_event("clear_subjects_filter", _, socket) do
    Personalization.set_profile_current_filters(
      socket.assigns.current_user,
      %{subjects_ids: []}
    )

    {:noreply,
     push_navigate(socket, to: ~p"/curriculum/component/#{socket.assigns.curriculum_component}")}
  end

  def handle_event("save_selected_subjects_ids", _, socket) do
    Personalization.set_profile_current_filters(
      socket.assigns.current_user,
      %{subjects_ids: socket.assigns.selected_subjects_ids}
    )

    {:noreply,
     push_navigate(socket, to: ~p"/curriculum/component/#{socket.assigns.curriculum_component}")}
  end

  def handle_event("show_years_filter", _, socket) do
    {:noreply, assign(socket, :show_years_filter, true)}
  end

  def handle_event("hide_years_filter", _, socket) do
    {:noreply, assign(socket, :show_years_filter, false)}
  end

  def handle_event("toggle_year_id", %{"id" => id}, socket) do
    selected_years_ids =
      case id in socket.assigns.selected_years_ids do
        true ->
          socket.assigns.selected_years_ids
          |> Enum.filter(&(&1 != id))

        false ->
          [id | socket.assigns.selected_years_ids]
      end

    {:noreply, assign(socket, :selected_years_ids, selected_years_ids)}
  end

  def handle_event("clear_years_filter", _, socket) do
    Personalization.set_profile_current_filters(
      socket.assigns.current_user,
      %{years_ids: []}
    )

    {:noreply,
     push_navigate(socket, to: ~p"/curriculum/component/#{socket.assigns.curriculum_component}")}
  end

  def handle_event("save_selected_years_ids", _, socket) do
    Personalization.set_profile_current_filters(
      socket.assigns.current_user,
      %{years_ids: socket.assigns.selected_years_ids}
    )

    {:noreply,
     push_navigate(socket, to: ~p"/curriculum/component/#{socket.assigns.curriculum_component}")}
  end
end
