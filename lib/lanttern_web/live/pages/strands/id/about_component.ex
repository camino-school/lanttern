defmodule LantternWeb.StrandLive.AboutComponent do
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPoint
  alias Lanttern.Curricula
  alias Lanttern.Reporting

  import Lanttern.SupabaseHelpers, only: [object_url_to_render_url: 2]
  import Lanttern.Utils, only: [swap: 3]

  # shared components
  alias LantternWeb.Assessments.AssessmentPointFormOverlayComponent
  import LantternWeb.ReportingComponents, only: [report_card_card: 1]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-4">
      <.cover_image
        image_url={@cover_image_url}
        alt_text={gettext("Strand cover image")}
        empty_state_text={gettext("Edit strand to add a cover image")}
      />
      <.responsive_container class="mt-10">
        <hgroup class="font-display font-black">
          <h1 class="text-4xl sm:text-5xl"><%= @strand.name %></h1>
          <p :if={@strand.type} class="mt-2 text-xl sm:text-2xl"><%= @strand.type %></p>
        </hgroup>
        <div class="flex flex-wrap gap-2 mt-6">
          <.badge :for={subject <- @strand.subjects} theme="dark">
            <%= Gettext.dgettext(Lanttern.Gettext, "taxonomy", subject.name) %>
          </.badge>
          <.badge :for={year <- @strand.years} theme="dark">
            <%= Gettext.dgettext(Lanttern.Gettext, "taxonomy", year.name) %>
          </.badge>
        </div>
        <.markdown text={@strand.description} class="mt-10" />
        <div :if={@strand.teacher_instructions} class="p-4 rounded-sm mt-10 bg-ltrn-staff-lightest">
          <p class="mb-4 font-bold text-ltrn-staff-dark">
            <%= gettext("Teacher instructions") %>
          </p>
          <.markdown text={@strand.teacher_instructions} />
        </div>
        <div class="flex items-end justify-between gap-6">
          <h3 class="mt-16 font-display font-black text-3xl"><%= gettext("Goals") %></h3>
          <.action
            type="link"
            icon_name="hero-plus-circle-mini"
            patch={~p"/strands/#{@strand}?goal=new"}
          >
            <%= gettext("Add strand goal") %>
          </.action>
        </div>
        <p class="mt-4">
          <%= gettext(
            "Under the hood, goals in Lanttern are defined by assessment points linked directly to the strand — when adding goals, we are adding assessment points which, in turn, hold the curriculum items we'll want to assess along the strand course."
          ) %>
        </p>
        <div :for={{curriculum_item, i} <- @indexed_curriculum_items} class="mt-6">
          <div class="flex items-stretch gap-6 p-6 rounded bg-white shadow-lg">
            <div class="flex-1">
              <div class="flex items-center gap-4">
                <div :if={curriculum_item.has_rubric} class="group relative">
                  <.icon name="hero-view-columns" class="w-6 h-6" />
                  <.tooltip><%= gettext("Uses rubric in final assessment") %></.tooltip>
                </div>
                <.badge :if={curriculum_item.is_differentiation} theme="diff">
                  <%= gettext("Differentiation") %>
                </.badge>
                <p class="flex-1 font-display font-bold text-sm">
                  <%= curriculum_item.curriculum_component.name %>
                </p>
                <.action
                  type="link"
                  theme="subtle"
                  icon_name="hero-pencil-mini"
                  patch={~p"/strands/#{@strand}?goal=#{curriculum_item.assessment_point_id}"}
                >
                  <%= gettext("Edit") %>
                </.action>
              </div>
              <p class="mt-4"><%= curriculum_item.name %></p>
              <div
                :if={hd(curriculum_item.assessment_points).report_info}
                class="p-4 rounded mt-6 bg-ltrn-mesh-cyan"
              >
                <div class="flex items-center gap-2 font-bold text-sm text-ltrn-subtle">
                  <.icon name="hero-information-circle" class="w-6 h-6" />
                  <%= gettext("Report info") %>
                </div>
                <.markdown
                  text={hd(curriculum_item.assessment_points).report_info}
                  class="max-w-none mt-4"
                />
              </div>
            </div>
            <div class="shrink-0 flex flex-col justify-center gap-2">
              <.icon_button
                type="button"
                sr_text={gettext("Move curriculum item up")}
                name="hero-chevron-up-mini"
                theme="ghost"
                rounded
                size="sm"
                disabled={i == 0}
                phx-click={JS.push("swap_goal_position", value: %{from: i, to: i - 1})}
                phx-target={@myself}
              />
              <.icon_button
                type="button"
                sr_text={gettext("Move curriculum item down")}
                name="hero-chevron-down-mini"
                theme="ghost"
                rounded
                size="sm"
                disabled={i + 1 == length(@indexed_curriculum_items)}
                phx-click={JS.push("swap_goal_position", value: %{from: i, to: i + 1})}
                phx-target={@myself}
              />
            </div>
          </div>
        </div>
      </.responsive_container>
      <.responsive_container class="mt-16">
        <h3 class="font-display font-black text-3xl"><%= gettext("Report cards") %></h3>
        <p class="flex gap-1 mt-4">
          <%= gettext("List of report cards linked to this strand.") %>
        </p>
      </.responsive_container>
      <%= if @has_report_cards do %>
        <.responsive_grid id={@id} phx-update="stream" class="px-6 py-10 sm:px-10">
          <.report_card_card
            :for={{dom_id, report_card} <- @streams.report_cards}
            id={dom_id}
            report_card={report_card}
            navigate={~p"/report_cards/#{report_card}"}
          />
        </.responsive_grid>
      <% else %>
        <.empty_state class="mt-10">
          <%= gettext("No report cards linked to this strand") %>
        </.empty_state>
      <% end %>
      <.live_component
        :if={@goal}
        module={AssessmentPointFormOverlayComponent}
        id={"strand-#{@strand.id}-goal-form-overlay"}
        notify_component={@myself}
        assessment_point={@goal}
        title={gettext("Strand goal")}
        on_cancel={JS.patch(~p"/strands/#{@strand}")}
      />
    </div>
    """
  end

  # lifecycle
  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:goal, nil)
      |> assign(:has_goal_position_change, false)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(
        %{action: {AssessmentPointFormOverlayComponent, {action, _assessment_point}}},
        socket
      )
      when action in [:created, :updated, :deleted, :deleted_with_entries] do
    flash_message =
      case action do
        :created ->
          {:info, gettext("Assessment point created successfully")}

        :updated ->
          {:info, gettext("Assessment point updated successfully")}

        :deleted ->
          {:info, gettext("Assessment point deleted successfully")}

        :deleted_with_entries ->
          {:info, gettext("Assessment point and entries deleted successfully")}
      end

    nav_opts = [
      put_flash: flash_message,
      push_navigate: [to: ~p"/strands/#{socket.assigns.strand}"]
    ]

    {:ok, delegate_navigation(socket, nav_opts)}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_goal()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    strand = socket.assigns.strand

    socket
    |> assign(
      :cover_image_url,
      object_url_to_render_url(strand.cover_image_url, width: 1280, height: 640)
    )
    |> assign_indexed_curriculum_items()
    |> stream_report_cards()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_indexed_curriculum_items(socket) do
    curriculum_items =
      Curricula.list_strand_curriculum_items(
        socket.assigns.strand.id,
        preloads: :curriculum_component
      )

    socket
    |> assign(:indexed_curriculum_items, Enum.with_index(curriculum_items))
    |> assign(:goals_ids, Enum.map(curriculum_items, & &1.assessment_point_id))
  end

  defp stream_report_cards(socket) do
    report_cards =
      Reporting.list_report_cards(
        preloads: :school_cycle,
        strands_ids: [socket.assigns.strand.id],
        school_id: socket.assigns.current_profile.school_id
      )

    socket
    |> stream(:report_cards, report_cards)
    |> assign(:has_report_cards, report_cards != [])
  end

  defp assign_goal(%{assigns: %{params: %{"goal" => "new"}}} = socket) do
    goal =
      %AssessmentPoint{
        strand_id: socket.assigns.strand.id,
        datetime: DateTime.utc_now()
      }

    assign(socket, :goal, goal)
  end

  defp assign_goal(%{assigns: %{params: %{"goal" => binary_id}}} = socket) do
    with {id, _} <- Integer.parse(binary_id), true <- id in socket.assigns.goals_ids do
      goal = Assessments.get_assessment_point(id)
      assign(socket, :goal, goal)
    else
      _ -> assign(socket, :goal, nil)
    end
  end

  defp assign_goal(socket), do: assign(socket, :goal, nil)

  # event handlers

  @impl true
  def handle_event("swap_goal_position", %{"from" => i, "to" => j}, socket) do
    swapped_curriculum_items =
      socket.assigns.indexed_curriculum_items
      |> Enum.map(fn {ap, _i} -> ap end)
      |> swap(i, j)

    swapped_goals_ids =
      swapped_curriculum_items
      |> Enum.map(& &1.assessment_point_id)

    case Assessments.update_assessment_points_positions(swapped_goals_ids) do
      {:ok, _} ->
        socket =
          socket
          |> assign(
            :indexed_curriculum_items,
            Enum.with_index(swapped_curriculum_items)
          )

        {:noreply, socket}

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}
    end
  end
end
