defmodule LantternWeb.FeedbackOverlayComponent do
  @moduledoc """
  ### PubSub: expected broadcast messages

  All messages should be broadcast to "assessment_point:id" topic, following `{:key, msg}` pattern.

      - `:feedback_created`
      - `:feedback_updated`

  ### Expected external assigns:

      attr :assessment_point, AssessmentPoint, required: true
      attr :current_user, User, required: true
      attr :feedback, :Feedback, doc: "`nil` when creating feedback"
      attr :student, Student, required: true
      attr :on_cancel, JS, default: %JS{}

  """
  use LantternWeb, :live_component
  alias Phoenix.PubSub

  import LantternWeb.DateTimeHelpers
  alias Lanttern.Assessments
  alias Lanttern.Assessments.Feedback

  def render(assigns) do
    ~H"""
    <div>
      <.slide_over :if={@show} id={@id} show={@show} on_cancel={Map.get(assigns, :on_cancel, %JS{})}>
        <:title>Feedback</:title>
        <div class="absolute top-4 right-4 flex items-center gap-2 text-xs">
          <.feedback_status feedback={@feedback} />
        </div>
        <div class="mt-5 mb-10">
          <div class="flex items-center gap-4 text-xs">
            <.icon name="hero-users-mini" class="text-ltrn-subtle" />
            <div class="flex items-center gap-1">
              From
              <.badge><%= @feedback_author_name %></.badge>
            </div>
            <div class="flex items-center gap-1">
              To
              <.badge><%= if @student, do: @student.name %></.badge>
            </div>
          </div>
          <div class="flex items-center gap-4 mt-4 text-xs">
            <.icon name="hero-bookmark-square-mini" class="text-ltrn-subtle" />
            <div class="flex items-center gap-1">
              In the context of
              <.badge><%= @assessment_point.name %></.badge>
            </div>
          </div>
        </div>
        <.user_icon_block
          :if={@feedback && !@show_feedback_form}
          id={"feedback=#{@feedback.id}"}
          profile_name={@feedback.profile.teacher.name}
          class="hidden"
          phx-mounted={
            JS.show(
              display: "flex",
              transition: {"ease-out duration-1000", "bg-ltrn-mesh-lime", "bg-transparent"},
              time: 1000
            )
          }
        >
          <span class="block mb-2 text-xs text-ltrn-subtle">
            <%= format_local!(@feedback.inserted_at, "{Mshort} {D}, {YYYY}, {h24}:{m}") %>
          </span>
          <p class="text-sm">
            <%= @feedback.comment %>
          </p>
        </.user_icon_block>
        <.user_icon_block :if={@show_feedback_form} profile_name={@profile_name}>
          <.form for={@form} id="feedback-form" phx-submit="save" phx-target={@myself}>
            <.error_block :if={@form.source.action == :insert} class="mb-6">
              Oops, something went wrong! Please check the errors below.
            </.error_block>
            <input type="hidden" name={@form[:profile_id].name} value={@form[:profile_id].value} />
            <input type="hidden" name={@form[:student_id].name} value={@form[:student_id].value} />
            <input
              type="hidden"
              name={@form[:assessment_point_id].name}
              value={@form[:assessment_point_id].value}
            />
            <.textarea_with_actions
              id={@form[:comment].id}
              name={@form[:comment].name}
              value={@form[:comment].value}
              errors={@form[:comment].errors}
              label="Add your feedback..."
            >
              <:actions>
                <.button type="submit">
                  Send feedback
                </.button>
              </:actions>
            </.textarea_with_actions>
            <.error :for={{msg, _opts} <- @form[:comment].errors}><%= msg %></.error>
          </.form>
        </.user_icon_block>
        <%= if @feedback do %>
          <.user_icon_block
            :for={comment <- @feedback.comments}
            id={"comment-#{comment.id}"}
            profile_name={
              if comment.profile.type == "teacher" do
                comment.profile.teacher.name
              else
                comment.profile.student.name
              end
            }
            class="mt-6 hidden"
            phx-mounted={
              JS.show(
                display: "flex",
                transition: {"ease-out duration-1000", "bg-ltrn-mesh-lime", "bg-transparent"},
                time: 1000
              )
            }
          >
            <span class="flex items-center gap-2 mb-2 text-xs text-ltrn-subtle">
              <%= format_local!(comment.inserted_at, "{Mshort} {D}, {YYYY}, {h24}:{m}") %>
              <button
                :if={comment.profile_id == @current_user.current_profile_id}
                type="button"
                class="underline"
                phx-click="edit-comment"
                phx-value-id={comment.id}
                phx-target={@myself}
              >
                Edit
              </button>
            </span>
            <%= if @edit_comment_id == comment.id do %>
              <.live_component
                module={LantternWeb.FeedbackCommentFormComponent}
                id={comment.id}
                comment_id={comment.id}
                current_user={@current_user}
                feedback_id={@feedback_id}
                assessment_point_id={@feedback.assessment_point_id}
                hide_mark_for_completion={@feedback.completion_comment_id}
                on_cancel_target={@myself}
              />
            <% else %>
              <div
                :if={@feedback.completion_comment_id == comment.id}
                class="flex items-center justify-between p-2 mb-2 text-white bg-green-500"
              >
                <div class="flex items-center gap-1">
                  <.icon name="hero-check-circle" class="shrink-0 w-6 h-6" />
                  <span class="font-display font-bold text-sm">Marked as complete 🎉</span>
                </div>
                <button
                  type="button"
                  class="shrink-0 opacity-50 hover:opacity-100 focus:opacity-100"
                  phx-click="remove_complete"
                  phx-target={@myself}
                >
                  <.icon name="hero-x-mark" class="w-6 h-6" />
                </button>
              </div>
              <p class="text-sm">
                <%= comment.comment %>
              </p>
            <% end %>
          </.user_icon_block>
          <.user_icon_block :if={!@edit_comment_id} profile_name={@profile_name} class="mt-10">
            <.live_component
              module={LantternWeb.FeedbackCommentFormComponent}
              id={:new}
              current_user={@current_user}
              feedback_id={@feedback_id}
              assessment_point_id={@feedback.assessment_point_id}
              hide_mark_for_completion={@feedback.completion_comment_id}
            />
          </.user_icon_block>
        <% end %>
      </.slide_over>
    </div>
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
    <span class="text-ltrn-text">Not completed yet</span>
    """
  end

  def feedback_status(%{feedback: %{completion_comment_id: comment_id}} = assigns)
      when not is_nil(comment_id) do
    ~H"""
    <.icon name="hero-check-circle" class="shrink-0 w-6 h-6 text-green-500" />
    <span class="text-ltrn-text">Completed</span>
    """
  end

  attr :profile_name, :string, required: true
  attr :class, :any, default: nil
  attr :id, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def user_icon_block(assigns) do
    ~H"""
    <div id={@id} class={["flex gap-4", @class]} {@rest}>
      <.profile_icon profile_name={@profile_name} class="shrink-0" />
      <div class="flex-1">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  # lifecycle

  @doc """
  we have three clauses for the update function, each one depending on the moment
  it's being used:

  ## open overlay without existing feedback (create new)

  ```
  update(%{show: true, feedback_id: nil} = assigns, socket)
  ```

  in this clause, we don't have a feedback yet.
  so, we should show the feedback comment form to the user, and consider
  that the user (identified in `current_user` assign) is the author of the
  feedback, which he is giving to the student (`student` assign).

  ## open overlay with existing feedback (view)

  ```
  update(%{show: true, feedback_id: _feedback_id} = assigns, socket)
  ```

  here we don't show the feedback form and we should query the feedback
  with all the relevant preloads (profile, student)

  ## mounting

  ```
  update(assigns, socket)
  ```

  the update that runs in the first cycle.
  here we assign everything that does not depend on a specific feedback information.
  """

  # open new feedback
  def update(%{show: true, feedback_id: nil} = assigns, socket) do
    form =
      %Feedback{}
      |> Assessments.change_feedback(%{
        profile_id: assigns.current_user.current_profile.id,
        student_id: assigns.student.id,
        assessment_point_id: assigns.assessment_point.id
      })
      |> to_form()

    socket =
      socket
      |> assign(assigns)
      |> assign(:form, form)
      |> assign(:show_feedback_form, true)

    {:ok, socket}
  end

  # open existing feedback
  def update(%{show: true, feedback_id: feedback_id} = assigns, socket) do
    feedback =
      Assessments.get_feedback!(feedback_id,
        preloads: [:student, profile: :teacher, comments: [profile: [:teacher, :student]]]
      )

    socket =
      socket
      |> assign(assigns)
      |> assign(:feedback, feedback)
      |> assign(:feedback_author_name, feedback.profile.teacher.name)
      |> assign(:student, feedback.student)

    {:ok, socket}
  end

  # comment created (sent via parent send_update)
  def update(%{action: {:feedback_comment_created, _comment}}, socket) do
    feedback =
      Assessments.get_feedback!(socket.assigns.feedback_id,
        preloads: [:student, profile: :teacher, comments: [profile: [:teacher, :student]]]
      )

    {:ok, assign(socket, :feedback, feedback)}
  end

  # comment updated (sent via parent send_update)
  def update(%{action: {:feedback_comment_updated, _comment}}, socket) do
    feedback =
      Assessments.get_feedback!(socket.assigns.feedback_id,
        preloads: [:student, profile: :teacher, comments: [profile: [:teacher, :student]]]
      )

    socket =
      socket
      |> assign(:feedback, feedback)
      |> assign(:edit_comment_id, nil)

    {:ok, socket}
  end

  # catch-all / mount update
  def update(assigns, socket) do
    profile_name =
      case assigns.current_user.current_profile.type do
        "teacher" -> assigns.current_user.current_profile.teacher.name
        "student" -> assigns.current_user.current_profile.student.name
      end

    socket =
      socket
      |> assign(assigns)
      |> assign(:profile_name, profile_name)
      |> assign(:feedback_author_name, profile_name)
      |> assign(:form, nil)
      |> assign(:show_feedback_form, false)
      |> assign(:feedback, nil)
      |> assign(:edit_comment_id, nil)

    {:ok, socket}
  end

  # event handlers

  def handle_event("save", %{"feedback" => params}, socket) do
    case Assessments.create_feedback(params,
           preloads: [:student, profile: :teacher, comments: [profile: [:teacher, :student]]]
         ) do
      {:ok, feedback} ->
        socket =
          socket
          |> assign(:form, nil)
          |> assign(:show_feedback_form, false)
          |> assign(:feedback_id, feedback.id)
          |> assign(:feedback, feedback)

        broadcast_to_assessment_point(
          socket.assigns.assessment_point.id,
          {:feedback_created, feedback}
        )

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("edit-comment", %{"id" => comment_id}, socket) do
    {:noreply, assign(socket, :edit_comment_id, String.to_integer(comment_id))}
  end

  def handle_event("feedback_comment_form:cancel", _params, socket) do
    {:noreply, assign(socket, :edit_comment_id, nil)}
  end

  def handle_event("remove_complete", _params, socket) do
    socket.assigns.feedback
    |> Assessments.update_feedback(%{completion_comment_id: nil},
      preloads: [:student, profile: :teacher, comments: [profile: [:teacher, :student]]]
    )
    |> case do
      {:ok, feedback} ->
        broadcast_to_assessment_point(
          socket.assigns.assessment_point.id,
          {:feedback_updated, feedback}
        )

        {:noreply, assign(socket, :feedback, feedback)}

      {:error, %Ecto.Changeset{}} ->
        # to do: where should we display this error?
        {:noreply, socket}
    end
  end

  defp broadcast_to_assessment_point(assessment_point_id, msg),
    do: PubSub.broadcast(Lanttern.PubSub, "assessment_point:#{assessment_point_id}", msg)
end
