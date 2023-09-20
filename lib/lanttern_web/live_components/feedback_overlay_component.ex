defmodule LantternWeb.FeedbackOverlayComponent do
  @moduledoc """
  Expected external assigns:

  ```elixir
  attr :assessment_point, AssessmentPoint, required: true
  attr :current_user, User, required: true
  attr :feedback, :Feedback, doc: "`nil` when creating feedback"
  attr :student, Student, required: true
  attr :on_cancel, JS, default: %JS{}
  ```



  """
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.Feedback

  def render(assigns) do
    ~H"""
    <div>
      <.slide_over :if={@show} id={@id} show={@show} on_cancel={Map.get(assigns, :on_cancel, %JS{})}>
        <:title>Feedback</:title>
        <div class="mt-6 mb-10">
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
          profile_name={@feedback.profile.teacher.name}
        >
          <span class="block mb-2 text-xs text-ltrn-subtle">
            <%= Timex.format!(
              Timex.local(@feedback.inserted_at),
              "{Mshort} {D}, {YYYY}, {h12}:{m} {am}"
            ) %>
          </span>
          <p class="text-sm"><%= @feedback.comment %></p>
        </.user_icon_block>
        <.user_icon_block
          :for={comment <- @feedback.comments}
          profile_name={
            if comment.profile.type == "teacher" do
              comment.profile.teacher.name
            else
              comment.profile.stuent.name
            end
          }
          class="mt-6"
        >
          <span class="block mb-2 text-xs text-ltrn-subtle">
            <%= Timex.format!(
              Timex.local(comment.inserted_at),
              "{Mshort} {D}, {YYYY}, {h12}:{m} {am}"
            ) %>
          </span>
          <p class="text-sm"><%= comment.comment %></p>
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
            <div class={[
              "overflow-hidden rounded-sm shadow-sm ring-1 ring-inset ring-ltrn-hairline bg-white",
              "focus-within:ring-2 focus-within:ring-ltrn-primary"
            ]}>
              <label for={@form[:comment].id} class="sr-only">Add your feedback</label>
              <textarea
                rows="4"
                name={@form[:comment].name}
                id={@form[:comment].id}
                class="peer block w-full border-0 bg-transparent p-4 placeholder:text-ltrn-subtle focus:ring-0"
                placeholder="Add your feedback..."
              ><%= Phoenix.HTML.Form.normalize_value("textarea", @form[:comment].value) %></textarea>
              <div class="flex justify-end w-full p-2 border-t border-ltrn-hairline peer-focus:border-ltrn-primary">
                <.button type="submit">
                  Send feedback
                </.button>
              </div>
            </div>
            <.error :for={{msg, _opts} <- @form[:comment].errors}><%= msg %></.error>
          </.form>
        </.user_icon_block>
        <.user_icon_block profile_name={@profile_name} class="mt-10">
          <.live_component
            module={LantternWeb.FeedbackCommentFormComponent}
            id={:new}
            current_user={@current_user}
            feedback_id={@feedback_id}
          />
        </.user_icon_block>
      </.slide_over>
    </div>
    """
  end

  attr :profile_name, :string, required: true
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def user_icon_block(assigns) do
    ~H"""
    <div class={["flex gap-4", @class]}>
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

    {:ok, socket}
  end

  # event handlers

  def handle_event("save", %{"feedback" => params}, socket) do
    case Assessments.create_feedback(params, preloads: [profile: [:teacher]]) do
      {:ok, feedback} ->
        send(self(), {:feedback_created, feedback})

        socket =
          socket
          |> assign(:form, nil)
          |> assign(:show_feedback_form, false)
          |> assign(:feedback, feedback)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end