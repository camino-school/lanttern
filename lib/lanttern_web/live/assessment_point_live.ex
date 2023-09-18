defmodule LantternWeb.AssessmentPointLive do
  use LantternWeb, :live_view

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Grading

  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <.page_title_with_menu>Assessment point details</.page_title_with_menu>
      <div class="flex items-center mt-2 font-display font-bold text-xs text-ltrn-subtle">
        <.link navigate={~p"/assessment_points"} class="underline">Assessment points</.link>
        <span class="mx-1">/</span>
        <.link navigate={~p"/assessment_points/explorer"} class="underline">Explorer</.link>
        <span class="mx-1">/</span>
        <span>Details</span>
      </div>
    </div>
    <div class="container mx-auto lg:max-w-5xl mt-10">
      <.link
        navigate={~p"/assessment_points/explorer"}
        class="flex items-center text-sm text-ltrn-subtle"
      >
        <.icon name="hero-arrow-left-mini" class="text-ltrn-primary mr-2" />
        <span class="underline">Back to explorer</span>
      </.link>
      <div class="relative w-full p-6 mt-4 rounded shadow-xl bg-white">
        <.button
          class="absolute top-2 right-2"
          theme="ghost"
          phx-click={JS.exec("data-show", to: "#update-assessment-point-overlay")}
        >
          Edit
        </.button>
        <div class="max-w-screen-sm">
          <h2 class="font-display font-black text-2xl"><%= @assessment_point.name %></h2>
          <p :if={@assessment_point.description} class="mt-4 text-sm">
            <%= @assessment_point.description %>
          </p>
        </div>
        <.icon_and_content icon_name="hero-calendar">
          Date: <%= @formatted_datetime %>
        </.icon_and_content>
        <.icon_and_content icon_name="hero-bookmark">
          Curriculum: <%= @assessment_point.curriculum_item.name %>
        </.icon_and_content>
        <.icon_and_content icon_name="hero-view-columns">
          Scale: <%= @assessment_point.scale.name %>
          <.ordinal_values ordinal_values={@ordinal_values} />
        </.icon_and_content>
        <.icon_and_content :if={length(@assessment_point.classes) > 0} icon_name="hero-squares-2x2">
          <.classes classes={@assessment_point.classes} />
        </.icon_and_content>
        <div class="mt-20">
          <div class={"grid #{head_grid_cols_based_on_scale_type(@assessment_point.scale.type)} items-center gap-2"}>
            <div>&nbsp;</div>
            <div class="flex items-center gap-2 font-display font-bold text-ltrn-subtle">
              <.icon name="hero-view-columns" />
              <span>Marking</span>
            </div>
            <div class="flex items-center gap-2 font-display font-bold text-ltrn-subtle">
              <.icon name="hero-pencil-square" />
              <span>Observations</span>
            </div>
            <div class="flex items-center gap-2 font-display font-bold text-ltrn-subtle">
              <.icon name="hero-chat-bubble-left-right" />
              <span>Feedback</span>
            </div>
          </div>
          <.entry_row
            :for={entry <- @entries}
            entry={entry}
            student_name={entry.student.name}
            scale_type={@assessment_point.scale.type}
          />
        </div>
      </div>
    </div>
    <.live_component
      module={LantternWeb.AssessmentPointUpdateOverlayComponent}
      id="update-assessment-point-overlay"
      assessment_point={@assessment_point}
    />
    """
  end

  defp head_grid_cols_based_on_scale_type("numeric"),
    do: "grid-cols-[12rem_minmax(10px,_1fr)_minmax(10px,_2fr)_minmax(10px,_2fr)]"

  defp head_grid_cols_based_on_scale_type("ordinal"),
    do: "grid-cols-[12rem_minmax(10px,_2fr)_minmax(10px,_2fr)_minmax(10px,_2fr)]"

  attr :icon_name, :string, required: true
  slot :inner_block, required: true

  def icon_and_content(assigns) do
    ~H"""
    <div class="flex items-center mt-10">
      <.icon name={@icon_name} class="shrink-0 text-rose-500 mr-4" /> <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :ordinal_values, :list, required: true

  def ordinal_values(assigns) do
    ~H"""
    <div :if={@ordinal_values} class="flex items-center gap-2 ml-2">
      <%= for ov <- @ordinal_values do %>
        <.badge get_bagde_color_from={ov}>
          <%= ov.name %>
        </.badge>
      <% end %>
    </div>
    """
  end

  attr :classes, :list, required: true

  def classes(assigns) do
    ~H"""
    <div class="flex items-center gap-2 ml-2">
      <%= for c <- @classes do %>
        <.badge>
          <%= c.name %>
        </.badge>
      <% end %>
    </div>
    """
  end

  attr :entry, AssessmentPointEntry, required: true
  attr :student_name, :string, required: true
  attr :scale_type, :string, required: true

  def entry_row(assigns) do
    ~H"""
    <div class={"grid #{row_grid_cols_based_on_scale_type(@scale_type)} gap-2 mt-4"}>
      <.icon_with_name class="self-center" profile_name={@student_name} />
      <.live_component
        module={LantternWeb.AssessmentPointEntryEditorComponent}
        id={@entry.id}
        entry={@entry}
        class={"grid #{entry_grid_cols_based_on_scale_type(@scale_type)} gap-2"}
      >
        <:marking_input />
        <:observation_input />
      </.live_component>
      <.feedback_button feedback="complete" />
    </div>
    """
  end

  defp row_grid_cols_based_on_scale_type("numeric"),
    do: "grid-cols-[12rem_minmax(10px,_3fr)_minmax(10px,_2fr)]"

  defp row_grid_cols_based_on_scale_type("ordinal"),
    do: "grid-cols-[12rem_minmax(10px,_4fr)_minmax(10px,_2fr)]"

  defp entry_grid_cols_based_on_scale_type("numeric"),
    do: "grid-cols-[minmax(10px,_1fr)_minmax(10px,_2fr)]"

  defp entry_grid_cols_based_on_scale_type("ordinal"),
    do: "grid-cols-2"

  attr :feedback, :any, default: nil

  def feedback_button(%{feedback: "complete"} = assigns) do
    # we are using grid here to allow truncate (which is not viable with flex)
    ~H"""
    <button
      type="button"
      class="grid grid-cols-[1.5rem_minmax(10px,_1fr)] items-center gap-2 px-4 rounded-sm text-xs text-ltrn-subtle bg-white shadow-md"
    >
      <.icon name="hero-check-circle" class="w-6 h-6 text-green-500" />
      <span class="block text-left">
        <span class="block w-full text-ltrn-text truncate">
          It would blah It would blah It would blah It would blah It would blah It would blah
        </span>
        Completed Sep 03, 2023 🎉
      </span>
    </button>
    """
  end

  def feedback_button(%{feedback: "pending"} = assigns) do
    # we are using grid here to allow truncate (which is not viable with flex)
    ~H"""
    <button
      type="button"
      class="grid grid-cols-[1.5rem_minmax(10px,_1fr)] items-center gap-2 px-4 rounded-sm text-xs text-ltrn-subtle bg-white shadow-md"
    >
      <.icon name="hero-check-circle" class="w-6 h-6" />
      <span class="block text-left">
        <span class="block w-full text-ltrn-text truncate">
          It would blah It would blah It would blah It would blah It would blah It would blah
        </span>
        Not completed yet
      </span>
    </button>
    """
  end

  def feedback_button(assigns) do
    ~H"""
    <button
      type="button"
      class="flex items-center gap-2 px-4 rounded-sm text-xs text-ltrn-subtle bg-ltrn-hairline shadow-md"
    >
      <.icon name="hero-x-circle" class="shrink-0 w-6 h-6" /> No feedback
    </button>
    """
  end

  # lifecycle

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _uri, socket) do
    try do
      Assessments.get_assessment_point!(id, [
        :curriculum_item,
        :scale,
        :classes
      ])
    rescue
      _ ->
        socket =
          socket
          |> put_flash(:error, "Couldn't find assessment point")
          |> redirect(to: ~p"/assessment_points")

        {:noreply, socket}
    else
      assessment_point ->
        entries =
          Assessments.list_assessment_point_entries(
            preloads: [:student, :ordinal_value],
            assessment_point_id: assessment_point.id
          )
          |> Enum.sort_by(& &1.student.name)

        ordinal_values =
          if assessment_point.scale.type == "ordinal" do
            Grading.list_ordinal_values_from_scale(assessment_point.scale.id)
          else
            nil
          end

        formatted_datetime =
          Timex.format!(
            Timex.local(assessment_point.datetime),
            "{Mshort} {D}, {YYYY}, {h12}:{m} {am}"
          )

        socket =
          socket
          |> assign(:assessment_point, assessment_point)
          |> assign(:entries, entries)
          |> assign(:ordinal_values, ordinal_values)
          |> assign(:formatted_datetime, formatted_datetime)
          |> assign(:is_updating, false)

        {:noreply, socket}
    end
  end

  # event handlers

  def handle_event("update", _params, socket) do
    {:noreply, assign(socket, :is_updating, true)}
  end

  def handle_event("cancel-assessment-point-update", _params, socket) do
    {:noreply, assign(socket, :is_updating, false)}
  end

  # info handlers

  def handle_info({:assessment_point_updated, assessment_point}, socket) do
    socket =
      socket
      |> assign(:is_updating, false)
      |> put_flash(:info, "Assessment point updated!")
      |> push_navigate(to: ~p"/assessment_points/#{assessment_point.id}", replace: true)

    {:noreply, socket}
  end

  def handle_info(
        {:assessment_point_entry_save_error,
         %Ecto.Changeset{errors: [score: {score_error, _}]} = _changeset},
        socket
      ) do
    socket =
      socket
      |> put_flash(:error, score_error)

    {:noreply, socket}
  end

  def handle_info({:assessment_point_entry_save_error, _changeset}, socket) do
    socket =
      socket
      |> put_flash(:error, "Something is not right")

    {:noreply, socket}
  end
end
