defmodule LantternWeb.StrandLive.AssessmentComponent do
  use LantternWeb, :live_component

  import LantternWeb.FiltersHelpers, only: [assign_user_filters: 2, assign_user_filters: 3]

  alias Lanttern.Filters

  # shared components
  import LantternWeb.AssessmentsComponents
  alias LantternWeb.Assessments.AssessmentsGridComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.action_bar class="flex items-center gap-4">
        <.action
          type="button"
          phx-click={JS.exec("data-show", to: "#classes-filter-modal")}
          icon_name="hero-chevron-down-mini"
        >
          <%= format_action_items_text(@selected_classes, gettext("No class selected")) %>
        </.action>
        <.assessment_group_by_dropdow
          current_assessment_group_by={@current_assessment_group_by}
          on_change={
            fn group_by ->
              JS.push("change_group_by", value: %{"group_by" => group_by}, target: @myself)
            end
          }
        />
        <.assessment_view_dropdow
          current_assessment_view={@current_assessment_view}
          on_change={fn view -> JS.push("change_view", value: %{"view" => view}, target: @myself) end}
        />
      </.action_bar>
      <.responsive_container :if={@selected_classes == []} class="py-10">
        <p class="flex items-center gap-2">
          <.icon name="hero-light-bulb-mini" class="text-ltrn-subtle" />
          <%= gettext("Select a class above to view full assessments grid") %>
        </p>
      </.responsive_container>
      <.live_component
        module={AssessmentsGridComponent}
        id={:strand_assessment_grid}
        current_user={@current_user}
        current_assessment_group_by={@current_assessment_group_by}
        current_assessment_view={@current_assessment_view}
        strand_id={@strand.id}
        classes_ids={@selected_classes_ids}
        navigate={~p"/strands/#{@strand}/assessment"}
      />
      <.live_component
        module={LantternWeb.Filters.ClassesFilterOverlayComponent}
        id="classes-filter-modal"
        current_user={@current_user}
        title={gettext("Select classes for assessment")}
        filter_opts={[strand_id: @strand.id]}
        classes={@classes}
        selected_classes_ids={@selected_classes_ids}
        navigate={~p"/strands/#{@strand}/assessment"}
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_user_filters([:classes], strand_id: socket.assigns.strand.id)
    |> assign_user_filters([:assessment_view, :assessment_group_by])
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  # event handlers

  @impl true
  def handle_event(
        "change_group_by",
        %{"group_by" => group_by},
        %{assigns: %{current_assessment_group_by: current_assessment_group_by}} = socket
      )
      when group_by == current_assessment_group_by,
      do: {:noreply, socket}

  def handle_event("change_group_by", %{"group_by" => group_by}, socket) do
    # TODO
    # before applying the group_by change, check if there're pending changes

    Filters.set_profile_current_filters(
      socket.assigns.current_user,
      %{assessment_group_by: group_by}
    )
    |> case do
      {:ok, _} ->
        socket =
          socket
          |> assign(:current_assessment_group_by, group_by)
          |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}/assessment")

        {:noreply, socket}

      {:error, _} ->
        # do something with error?
        {:noreply, socket}
    end
  end

  def handle_event(
        "change_view",
        %{"view" => view},
        %{assigns: %{current_assessment_view: current_assessment_view}} = socket
      )
      when view == current_assessment_view,
      do: {:noreply, socket}

  def handle_event("change_view", %{"view" => view}, socket) do
    # TODO
    # before applying the view change, check if there're pending changes

    Filters.set_profile_current_filters(
      socket.assigns.current_user,
      %{assessment_view: view}
    )
    |> case do
      {:ok, _} ->
        socket =
          socket
          |> assign(:current_assessment_view, view)
          |> push_navigate(to: ~p"/strands/#{socket.assigns.strand}/assessment")

        {:noreply, socket}

      {:error, _} ->
        # do something with error?
        {:noreply, socket}
    end
  end
end
