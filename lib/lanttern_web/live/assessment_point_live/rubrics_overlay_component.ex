defmodule LantternWeb.AssessmentPointLive.RubricsOverlayComponent do
  use LantternWeb, :live_component

  import LantternWeb.RubricsHelpers
  alias Lanttern.Assessments
  alias Lanttern.Rubrics
  alias Lanttern.Rubrics.Rubric
  alias LantternWeb.RubricsLive.FormComponent, as: RubricsFormComponent
  alias LantternWeb.AssessmentPointLive.DifferentiationRubricComponent
  alias LantternWeb.RubricsLive.RubricSearchInputComponent

  def render(assigns) do
    ~H"""
    <div>
      <.slide_over
        id="rubrics-overlay"
        show={true}
        on_cancel={JS.patch(~p"/assessment_points/#{@assessment_point.id}")}
      >
        <:title>Assessment point rubrics</:title>
        <%= if !@rubric && !@is_creating_rubric do %>
          <p class="font-display font-bold text-lg">
            Use an existing rubric (<.link href={~p"/rubrics"} class="underline" target="_blank">explore</.link>)<br />
            or
            <button type="button" phx-click="create_new" phx-target={@myself} class="underline">
              create a new rubric
            </button>
          </p>
          <.live_component
            module={RubricSearchInputComponent}
            id="assessment-point-rubric-search"
            selected_id={nil}
            notify_component={@myself}
            search_opts={[is_differentiation: false, scale_id: @assessment_point.scale_id]}
            class="mt-6"
          />
        <% end %>
        <%= if @is_creating_rubric do %>
          <h4 class="-mb-2 font-display font-black text-xl text-ltrn-subtle">Create new rubric</h4>
          <.live_component
            module={RubricsFormComponent}
            id={:new}
            action={:new}
            rubric={
              %Rubric{
                scale_id: @assessment_point.scale_id,
                is_differentiation: false
              }
            }
            hide_diff_and_scale
            show_buttons
            notify_component={@myself}
            notify_parent={false}
            class="mt-6"
          />
        <% end %>
        <section :if={@rubric && !@is_creating_rubric}>
          <div class="flex items-baseline gap-4 mb-4 text-ltrn-subtle">
            <h4 class="font-display font-black text-xl">Criteria</h4>
            <button
              type="button"
              phx-click="remove_rubric"
              phx-target={@myself}
              class="text-sm underline"
            >
              Remove rubric
            </button>
          </div>
          <p class="font-display font-bold"><%= @rubric.criteria %></p>
          <h4 class="mt-10 -mb-2 font-display font-black text-xl text-ltrn-subtle">Descriptors</h4>
          <.rubric_descriptors descriptors={@rubric.descriptors} class="mt-8" />
        </section>
        <section :if={!@is_creating_rubric} id="differentiation-rubrics-section" class="pb-10 mt-10">
          <h4 class="-mb-2 font-display font-black text-xl text-ltrn-subtle">Differentiation</h4>
          <div role="tablist" class="flex items-center gap-2 mt-6">
            <.person_tab
              :for={entry <- @entries}
              aria-controls={"entry-#{entry.id}-differentiation-panel"}
              person={entry.student}
              container_selector="#differentiation-rubrics-section"
              theme={if entry.differentiation_rubric_id != nil, do: "cyan", else: "subtle"}
            />
          </div>
          <.live_component
            :for={entry <- @entries}
            module={DifferentiationRubricComponent}
            id={"entry-#{entry.id}"}
            entry={entry}
            rubric_options={@diff_rubric_options}
            notify_component={@myself}
          />
        </section>
      </.slide_over>
    </div>
    """
  end

  # function components

  attr :descriptors, :list, required: true
  attr :class, :any, default: nil

  defp rubric_descriptors(assigns) do
    ~H"""
    <div :for={descriptor <- @descriptors} class={@class}>
      <%= if descriptor.scale_type == "ordinal" do %>
        <.badge style_from_ordinal_value={descriptor.ordinal_value}>
          <%= descriptor.ordinal_value.name %>
        </.badge>
      <% else %>
        <.badge>
          <%= descriptor.score %>
        </.badge>
      <% end %>
      <.markdown class="mt-2" text={descriptor.descriptor} />
    </div>
    """
  end

  # lifecycle

  def mount(socket) do
    {:ok,
     socket
     |> assign(:is_creating_rubric, false)}
  end

  def update(%{assessment_point: assessment_point} = assigns, socket) do
    rubric =
      case assessment_point.rubric_id do
        nil -> nil
        rubric_id -> Rubrics.get_full_rubric!(rubric_id)
      end

    diff_rubric_options =
      [
        {"Create new differentiation rubric", "new"}
        | generate_rubric_options(
            is_differentiation: true,
            scale_id: assessment_point.scale_id
          )
      ]

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:rubric, rubric)
     |> assign(:diff_rubric_options, diff_rubric_options)}
  end

  def update(%{action: {RubricSearchInputComponent, {:selected, rubric_id}}}, socket),
    do: {:ok, link_rubric_to_assessment_and_notify_parent(socket, rubric_id)}

  def update(%{action: {RubricsFormComponent, {:created, rubric}}}, socket) do
    {:ok,
     socket
     |> link_rubric_to_assessment_and_notify_parent(rubric.id)
     |> assign(:is_creating_rubric, false)}
  end

  def update(
        %{action: {DifferentiationRubricComponent, {:diff_rubric_linked, entry_id, rubric_id}}},
        socket
      ) do
    entries =
      socket.assigns.entries
      |> Enum.map(fn
        %{id: ^entry_id} = entry -> Map.put(entry, :differentiation_rubric_id, rubric_id)
        entry -> entry
      end)

    {:ok,
     socket
     |> assign(:entries, entries)}
  end

  def update(
        %{
          action: {DifferentiationRubricComponent, {:new_diff_rubric_linked, entry_id, rubric}}
        },
        socket
      ) do
    entries =
      socket.assigns.entries
      |> Enum.map(fn
        %{id: ^entry_id} = entry -> Map.put(entry, :differentiation_rubric_id, rubric.id)
        entry -> entry
      end)

    diff_rubric_options =
      socket.assigns.diff_rubric_options
      |> List.insert_at(-1, {"(##{rubric.id}) #{rubric.criteria}", rubric.id})

    {:ok,
     socket
     |> assign(:entries, entries)
     |> assign(:diff_rubric_options, diff_rubric_options)}
  end

  defp link_rubric_to_assessment_and_notify_parent(socket, rubric_id) do
    socket.assigns.assessment_point
    |> Assessments.update_assessment_point(%{
      rubric_id: rubric_id
    })
    |> case do
      {:ok, _assessment_point} ->
        notify_parent({:rubric_linked, rubric_id})

        socket
        |> assign(:rubric, Rubrics.get_full_rubric!(rubric_id))

      {:error, _changeset} ->
        notify_parent({:error, "Couldn't link rubric to assessment point"})
        socket
    end
  end

  # event handlers

  def handle_event("create_new", _params, socket),
    do: {:noreply, assign(socket, :is_creating_rubric, true)}

  def handle_event("cancel_create_new", _params, socket),
    do: {:noreply, assign(socket, :is_creating_rubric, false)}

  def handle_event("remove_rubric", _params, socket) do
    socket.assigns.assessment_point
    |> Assessments.update_assessment_point(%{rubric_id: nil})
    |> case do
      {:ok, _assessment_point} ->
        notify_parent({:rubric_linked, nil})
        {:noreply, assign(socket, :rubric, nil)}

      {:error, _changeset} ->
        notify_parent({:error, "Couldn't remove rubric from assessment point"})
        {:noreply, socket}
    end
  end

  # helpers

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
