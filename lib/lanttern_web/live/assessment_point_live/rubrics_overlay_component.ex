defmodule LantternWeb.AssessmentPointLive.RubricsOverlayComponent do
  use LantternWeb, :live_component

  import LantternWeb.RubricsHelpers
  alias Lanttern.Assessments
  alias Lanttern.Rubrics
  alias Lanttern.Rubrics.Rubric
  alias LantternWeb.RubricsLive.FormComponent, as: RubricsFormComponent
  alias LantternWeb.AssessmentPointLive.DifferentiationRubricComponent

  def render(assigns) do
    ~H"""
    <div>
      <.slide_over
        id="rubrics-overlay"
        show={true}
        on_cancel={JS.patch(~p"/assessment_points/#{@assessment_point.id}")}
      >
        <:title>Assessment point rubrics</:title>
        <form
          id="assessment-point-rubric-form"
          class="flex items-end gap-2"
          phx-submit="save_rubric"
          phx-target={@myself}
        >
          <.input
            field={@assessment_point_rubric_form[:rubric_id]}
            type="select"
            label="Rubric"
            options={@rubric_options}
            prompt="No rubric"
            phx-change="assessment_point_rubric_selected"
            phx-target={@myself}
            class="flex-1"
          />
          <.button
            type="submit"
            disabled={!@has_rubric_change || @is_creating_rubric}
            class={["shrink-0", if(!@has_rubric_change || @is_creating_rubric, do: "hidden")]}
          >
            Save
          </.button>
        </form>
        <%= if @is_creating_rubric do %>
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
            show_submit
            notify_component={@myself}
            notify_parent={false}
            class="mt-6"
          />
        <% end %>
        <%= if @rubric && !@is_creating_rubric do %>
          <section class="mt-10">
            <h4 class="-mb-2 font-display font-black text-xl text-ltrn-subtle">Descriptors</h4>
            <.rubric_descriptors descriptors={@rubric.descriptors} class="mt-8" />
          </section>
          <section :if={!@has_rubric_change} id="differentiation-rubrics-section" class="pb-10 mt-10">
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
        <% end %>
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
     |> assign(:is_creating_rubric, false)
     |> assign(:has_rubric_change, false)}
  end

  def update(%{assessment_point: assessment_point} = assigns, socket) do
    rubric =
      case assessment_point.rubric_id do
        nil -> nil
        rubric_id -> Rubrics.get_full_rubric!(rubric_id)
      end

    rubric_options =
      [
        {"Create new rubric", "new"}
        | generate_rubric_options(
            is_differentiation: false,
            scale_id: assessment_point.scale_id
          )
      ]

    diff_rubric_options =
      [
        {"Create new differentiation rubric", "new"}
        | generate_rubric_options(
            is_differentiation: true,
            scale_id: assessment_point.scale_id
          )
      ]

    assessment_point_rubric_form =
      %{"rubric_id" => assessment_point.rubric_id}
      |> to_form()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:rubric, rubric)
     |> assign(:rubric_options, rubric_options)
     |> assign(:diff_rubric_options, diff_rubric_options)
     |> assign(:assessment_point_rubric_form, assessment_point_rubric_form)}
  end

  def update(%{action: {RubricsFormComponent, {:created, rubric}}}, socket) do
    assessment_point = socket.assigns.assessment_point

    assessment_point
    |> Assessments.update_assessment_point(%{
      rubric_id: rubric.id
    })
    |> case do
      {:ok, _assessment_point} ->
        notify_parent({:new_rubric_linked, rubric.id})
        {:ok, socket}

      {:error, _changeset} ->
        notify_parent({:error, "Couldn't link rubric to assessment point"})
        {:ok, socket}
    end
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

  # event handlers

  def handle_event("assessment_point_rubric_selected", %{"rubric_id" => ""}, socket) do
    has_rubric_change = socket.assigns.assessment_point.rubric_id != nil

    socket =
      socket
      |> assign(:rubric, nil)
      |> assign(:has_rubric_change, has_rubric_change)
      |> assign(:is_creating_rubric, false)

    {:noreply, socket}
  end

  def handle_event("assessment_point_rubric_selected", %{"rubric_id" => "new"}, socket) do
    socket =
      socket
      |> assign(:is_creating_rubric, true)

    {:noreply, socket}
  end

  def handle_event("assessment_point_rubric_selected", %{"rubric_id" => rubric_id}, socket) do
    has_rubric_change = rubric_id != "#{socket.assigns.assessment_point.rubric_id}"

    socket =
      socket
      |> assign(:rubric, Rubrics.get_full_rubric!(rubric_id))
      |> assign(:has_rubric_change, has_rubric_change)
      |> assign(:is_creating_rubric, false)

    {:noreply, socket}
  end

  def handle_event("save_rubric", %{"rubric_id" => rubric_id}, socket) do
    rubric_id = if rubric_id == "", do: nil, else: rubric_id

    socket.assigns.assessment_point
    |> Assessments.update_assessment_point(%{
      rubric_id: rubric_id
    })
    |> case do
      {:ok, _assessment_point} ->
        notify_parent({:rubric_linked, rubric_id})

        socket =
          socket
          |> assign(:has_rubric_change, false)
          |> assign(:is_creating_rubric, false)

        {:noreply, socket}

      {:error, _changeset} ->
        notify_parent({:error, "Couldn't link rubric to assessment point"})
        {:noreply, socket}
    end
  end

  # helpers

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
