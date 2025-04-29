defmodule LantternWeb.Grading.GradeCompositionOverlayComponent do
  @moduledoc """
  ### About assessment points list active UI state handling

  As we are using streams for assessment points listing, we can't update the
  item without inserting the whole item into the stream. That's why we are
  using `JS` to handle the assessment point item classes.

  Check https://elixirforum.com/t/54663

  """

  use LantternWeb, :live_component

  alias Lanttern.GradesReports
  alias Lanttern.Grading
  alias Lanttern.Grading.GradeComponent
  alias Lanttern.Reporting

  import Lanttern.Utils, only: [swap: 3]

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.slide_over id={@id} show={true} on_cancel={@on_cancel}>
        <:title><%= @title %></:title>
        <%= if length(@indexed_grade_components) == 0 do %>
          <.empty_state>
            <%= gettext("No assesment points in this grade composition") %>
          </.empty_state>
        <% else %>
          <div class="grid grid-cols-[minmax(0,_1fr)_repeat(2,_max-content)] gap-x-4 gap-y-2">
            <div class="grid grid-cols-subgrid col-span-3 px-4 py-2 rounded-sm mt-4 text-sm text-ltrn-subtle bg-ltrn-lighter">
              <div><%= gettext("Strand goal") %></div>
              <div class="text-right"><%= gettext("Weight") %></div>
            </div>
            <.grade_component_form
              :for={{grade_component, i} <- @indexed_grade_components}
              id={"report-card-grade-component-#{grade_component.id}"}
              grade_component={grade_component}
              myself={@myself}
              index={i}
              is_last={i + 1 == length(@indexed_grade_components)}
            />
          </div>
        <% end %>
        <div :if={@use_assessment_points_from_report_card_id} class="mt-10">
          <h5 class="font-display font-bold">
            <%= gettext("All report card strands' goals") %>
          </h5>
          <div id="report-card-assessment-points" phx-update="stream">
            <.card_base
              :for={{dom_id, assessment_point} <- @streams.assessment_points}
              id={dom_id}
              class={[
                "group flex items-center gap-4 p-4 mt-2",
                if(
                  assessment_point.id in @grade_composition_assessment_point_ids,
                  do: "active"
                )
              ]}
              {if(
                assessment_point.id in @grade_composition_assessment_point_ids,
                do: %{bg_class: "bg-ltrn-mesh-cyan"}, else: %{}
              )}
            >
              <div class="flex-1">
                <p class="text-xs">
                  <%= assessment_point.strand.name %>
                  <span :if={assessment_point.strand.type}>
                    (<%= assessment_point.strand.type %>)
                  </span>
                </p>
                <p class="mt-2 text-sm">
                  <.badge><%= assessment_point.curriculum_item.curriculum_component.name %></.badge>
                  <.badge :if={assessment_point.is_differentiation} theme="diff">
                    <%= gettext("Diff") %>
                  </.badge>
                  <%= assessment_point.curriculum_item.name %>
                </p>
              </div>
              <div class="hidden group-[.active]:block p-2">
                <.icon name="hero-check" class="text-ltrn-primary" />
              </div>
              <.icon_button
                type="button"
                theme="ghost"
                name="hero-plus"
                phx-click={
                  JS.push("add_assessment_point_to_grade_comp",
                    value: %{id: assessment_point.id},
                    target: @myself
                  )
                  |> JS.remove_class("bg-white", to: "##{dom_id}")
                  |> JS.add_class("bg-ltrn-mesh-cyan active", to: "##{dom_id}")
                }
                sr_text={gettext("Add to grade composition")}
                rounded
                class="group-[.active]:hidden"
              />
            </.card_base>
          </div>
        </div>
      </.slide_over>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :grade_component, GradeComponent, required: true
  attr :index, :integer, required: true
  attr :is_last, :boolean, required: true
  attr :myself, Phoenix.LiveComponent.CID, required: true

  def grade_component_form(assigns) do
    form =
      assigns.grade_component
      |> GradeComponent.changeset(%{})
      |> to_form()

    assigns =
      assigns
      |> assign(:form, form)

    ~H"""
    <.form
      id={@id}
      for={@form}
      class="grid grid-cols-subgrid col-span-3"
      phx-change={JS.push("update_grade_component", target: @myself)}
      phx-value-id={@grade_component.id}
    >
      <.card_base
        class="grid grid-cols-subgrid col-span-3 items-center p-4"
        bg_class="bg-ltrn-mesh-cyan"
      >
        <div>
          <p class="text-xs">
            <%= @grade_component.assessment_point.strand.name %>
            <span :if={@grade_component.assessment_point.strand.type}>
              (<%= @grade_component.assessment_point.strand.type %>)
            </span>
          </p>
          <p class="mt-2 text-sm">
            <.badge>
              <%= @grade_component.assessment_point.curriculum_item.curriculum_component.name %>
            </.badge>
            <.badge :if={@grade_component.assessment_point.is_differentiation} theme="diff">
              <%= gettext("Diff") %>
            </.badge>
            <%= @grade_component.assessment_point.curriculum_item.name %>
          </p>
        </div>
        <input
          type="number"
          name={@form[:weight].name}
          value={@form[:weight].value}
          step="0.01"
          min="0"
          phx-debounce="1500"
          class="w-20 rounded-xs border-none text-right text-sm bg-ltrn-lightest"
        />
        <div class="flex flex-col items-center gap-1">
          <.icon_button
            type="button"
            sr_text={gettext("Move up")}
            name="hero-chevron-up-mini"
            theme="ghost"
            rounded
            size="sm"
            phx-click={
              JS.push("swap_grade_components_position",
                value: %{from: @index, to: @index - 1},
                target: @myself
              )
            }
            disabled={@index == 0}
          />
          <.icon_button
            type="button"
            theme="ghost"
            name="hero-x-mark"
            phx-click={
              JS.push("delete_grade_component_from_composition",
                value: %{id: @grade_component.id},
                target: @myself
              )
              |> JS.remove_class("bg-ltrn-mesh-cyan active",
                to: "#assessment_points-#{@grade_component.assessment_point_id}"
              )
              |> JS.add_class("bg-white",
                to: "#assessment_points-#{@grade_component.assessment_point_id}"
              )
            }
            sr_text={gettext("Remove")}
            rounded
          />
          <.icon_button
            type="button"
            sr_text={gettext("Move down")}
            name="hero-chevron-down-mini"
            theme="ghost"
            rounded
            size="sm"
            phx-click={
              JS.push("swap_grade_components_position",
                value: %{from: @index, to: @index + 1},
                target: @myself
              )
            }
            disabled={@is_last}
          />
        </div>
      </.card_base>
    </.form>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:indexed_grade_components, [])
      |> assign(:grade_composition_assessment_point_ids, [])
      |> assign(:use_assessment_points_from_report_card_id, nil)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    grade_components =
      GradesReports.list_grade_composition(
        assigns.grades_report_cycle_id,
        assigns.grades_report_subject_id
      )

    grade_composition_assessment_point_ids =
      grade_components
      |> Enum.map(& &1.assessment_point_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(:indexed_grade_components, Enum.with_index(grade_components))
      |> assign(:grade_composition_assessment_point_ids, grade_composition_assessment_point_ids)
      |> assign_assessment_points(assigns)

    {:ok, socket}
  end

  defp assign_assessment_points(socket, %{
         use_assessment_points_from_report_card_id: report_card_id
       }) do
    assessment_points = Reporting.list_report_card_assessment_points(report_card_id)

    socket
    |> stream(:assessment_points, assessment_points)
  end

  defp assign_assessment_points(socket, _), do: socket

  @impl true
  def handle_event("add_assessment_point_to_grade_comp", %{"id" => id}, socket) do
    %{
      assessment_point_id: id,
      grades_report_id: socket.assigns.grades_report_id,
      grades_report_cycle_id: socket.assigns.grades_report_cycle_id,
      grades_report_subject_id: socket.assigns.grades_report_subject_id
    }
    |> Grading.create_grade_component()
    |> case do
      {:ok, _grade_component} ->
        grade_components =
          GradesReports.list_grade_composition(
            socket.assigns.grades_report_cycle_id,
            socket.assigns.grades_report_subject_id
          )

        grade_composition_assessment_point_ids =
          grade_components
          |> Enum.map(& &1.assessment_point_id)

        socket =
          socket
          |> assign(:indexed_grade_components, Enum.with_index(grade_components))
          |> assign(
            :grade_composition_assessment_point_ids,
            grade_composition_assessment_point_ids
          )

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_event("update_grade_component", %{"id" => id, "grade_component" => params}, socket) do
    socket.assigns.indexed_grade_components
    |> Enum.map(fn {grade_component, _i} -> grade_component end)
    |> Enum.find(&("#{&1.id}" == id))
    |> Grading.update_grade_component(params)
    |> case do
      {:ok, _grades_component} ->
        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply,
         put_flash(socket, :error, gettext("Error updating grades report cycle weight"))}
    end
  end

  def handle_event("delete_grade_component_from_composition", %{"id" => id}, socket) do
    socket.assigns.indexed_grade_components
    |> Enum.map(fn {grade_component, _i} -> grade_component end)
    |> Enum.find(&(&1.id == id))
    |> Grading.delete_grade_component()
    |> case do
      {:ok, _grade_component} ->
        grade_components =
          socket.assigns.indexed_grade_components
          |> Enum.map(fn {grade_component, _i} -> grade_component end)
          |> Enum.filter(&(&1.id != id))

        grade_composition_assessment_point_ids =
          grade_components
          |> Enum.map(& &1.assessment_point_id)

        socket =
          socket
          |> assign(:indexed_grade_components, Enum.with_index(grade_components))
          |> assign(
            :grade_composition_assessment_point_ids,
            grade_composition_assessment_point_ids
          )

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_event("swap_grade_components_position", %{"from" => i, "to" => j}, socket) do
    indexed_grade_components =
      socket.assigns.indexed_grade_components
      |> Enum.map(fn {grade_component, _i} -> grade_component end)
      |> swap(i, j)
      |> Enum.with_index()

    indexed_grade_components
    |> Enum.map(fn {grade_component, _i} -> grade_component.id end)
    |> Grading.update_grade_components_positions()
    |> case do
      :ok ->
        socket =
          socket
          |> assign(:indexed_grade_components, indexed_grade_components)

        {:noreply, socket}

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}
    end
  end
end
