defmodule LantternWeb.FeedbackCommentFormComponent do
  @moduledoc """
  Expected external assigns:

      attr :current_user, User, required: true
      attr :feedback_id, :string
      attr :hide_mark_for_completion, :boolean, default: false

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
        phx-target={@myself}
      >
        <.error_block :if={@form.source.action == :insert} class="mb-6">
          Oops, something went wrong! Please check the errors below.
        </.error_block>
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
        >
          <:actions>
            <div :if={!@hide_mark_for_completion} class="flex items-center gap-2 text-xs">
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

  @doc """
  2 expected update clauses:

      # update comment
      update(%{comment_id: comment_id} = assigns, socket)

      # new comment
      update(assigns, socket)

  we expect `feedback_id` and `hide_mark_for_completion`
  assigns in both scenarios
  """

  # existing comment
  def update(%{comment_id: comment_id} = assigns, socket) do
    comment =
      Conversation.get_comment!(comment_id)
      |> Map.put(:feedback_id_for_completion, assigns.feedback_id)

    form =
      comment
      |> to_form()

    socket =
      socket
      |> assign(assigns)
      |> assign(:form, form)

    {:ok, socket}
  end

  # new comment
  def update(assigns, socket) do
    form = empty_form(assigns.current_user.current_profile.id, assigns.feedback_id)

    socket =
      socket
      |> assign(assigns)
      |> assign(:form, form)

    {:ok, socket}
  end

  # event handlers

  def handle_event("save", %{"comment" => params}, socket) do
    # feedback_id type changes depending on its "source"
    # 1. phx-value-feedbackid from assessment point live view or
    # 2. feedback.id after feedback creation in overlay live component
    feedback_id =
      socket.assigns.feedback_id
      |> case do
        id when is_binary(id) -> String.to_integer(id)
        id -> id
      end

    case Conversation.create_feedback_comment(params, feedback_id) do
      {:ok, _comment} ->
        # create_feedback_comment/2 broadcasts a {:feedback_comment_created, comment} message
        form =
          empty_form(
            socket.assigns.current_user.current_profile.id,
            socket.assigns.feedback_id
          )

        {:noreply, assign(socket, :form, form)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  # helpers

  defp empty_form(profile_id, feedback_id) do
    %Comment{}
    |> Conversation.change_comment(%{
      profile_id: profile_id,
      feedback_id_for_completion: feedback_id
    })
    |> to_form()
  end
end
