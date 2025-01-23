defmodule LantternWeb.Assessments.FeedbackCommentFormComponent do
  @moduledoc """
  ### PubSub: expected broadcast messages

  All messages should be broadcast to "assessment_point:id" topic, following `{:key, msg}` pattern.

      - `:comment_created`

  ### Expected external assigns:

      attr :comment, Comment, required: true
      attr :feedback, Feedback, required: true
      attr :on_cancel_target, Phoenix.LiveComponent.CID, doc: "required if updating"

  """
  use LantternWeb, :live_component

  alias Lanttern.Conversation
  alias Lanttern.Conversation.Comment

  def render(assigns) do
    ~H"""
    <div>
      <.form
        for={@form}
        id={"feedback-comment-form-#{@id}"}
        class="flex-1"
        phx-submit="save"
        phx-change="validate"
        phx-target={@myself}
      >
        <.error_block
          :if={@form.source.action == :insert || @form.source.action == :update}
          class="mb-2"
        >
          Oops, something went wrong! Please check the errors below.
        </.error_block>
        <input type="hidden" name={@form[:id].name} value={@form[:id].value} />
        <input type="hidden" name={@form[:profile_id].name} value={@form[:profile_id].value} />
        <input
          type="hidden"
          name={@form[:feedback_id_for_completion].name}
          value={@form[:feedback_id_for_completion].value}
        />
        <.textarea_with_actions
          id={@form[:comment].id}
          name={@form[:comment].name}
          value={@form[:comment].value}
          errors={@form[:comment].errors}
          label="Add your comment..."
          phx-debounce="1500"
        >
          <:actions_left :if={!@feedback.completion_comment_id}>
            <div class="flex items-center gap-2 text-xs">
              <input
                id={@form[:mark_feedback_for_completion].id}
                name={@form[:mark_feedback_for_completion].name}
                value="true"
                checked={
                  Phoenix.HTML.Form.normalize_value(
                    "checkbox",
                    @form[:mark_feedback_for_completion].value
                  )
                }
                type="checkbox"
              />
              <label for={@form[:mark_feedback_for_completion].id}>Mark completed</label>
            </div>
          </:actions_left>
          <:actions>
            <.button
              :if={@id != :new}
              type="button"
              theme="ghost"
              phx-click="cancel"
              phx-target={@myself}
            >
              Cancel
            </.button>
            <.button type="submit">
              Save
            </.button>
          </:actions>
        </.textarea_with_actions>
        <.error :for={{msg, _opts} <- @form[:comment].errors}><%= msg %></.error>
      </.form>
    </div>
    """
  end

  # lifecycle

  def update(%{comment: %Comment{} = comment} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:form, blank_form(comment))
      |> assign(:on_cancel_target, Map.get(assigns, :on_cancel_target))

    {:ok, socket}
  end

  # event handlers

  def handle_event("cancel", _params, socket) do
    notify_parent({:cancel, socket.assigns.comment})
    {:noreply, socket}
  end

  def handle_event("validate", %{"comment" => params}, socket) do
    form =
      %Comment{}
      |> Conversation.change_comment(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"comment" => params}, socket),
    do: save_comment(socket, socket.assigns.id, params)

  defp save_comment(socket, :new, params) do
    feedback_id = socket.assigns.feedback.id

    case Conversation.create_feedback_comment(params, feedback_id,
           preloads: [:completed_feedback, profile: [:staff_member, :student]]
         ) do
      {:ok, comment} ->
        notify_parent({:created, comment})
        {:noreply, assign(socket, :form, blank_form(socket.assigns.comment))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_comment(socket, _comment_id, params) do
    # we are using returning: true opt because inserted_at field is required
    # to render the feedback button after an update with mark_feedback_for_completion: true
    case Conversation.update_comment(socket.assigns.comment, params, returning: true) do
      {:ok, comment} ->
        notify_parent({:updated, comment})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  # helpers

  defp blank_form(comment) do
    comment
    |> Conversation.change_comment()
    |> to_form()
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
