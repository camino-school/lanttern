defmodule LantternWeb.StrandLive.AssessmentComponent do
  use LantternWeb, :live_component

  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 3]

  # shared components
  alias LantternWeb.Assessments.AssessmentsGridComponent
  alias LantternWeb.StrandLive.StrandRubricsComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div class="py-10">
      <.responsive_container>
        <div class="flex items-end justify-between gap-6">
          <%= if @selected_classes != [] do %>
            <p class="font-display font-bold text-2xl">
              <%= gettext("Viewing") %>
              <button
                type="button"
                class="inline text-left underline hover:text-ltrn-subtle"
                phx-click={JS.exec("data-show", to: "#classes-filter-modal")}
              >
                <%= @selected_classes
                |> Enum.map(& &1.name)
                |> Enum.join(", ") %>
              </button>
            </p>
          <% else %>
            <p class="font-display font-bold text-2xl">
              <button
                type="button"
                class="underline hover:text-ltrn-subtle"
                phx-click={JS.exec("data-show", to: "#classes-filter-modal")}
              >
                <%= gettext("Select a class") %>
              </button>
              <%= gettext("to view students assessments") %>
            </p>
          <% end %>
        </div>
      </.responsive_container>
      <.live_component
        module={AssessmentsGridComponent}
        id={:strand_assessment_grid}
        current_user={@current_user}
        strand_id={@strand.id}
        classes_ids={@selected_classes_ids}
        class="mt-6"
        navigate={~p"/strands/#{@strand}?tab=assessment"}
      />

      <.live_component
        module={StrandRubricsComponent}
        id={:strand_rubrics}
        strand={@strand}
        live_action={@live_action}
        selected_classes_ids={@selected_classes_ids}
      />
      <.live_component
        module={LantternWeb.Filters.FiltersOverlayComponent}
        id="classes-filter-modal"
        current_user={@current_user}
        title={gettext("Select classes for assessment")}
        filter_type={:classes}
        filter_opts={[strand_id: @strand.id]}
        navigate={~p"/strands/#{@strand}?tab=assessment"}
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def update(%{strand: strand} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_user_filters([:classes], strand_id: strand.id)

    {:ok, socket}
  end

  def update(_assigns, socket), do: {:ok, socket}
end
