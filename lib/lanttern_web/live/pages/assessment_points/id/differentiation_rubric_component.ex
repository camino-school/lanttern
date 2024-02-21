defmodule LantternWeb.AssessmentPointLive.DifferentiationRubricComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Rubrics
  alias Lanttern.Rubrics.Rubric

  # shared components
  import LantternWeb.GradingComponents
  alias LantternWeb.Rubrics.RubricFormComponent
  alias LantternWeb.Rubrics.RubricSearchInputComponent

  def render(assigns) do
    ~H"""
    <div id={"entry-#{@entry.id}-differentiation-panel"} role="tabpanel" class="mt-6 hidden">
      <%= if !@rubric && !@is_creating_rubric do %>
        <p class="font-display font-bold text-lg">
          Use an existing differentiation rubric (<.link
            href={~p"/rubrics"}
            class="underline"
            target="_blank"
          >explore</.link>)<br /> or
          <button type="button" phx-click="create_new" phx-target={@myself} class="underline">
            create a new differentiation rubric
          </button>
        </p>
        <.live_component
          module={RubricSearchInputComponent}
          id={"entry-#{@entry.id}-rubric-search"}
          selected_id={nil}
          notify_component={@myself}
          search_opts={[is_differentiation: true, scale_id: @entry.scale_id]}
          class="mt-6"
        />
      <% end %>
      <%= if @is_creating_rubric do %>
        <h4 class="-mb-2 font-display font-black text-xl text-ltrn-subtle">
          Create new differentiation rubric
        </h4>
        <.live_component
          module={RubricFormComponent}
          id={"entry-#{@entry.id}"}
          rubric={
            %Rubric{
              scale_id: @entry.scale_id,
              is_differentiation: true
            }
          }
          hide_diff_and_scale
          show_buttons
          on_cancel={JS.push("cancel_create_new", target: @myself)}
          notify_component={@myself}
          notify_parent={false}
          class="mt-6"
        />
      <% end %>
      <section :if={@rubric && !@is_creating_rubric} class="mt-8">
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
        <h5 class="mt-10 -mb-2 font-display font-black text-lg text-ltrn-subtle">
          Differentiation descriptors
        </h5>
        <.rubric_descriptors descriptors={@rubric.descriptors} class="mt-6" />
      </section>
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
        <.ordinal_value_badge ordinal_value={descriptor.ordinal_value}>
          <%= descriptor.ordinal_value.name %>
        </.ordinal_value_badge>
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

  def update(%{entry: entry} = assigns, socket) do
    # this is N+1, but it's *kind of* ok because we
    # don't expect too many diff rubrics in a real scenario
    rubric =
      case entry.differentiation_rubric_id do
        nil -> nil
        rubric_id -> Rubrics.get_full_rubric!(rubric_id)
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:rubric, rubric)}
  end

  def update(%{action: {RubricSearchInputComponent, {:selected, rubric_id}}}, socket),
    do: {:ok, link_rubric_to_entry_and_notify(socket, rubric_id)}

  def update(%{action: {RubricFormComponent, {:created, rubric}}}, socket) do
    {:ok,
     socket
     |> link_rubric_to_entry_and_notify(rubric.id)
     |> assign(:is_creating_rubric, false)}
  end

  # event handlers

  def handle_event("create_new", _params, socket),
    do: {:noreply, assign(socket, :is_creating_rubric, true)}

  def handle_event("cancel_create_new", _params, socket),
    do: {:noreply, assign(socket, :is_creating_rubric, false)}

  def handle_event("remove_rubric", _params, socket),
    do: {:noreply, link_rubric_to_entry_and_notify(socket, nil)}

  # helpers

  defp link_rubric_to_entry_and_notify(socket, rubric_id) do
    socket.assigns.entry
    |> Assessments.update_assessment_point_entry(%{
      differentiation_rubric_id: rubric_id
    })
    |> case do
      {:ok, assessment_point_entry} ->
        notify_component(
          socket.assigns.notify_component,
          {:diff_rubric_linked, assessment_point_entry.id, rubric_id}
        )

        socket
        |> assign(:rubric, rubric_id && Rubrics.get_full_rubric!(rubric_id))

      {:error, _changeset} ->
        notify_parent({:error, "Couldn't link differentiation rubric to assessment point entry"})
        socket
    end
  end

  defp notify_component(cid, msg), do: send_update(cid, action: {__MODULE__, msg})

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
