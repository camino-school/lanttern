defmodule LantternWeb.AssessmentPointLive.Details do
  use LantternWeb, :live_view

  import LantternWeb.DateTimeHelpers

  alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPointEntry
  alias Lanttern.Assessments.Feedback
  alias Lanttern.Conversation
  alias Lanttern.Conversation.Comment
  alias Lanttern.Grading
  alias Lanttern.Schools.Student

  alias LantternWeb.AssessmentPointLive.AssessmentPointEntryEditorComponent
  alias LantternWeb.AssessmentPointLive.AssessmentPointUpdateFormComponent
  alias LantternWeb.AssessmentPointLive.RubricsOverlayComponent
  alias LantternWeb.AssessmentPointLive.DifferentiationRubricComponent
  alias LantternWeb.AssessmentPointLive.FeedbackFormComponent
  alias LantternWeb.AssessmentPointLive.FeedbackCommentFormComponent

  # render helpers and function components

  defp head_grid_cols_based_on_scale_type("numeric"),
    do: "grid-cols-[12rem_minmax(10px,_1fr)_minmax(10px,_2fr)_minmax(10px,_2fr)]"

  defp head_grid_cols_based_on_scale_type("ordinal"),
    do: "grid-cols-[12rem_minmax(10px,_2fr)_minmax(10px,_2fr)_minmax(10px,_2fr)]"

  attr :icon_name, :string, required: true
  slot :inner_block, required: true

  def icon_and_content(assigns) do
    ~H"""
    <div class="flex items-center gap-4 mt-10">
      <.icon name={@icon_name} class="shrink-0 text-ltrn-secondary" /> <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :ordinal_values, :list, required: true

  def ordinal_values(assigns) do
    ~H"""
    <div :if={@ordinal_values} class="flex items-center gap-2 ml-2">
      <%= for ov <- @ordinal_values do %>
        <.badge style_from_ordinal_value={ov}>
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
        module={AssessmentPointEntryEditorComponent}
        id={@entry.id}
        entry={@entry}
        class={"grid #{entry_grid_cols_based_on_scale_type(@scale_type)} gap-2"}
      >
        <:marking_input />
        <:observation_input />
      </.live_component>
      <.feedback_button
        feedback={@feedback}
        student_id={@student.id}
        assessment_point_id={@entry.assessment_point_id}
      />
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
  attr :assessment_point_id, :any, required: true
  attr :student_id, :any, required: true

  def feedback_button(%{feedback: %{completion_comment_id: nil}} = assigns) do
    ~H"""
    <.feedback_button_base
      feedback={@feedback}
      student_id={@student_id}
      assessment_point_id={@assessment_point_id}
    >
      <.icon name="hero-check-circle" class="shrink-0 w-6 h-6" />
      <span class="flex-1 block text-left">
        <span class="w-full text-ltrn-dark line-clamp-3">
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
    <.feedback_button_base
      feedback={@feedback}
      student_id={@student_id}
      assessment_point_id={@assessment_point_id}
    >
      <.icon name="hero-check-circle" class="shrink-0 w-6 h-6 text-green-500" />
      <span class="flex-1 block text-left">
        <span class="w-full text-ltrn-dark line-clamp-3">
          <%= @feedback.comment %>
        </span>
        Completed <%= format_local!(@feedback.completion_comment.inserted_at, "{Mshort} {D}, {YYYY}") %> 🎉
      </span>
    </.feedback_button_base>
    """
  end

  def feedback_button(%{feedback: nil} = assigns) do
    ~H"""
    <.feedback_button_base
      feedback={@feedback}
      student_id={@student_id}
      assessment_point_id={@assessment_point_id}
    >
      <.icon name="hero-x-circle" class="shrink-0 w-6 h-6" /> No feedback yet
    </.feedback_button_base>
    """
  end

  attr :feedback, :any, default: nil
  attr :assessment_point_id, :any, required: true
  attr :student_id, :any, required: true
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
    <.link
      class={[
        "flex items-center gap-2 px-4 rounded-sm text-xs text-ltrn-subtle shadow-md",
        if(@feedback_id, do: "bg-white", else: "bg-ltrn-lighter")
      ]}
      patch={~p"/assessment_points/#{@assessment_point_id}/student/#{@student_id}/feedback"}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  attr :feedback, :any

  def feedback_status(%{feedback: nil} = assigns) do
    ~H"""
    <.icon name="hero-x-circle" class="shrink-0 w-6 h-6 text-ltrn-subtle" />
    <span class="text-ltrn-subtle">No feedback yet</span>
    """
  end

  def feedback_status(%{feedback: %{completion_comment_id: nil}} = assigns) do
    ~H"""
    <.icon name="hero-check-circle" class="shrink-0 w-6 h-6 text-ltrn-subtle" />
    <span class="text-ltrn-dark">Not completed yet</span>
    """
  end

  def feedback_status(%{feedback: %{completion_comment_id: comment_id}} = assigns)
      when not is_nil(comment_id) do
    ~H"""
    <.icon name="hero-check-circle" class="shrink-0 w-6 h-6 text-green-500" />
    <span class="text-ltrn-dark">Completed</span>
    """
  end

  # lifecycle

  def mount(%{"id" => id}, _session, socket) do
    try do
      Assessments.get_assessment_point!(id,
        preloads: [
          :curriculum_item,
          :scale,
          :classes
        ]
      )
    rescue
      _ ->
        socket =
          socket
          |> put_flash(:error, "Couldn't find assessment point")
          |> redirect(to: ~p"/assessment_points")

        {:ok, socket}
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
            Grading.list_ordinal_values(scale_id: assessment_point.scale.id)
          else
            nil
          end

        socket =
          socket
          |> assign(:assessment_point, assessment_point)
          |> assign(:entries, entries)
          |> assign(:ordinal_values, ordinal_values)
          |> assign(:is_updating, false)

        {:ok, socket}
    end
  end

  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :feedback, %{"student_id" => student_id}) do
    feedback =
      socket.assigns.entries
      |> Enum.find(&("#{&1.student.id}" == student_id))
      |> Map.get(:feedback)
      |> case do
        nil ->
          nil

        feedback ->
          Assessments.get_feedback!(feedback.id,
            preloads: [:student, profile: :teacher]
          )
      end

    student =
      socket.assigns.entries
      |> Enum.map(& &1.student)
      |> Enum.find(&("#{&1.id}" == student_id))

    profile_name =
      case socket.assigns.current_user.current_profile.type do
        "teacher" -> socket.assigns.current_user.current_profile.teacher.name
        "student" -> socket.assigns.current_user.current_profile.student.name
      end

    feedback_author_name =
      case feedback do
        nil -> profile_name
        feedback -> feedback.profile.teacher.name
      end

    comments =
      case feedback do
        nil ->
          []

        feedback ->
          Conversation.list_comments(
            feedback_id: feedback.id,
            preloads: [:completed_feedback, profile: [:teacher, :student]]
          )
      end

    socket
    |> assign(:feedback, feedback)
    |> assign(:student, student)
    |> assign(:feedback_author_name, feedback_author_name)
    |> assign(:profile_name, profile_name)
    |> assign(:edit_comment_id, nil)
    |> stream(:comments, comments)
  end

  defp apply_action(socket, _live_action, _params), do: socket

  # event handlers

  def handle_event("edit_comment", %{"id" => id}, socket) do
    comment =
      Conversation.get_comment!(
        id,
        preloads: [:completed_feedback, profile: [:teacher, :student]]
      )

    socket =
      socket
      |> assign(:edit_comment_id, id)
      # we need this to force view update
      |> stream_insert(:comments, comment)

    {:noreply, socket}
  end

  def handle_event("delete_comment", %{"id" => id, "is_completion" => is_completion}, socket) do
    case Conversation.delete_comment(%Comment{id: id}) do
      {:ok, comment} ->
        socket =
          socket
          |> update(:feedback, fn feedback ->
            if is_completion do
              feedback
              |> Map.put(:completion_comment_id, nil)
              |> Map.put(:completion_comment, nil)
            else
              feedback
            end
          end)
          |> maybe_update_socket_entries({:feedback_comment_deleted, comment})
          |> stream_delete(:comments, comment)

        {:noreply, socket}

      {:error, %Ecto.Changeset{}} ->
        # to do: where should we display this error?
        {:noreply, socket}
    end
  end

  def handle_event("remove_complete", _params, socket) do
    socket.assigns.feedback
    |> Assessments.update_feedback(%{completion_comment_id: nil})
    |> case do
      {:ok, feedback} ->
        socket =
          socket
          |> assign(:feedback, feedback)
          |> update(:entries, &update_entries(&1, feedback))

        {:noreply, socket}

      {:error, %Ecto.Changeset{}} ->
        # to do: where should we display this error?
        {:noreply, socket}
    end
  end

  # info handlers

  def handle_info({AssessmentPointUpdateFormComponent, {:updated, assessment_point}}, socket) do
    socket =
      socket
      |> assign(:is_updating, false)
      |> put_flash(:info, "Assessment point updated!")
      |> push_navigate(to: ~p"/assessment_points/#{assessment_point.id}")

    {:noreply, socket}
  end

  def handle_info(
        {
          AssessmentPointEntryEditorComponent,
          {
            :error,
            %Ecto.Changeset{errors: [score: {score_error, _}]} = _changeset
          }
        },
        socket
      ) do
    socket =
      socket
      |> put_flash(:error, score_error)

    {:noreply, socket}
  end

  def handle_info({AssessmentPointEntryEditorComponent, {:error, _changeset}}, socket) do
    socket =
      socket
      |> put_flash(:error, "Something is not right")

    {:noreply, socket}
  end

  def handle_info({RubricsOverlayComponent, {:rubric_linked, rubric_id}}, socket) do
    {:noreply, update(socket, :assessment_point, &Map.put(&1, :rubric_id, rubric_id))}
  end

  def handle_info({RubricsOverlayComponent, {:new_rubric_linked, _rubric_id}}, socket) do
    {:noreply,
     push_navigate(socket,
       to: ~p"/assessment_points/#{socket.assigns.assessment_point.id}/rubrics"
     )}
  end

  def handle_info({RubricsOverlayComponent, {:error, error_msg}}, socket),
    do: {:noreply, put_flash(socket, :error, error_msg)}

  def handle_info({DifferentiationRubricComponent, {:error, error_msg}}, socket),
    do: {:noreply, put_flash(socket, :error, error_msg)}

  def handle_info({FeedbackFormComponent, {:created, feedback}}, socket) do
    socket =
      socket
      |> update(:entries, &update_entries(&1, feedback))
      |> assign(:feedback, feedback)

    {:noreply, socket}
  end

  def handle_info({FeedbackCommentFormComponent, {:created, comment}}, socket) do
    socket =
      socket
      |> stream_insert(:comments, comment)
      |> maybe_update_feedback(comment, socket.assigns.feedback)
      |> maybe_update_socket_entries({:created, comment})

    {:noreply, socket}
  end

  def handle_info({FeedbackCommentFormComponent, {:updated, comment}}, socket) do
    socket =
      socket
      |> stream_insert(:comments, comment)
      |> maybe_update_feedback(comment, socket.assigns.feedback)
      |> maybe_update_socket_entries({:created, comment})
      |> assign(:edit_comment_id, nil)

    {:noreply, socket}
  end

  def handle_info({FeedbackCommentFormComponent, {:cancel, comment}}, socket) do
    socket =
      socket
      |> stream_insert(:comments, comment)
      |> assign(:edit_comment_id, nil)

    {:noreply, socket}
  end

  # comment was completing feedback, but completion was unchecked
  defp maybe_update_feedback(
         socket,
         %{id: comment_id, completed_feedback: nil} = _comment,
         %{completion_comment_id: completion_comment_id} = _feedback
       )
       when comment_id == completion_comment_id do
    update(
      socket,
      :feedback,
      &(&1
        |> Map.put(:completion_comment_id, nil)
        |> Map.put(:completion_comment, nil))
    )
  end

  # comment is completing feedback
  defp maybe_update_feedback(socket, %{completed_feedback: %Feedback{}} = comment, _feedback) do
    update(
      socket,
      :feedback,
      &(&1
        |> Map.put(:completion_comment_id, comment.id)
        |> Map.put(:completion_comment, comment))
    )
  end

  # comment is not completion, and feedback is not completed
  defp maybe_update_feedback(socket, _comment, _feedback), do: socket

  defp maybe_update_socket_entries(socket, {:feedback_comment_deleted, _comment}) do
    # check if there's some feedback that was
    # completed by the deleted comment, and
    # update it's completion_comment if needed
    current_feedback_id = socket.assigns.feedback.id

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
