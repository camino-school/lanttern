defmodule LantternWeb.StrandLive.StrandRubricsComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Rubrics
  alias Lanttern.Rubrics.Rubric

  # shared components
  import LantternWeb.RubricsComponents
  alias LantternWeb.Rubrics.RubricFormComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <h3 class="mt-16 font-display font-black text-3xl">Goal rubrics</h3>
      <div
        :for={assessment_point <- @assessment_points}
        id={"strand-assessment-point-#{assessment_point.id}"}
        class="mt-6"
      >
        <div class="p-6 rounded bg-white shadow-lg">
          <p class="text-sm pb-4 mb-4 border-b border-ltrn-lighter">
            <strong class="inline-block mr-2 font-display font-bold">
              <%= assessment_point.curriculum_item.curriculum_component.name %>
            </strong>
            <%= assessment_point.curriculum_item.name %>
          </p>
          <%= if assessment_point.rubric do %>
            <div class="flex items-start justify-between mb-4 ">
              <p class="flex-1 font-display font-black text-lg">
                Criteria: <%= assessment_point.rubric.criteria %>
              </p>
              <.button
                theme="ghost"
                phx-click={
                  JS.push("edit_rubric",
                    value: %{assessment_point_id: assessment_point.id}
                  )
                }
                phx-target={@myself}
              >
                Edit
              </.button>
            </div>
            <.rubric_descriptors rubric={assessment_point.rubric} />
          <% else %>
            <div class="flex items-start justify-between">
              <p class="flex-1 font-display font-black text-lg text-ltrn-subtle">
                No rubric created for this goal yet
              </p>
              <.button
                phx-click={
                  JS.push("new_rubric",
                    value: %{assessment_point_id: assessment_point.id}
                  )
                }
                phx-target={@myself}
              >
                Add rubric
              </.button>
            </div>
          <% end %>
        </div>
      </div>
      <.slide_over
        :if={@live_action == :manage_rubric}
        id="rubric-form-overlay"
        show={true}
        on_cancel={JS.patch(~p"/strands/#{@strand}?tab=assessment")}
      >
        <:title>Rubric</:title>
        <p>
          <strong class="inline-block mr-2 font-display font-bold">
            <%= @assessment_point.curriculum_item.curriculum_component.name %>
          </strong>
          <%= @assessment_point.curriculum_item.name %>
        </p>
        <.live_component
          module={RubricFormComponent}
          id={@rubric.id || :new}
          rubric={@rubric}
          link_to_assessment_point_id={@assessment_point.id}
          hide_diff_and_scale
          navigate={~p"/strands/#{@strand}?tab=assessment"}
          class="mt-6"
        />
        <:actions_left :if={@rubric.id}>
          <.button
            type="button"
            theme="ghost"
            phx-click="delete_rubric"
            phx-target={@myself}
            data-confirm="Are you sure?"
          >
            Delete
          </.button>
        </:actions_left>
        <:actions>
          <.button
            type="button"
            theme="ghost"
            phx-click={JS.exec("data-cancel", to: "#rubric-form-overlay")}
          >
            Cancel
          </.button>
          <.button
            type="submit"
            form={"rubric-form-#{@rubric.id || :new}"}
            phx-disable-with="Saving..."
          >
            Save
          </.button>
        </:actions>
      </.slide_over>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:rubric, nil)
      |> assign(:curriculum_item, nil)

    {:ok, socket}
  end

  @impl true
  def update(%{strand: strand} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:assessment_points, fn ->
        Assessments.list_assessment_points(
          strand_id: strand.id,
          preloads: [
            rubric: [descriptors: :ordinal_value],
            curriculum_item: :curriculum_component
          ]
        )
      end)

    {:ok, socket}
  end

  def update(_assigns, socket), do: {:ok, socket}

  # event handlers

  @impl true
  def handle_event("new_rubric", %{"assessment_point_id" => assessment_point_id}, socket) do
    assessment_point =
      socket.assigns.assessment_points
      |> Enum.find(&(&1.id == assessment_point_id))

    {:noreply,
     socket
     |> assign(:assessment_point, assessment_point)
     |> assign(:rubric, %Rubric{scale_id: assessment_point.scale_id})
     |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/manage_rubric")}
  end

  def handle_event("edit_rubric", %{"assessment_point_id" => assessment_point_id}, socket) do
    assessment_point =
      socket.assigns.assessment_points
      |> Enum.find(&(&1.id == assessment_point_id))

    {:noreply,
     socket
     |> assign(:assessment_point, assessment_point)
     |> assign(:rubric, assessment_point.rubric)
     |> push_patch(to: ~p"/strands/#{socket.assigns.strand}/manage_rubric")}
  end

  def handle_event("delete_rubric", _, socket) do
    case Rubrics.delete_rubric(socket.assigns.rubric) do
      {:ok, _rubric} ->
        {:noreply,
         push_navigate(socket, to: ~p"/strands/#{socket.assigns.strand}?tab=assessment")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Something went wrong")}
    end
  end
end
