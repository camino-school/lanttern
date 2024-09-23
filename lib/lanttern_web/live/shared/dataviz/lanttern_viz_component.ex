defmodule LantternWeb.Dataviz.LantternVizComponent do
  @moduledoc """
  Renders a "Lanttern visualization" component
  """

  use LantternWeb, :live_component

  alias Lanttern.LearningContext

  @impl true
  def render(assigns) do
    ~H"""
    <canvas id={@id} phx-hook="LantternViz" class={@class}></canvas>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> push_assessment_points_data()

    {:ok, socket}
  end

  defp push_assessment_points_data(socket) do
    strand =
      LearningContext.get_strand(socket.assigns.strand_id,
        preloads: [
          :assessment_points,
          moments: :assessment_points
        ]
      )

    strand_goals =
      strand.assessment_points
      |> Enum.map(& &1.curriculum_item_id)

    moments_assessment_points =
      strand.moments
      |> Enum.map(&Enum.map(&1.assessment_points, fn ap -> ap.curriculum_item_id end))

    socket
    |> push_event("build_lanttern_viz", %{
      strand_goals: strand_goals,
      moments_assessment_points: moments_assessment_points
    })
  end

  # def update(assigns, socket) do
  #   %{assessment_point: assessment_point} = assigns

  #   curriculum_item =
  #     case assessment_point.curriculum_item_id do
  #       nil -> nil
  #       id -> Curricula.get_curriculum_item!(id, preloads: :curriculum_component)
  #     end

  #   curriculum_item_options =
  #     case assigns do
  #       %{curriculum_from_strand_id: strand_id} ->
  #         Curricula.list_strand_curriculum_items(strand_id, preloads: :curriculum_component)
  #         |> Enum.map(&{"(#{&1.curriculum_component.name}) #{&1.name}", &1.id})

  #       _ ->
  #         nil
  #     end
  #     |> maybe_add_extra_curriculum_item_option(curriculum_item, assigns)

  #   socket =
  #     socket
  #     |> assign(assigns)
  #     |> assign(:form, to_form(Assessments.change_assessment_point(assessment_point)))
  #     |> assign(:selected_curriculum_item, curriculum_item)
  #     |> assign(:curriculum_item_options, curriculum_item_options)

  #   {:ok, socket}
  # end

  # defp maybe_add_extra_curriculum_item_option(curriculum_item_options, curriculum_item, assigns) do
  #   # for cases when we have existing assessment points using curriculum items
  #   # that were removed from strand, we add one extra curriculum item option
  #   # using the current assessment point curriculum item

  #   curriculum_item_id =
  #     case curriculum_item do
  #       nil -> nil
  #       curriculum_item -> curriculum_item.id
  #     end

  #   curriculum_item_options_ids =
  #     case curriculum_item_options do
  #       nil -> []
  #       curriculum_item_options -> Enum.map(curriculum_item_options, fn {_name, id} -> id end)
  #     end

  #   case {assigns, curriculum_item_id in curriculum_item_options_ids, curriculum_item_id} do
  #     {%{curriculum_from_strand_id: _}, false, ci_id} when not is_nil(ci_id) ->
  #       (curriculum_item_options ++
  #          [
  #            {"#{gettext("Not linked to strand")} - (#{curriculum_item.curriculum_component.name}) #{curriculum_item.name}",
  #             curriculum_item.id}
  #          ])
  #       |> Enum.uniq()

  #     _ ->
  #       curriculum_item_options
  #   end
  # end

  # # event handlers

  # def handle_event("remove_curriculum_item", _params, socket) do
  #   # basically a manual "validate" event to update curriculum_item id
  #   params =
  #     socket.assigns.form.params
  #     |> Map.put("curriculum_item_id", nil)

  #   form =
  #     socket.assigns.form.data
  #     |> Assessments.change_assessment_point(params)
  #     |> Map.put(:action, :validate)
  #     |> to_form()

  #   {:noreply,
  #    socket
  #    |> assign(:selected_curriculum_item, nil)
  #    |> assign(:form, form)}
  # end

  # def handle_event("validate", %{"assessment_point" => params}, socket) do
  #   form =
  #     socket.assigns.assessment_point
  #     |> Assessments.change_assessment_point(params)
  #     |> Map.put(:action, :validate)
  #     |> to_form()

  #   {:noreply, assign(socket, form: form)}
  # end

  # def handle_event("save", %{"assessment_point" => params}, socket) do
  #   # inject strand and moment id in params
  #   assessment_point = socket.assigns.assessment_point

  #   params =
  #     params
  #     |> Map.put("strand_id", assessment_point.strand_id)
  #     |> Map.put("moment_id", assessment_point.moment_id)

  #   save(socket, assessment_point.id, params)
  # end

  # defp save(socket, nil, params) do
  #   case Assessments.create_assessment_point(params) do
  #     {:ok, _assessment_point} ->
  #       {:noreply,
  #        socket
  #        |> handle_navigation()}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign(socket, form: to_form(changeset))}
  #   end
  # end

  # defp save(socket, _assessment_point_id, params) do
  #   case Assessments.update_assessment_point(socket.assigns.assessment_point, params) do
  #     {:ok, _assessment_point} ->
  #       {:noreply,
  #        socket
  #        |> handle_navigation()}

  #     {:error, %Ecto.Changeset{} = changeset} ->
  #       {:noreply, assign(socket, form: to_form(changeset))}
  #   end
  # end
end
