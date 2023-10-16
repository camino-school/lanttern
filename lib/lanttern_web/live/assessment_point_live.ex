defmodule LantternWeb.AssessmentPointLive do
  @moduledoc """
  ### PubSub subscription topics

  - "assessment_point:id" on `handle_params`

  Expected broadcasted messages in `handle_info/2` documentation.
  """

  use LantternWeb, :live_view
  alias Phoenix.PubSub

  import LantternWeb.DateTimeHelpers
  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Assessments.Feedback
  alias Lanttern.Grading
  alias Lanttern.Schools.Student

  def render(assigns) do
    ~H"""
    <div class="container mx-auto lg:max-w-5xl">
      <.page_title_with_menu>Assessment point details</.page_title_with_menu>
      <div class="flex items-center mt-2 font-display font-bold text-xs text-ltrn-subtle">
        <.link navigate={~p"/assessment_points"} class="underline">Assessment points explorer</.link>
        <span class="mx-1">/</span>
        <span>Details</span>
      </div>
    </div>
    <div class="container mx-auto lg:max-w-5xl mt-10">
      <.link navigate={~p"/assessment_points"} class="flex items-center text-sm text-ltrn-subtle">
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
          <.markdown
            :if={@assessment_point.description}
            class="mt-4"
            text={@assessment_point.description}
          />
        </div>
        <.icon_and_content icon_name="hero-calendar">
          Date: <%= format_local!(@assessment_point.datetime, "{Mshort} {D}, {YYYY}, {h24}:{m}") %>
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
            student={entry.student}
            feedback={entry.feedback}
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
    <.live_component
      module={LantternWeb.FeedbackOverlayComponent}
      id="feedback-overlay"
      current_user={@current_user}
      assessment_point={@assessment_point}
      feedback_id={@current_feedback_id}
      student={@current_feedback_student}
      show={@show_feedback}
      on_cancel={JS.push("close-feedback")}
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
  attr :student, Student, required: true
  attr :feedback, Feedback, default: nil
  attr :scale_type, :string, required: true

  def entry_row(assigns) do
    ~H"""
    <div class={"grid #{row_grid_cols_based_on_scale_type(@scale_type)} gap-2 mt-4"}>
      <.icon_with_name class="self-center" profile_name={@student.name} />
      <.live_component
        module={LantternWeb.AssessmentPointEntryEditorComponent}
        id={@entry.id}
        entry={@entry}
        class={"grid #{entry_grid_cols_based_on_scale_type(@scale_type)} gap-2"}
      >
        <:marking_input />
        <:observation_input />
      </.live_component>
      <.feedback_button feedback={@feedback} student_id={@student.id} />
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
  attr :student_id, :string, required: true

  def feedback_button(%{feedback: %{completion_comment_id: nil}} = assigns) do
    ~H"""
    <.feedback_button_base feedback={@feedback} student_id={@student_id}>
      <.icon name="hero-check-circle" class="shrink-0 w-6 h-6" />
      <span class="flex-1 block text-left">
        <span class="w-full text-ltrn-text line-clamp-3">
          <%= @feedback.comment %>
        </span>
        Not completed yet
      </span>
    </.feedback_button_base>
    """
  end

  def feedback_button(%{feedback: %{completion_comment_id: comment_id}} = assigns)
      when not is_nil(comment_id) do
    ~H"""
    <.feedback_button_base feedback={@feedback} student_id={@student_id}>
      <.icon name="hero-check-circle" class="shrink-0 w-6 h-6 text-green-500" />
      <span class="flex-1 block text-left">
        <span class="w-full text-ltrn-text line-clamp-3">
          <%= @feedback.comment %>
        </span>
        Completed <%= format_local!(@feedback.completion_comment.inserted_at, "{Mshort} {D}, {YYYY}") %> 🎉
      </span>
    </.feedback_button_base>
    """
  end

  def feedback_button(%{feedback: nil} = assigns) do
    ~H"""
    <.feedback_button_base feedback={@feedback} student_id={@student_id}>
      <.icon name="hero-x-circle" class="shrink-0 w-6 h-6" /> No feedback yet
    </.feedback_button_base>
    """
  end

  attr :feedback, :any, default: nil
  attr :student_id, :string, required: true
  slot :inner_block, required: true

  def feedback_button_base(assigns) do
    feedback_id =
      case assigns.feedback do
        %{id: id} -> id
        _ -> nil
      end

    assigns =
      assign(assigns, feedback_id: feedback_id)

    ~H"""
    <button
      type="button"
      class={[
        "flex items-center gap-2 px-4 rounded-sm text-xs text-ltrn-subtle shadow-md",
        if(@feedback_id, do: "bg-white", else: "bg-ltrn-hairline")
      ]}
      phx-click="open-feedback"
      phx-value-feedbackid={@feedback_id}
      phx-value-studentid={@student_id}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  # lifecycle

  def handle_params(%{"id" => id}, _uri, socket) do
    if connected?(socket) do
      PubSub.subscribe(Lanttern.PubSub, "assessment_point:#{id}")
    end

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
            assessment_point_id: assessment_point.id,
            load_feedback: true
          )
          # to do: move sort to list_assessment_point_entries
          |> Enum.sort_by(& &1.student.name)

        ordinal_values =
          if assessment_point.scale.type == "ordinal" do
            Grading.list_ordinal_values_from_scale(assessment_point.scale.id)
          else
            nil
          end

        socket =
          socket
          |> assign(:assessment_point, assessment_point)
          |> assign(:entries, entries)
          |> assign(:ordinal_values, ordinal_values)
          |> assign(:is_updating, false)
          |> assign(:current_feedback_id, nil)
          |> assign(:current_feedback_student, nil)
          |> assign(:show_feedback, false)

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

  def handle_event("open-feedback", params, socket) do
    feedback_id =
      params
      |> Map.get("feedbackid")
      |> case do
        nil -> nil
        id -> String.to_integer(id)
      end

    student =
      socket.assigns.entries
      |> Enum.map(&Map.get(&1, :student))
      |> Enum.find(fn s -> "#{s.id}" == params["studentid"] end)

    socket =
      socket
      |> assign(:current_feedback_id, feedback_id)
      |> assign(:current_feedback_student, student)
      |> assign(:show_feedback, true)

    {:noreply, socket}
  end

  def handle_event("close-feedback", _params, socket) do
    socket =
      socket
      |> assign(:current_feedback_id, nil)
      |> assign(:current_feedback_student, nil)
      |> assign(:show_feedback, false)

    {:noreply, socket}
  end

  # info handlers

  @doc """
  Handles sent or broadcasted messages from children Live Components.

  ## Clauses

  #### Assessment point update success

  Sent from `LantternWeb.AssessmentPointUpdateOverlayComponent`.

  🔺 Not implemented in PubSub yet

      handle_info({:assessment_point_updated, assessment_point}, socket)

  #### Assessment point entry save error

  Sent from `LantternWeb.AssessmentPointEntryEditorComponent`.

  🔺 Not implemented in PubSub yet

      handle_info({:assessment_point_entry_save_error, %Ecto.Changeset{errors: [score: {score_error, _}]} = _changeset}, socket)
      handle_info({:assessment_point_entry_save_error, _changeset}, socket)

  #### Feedback created

  Broadcasted to `"assessment_point:id"` from `LantternWeb.FeedbackOverlayComponent`.

      handle_info({:feedback_created, feedback}, socket)

  #### Feedback updated

  Broadcasted to `"assessment_point:id"` from `LantternWeb.FeedbackOverlayComponent`.

      handle_info({:feedback_updated, feedback}, socket)

  ### Feedback comment messages

  All `handle_info()` for feedback comment have to `send_update()` to
  `FeedbackOverlayComponent`, in order to "trigger" the comment thread
  update inside the live component.

  #### Feedback comment created

  Broadcasted to `"assessment_point:id"` from `LantternWeb.FeedbackCommentFormComponent`.

      handle_info({:feedback_comment_created, _comment} = msg, socket) do

  #### Feedback comment updated

  Broadcasted to `"assessment_point:id"` from `LantternWeb.FeedbackCommentFormComponent`.

      handle_info({:feedback_comment_updated, _comment} = msg, socket) do

  #### Feedback comment deleted

  Broadcasted to `"assessment_point:id"` from `LantternWeb.FeedbackCommentFormComponent`.

      handle_info({:feedback_comment_deleted, _comment} = msg, socket) do
  """

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

  def handle_info({:feedback_created, feedback}, socket) do
    socket =
      socket
      |> update(:entries, &update_entries(&1, feedback))
      |> assign(:current_feedback_id, feedback.id)
      |> assign(:current_feedback_student, feedback.student)

    {:noreply, socket}
  end

  def handle_info({:feedback_updated, feedback}, socket) do
    socket =
      socket
      |> update(:entries, &update_entries(&1, feedback))

    {:noreply, socket}
  end

  def handle_info({:feedback_comment_created, _comment} = msg, socket) do
    send_comment_update_to_feedback_overlay(msg)

    socket =
      socket
      |> maybe_update_socket_entries(msg)

    {:noreply, socket}
  end

  def handle_info({:feedback_comment_updated, _comment} = msg, socket) do
    send_comment_update_to_feedback_overlay(msg)

    socket =
      socket
      |> maybe_update_socket_entries(msg)

    {:noreply, socket}
  end

  def handle_info({:feedback_comment_deleted, _comment} = msg, socket) do
    send_comment_update_to_feedback_overlay(msg)

    socket =
      socket
      |> maybe_update_socket_entries(msg)

    {:noreply, socket}
  end

  defp send_comment_update_to_feedback_overlay({_key, _comment} = msg) do
    send_update(
      LantternWeb.FeedbackOverlayComponent,
      id: "feedback-overlay",
      action: msg
    )
  end

  defp maybe_update_socket_entries(socket, {:feedback_comment_deleted, _comment}) do
    # check if there's some feedback that was
    # completed by the deleted comment, and
    # update it's completion_comment if needed
    current_feedback_id = socket.assigns.current_feedback_id

    socket
    |> update(
      :entries,
      &Enum.map(&1, fn
        %{feedback: %{id: ^current_feedback_id}} = entry ->
          entry
          |> Map.put(:feedback, %{entry.feedback | completion_comment_id: nil})

        entry ->
          entry
      end)
    )
  end

  defp maybe_update_socket_entries(socket, {_key, comment}) do
    # if comment completes feedback,
    # update feedback in entries to reflect
    # on feedback button
    case comment.completed_feedback do
      %Feedback{} = feedback ->
        socket
        |> update(
          :entries,
          &update_entries(
            &1,
            %{feedback | completion_comment: comment}
          )
        )

      _ ->
        socket
    end
  end

  defp update_entries(entries, feedback),
    do: Enum.map(entries, &update_entry_feedback(&1, feedback))

  defp update_entry_feedback(entry, feedback)
       when entry.student_id == feedback.student_id,
       do: Map.put(entry, :feedback, feedback)

  defp update_entry_feedback(entry, _feedback), do: entry
end
