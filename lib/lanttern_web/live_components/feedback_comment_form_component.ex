defmodule LantternWeb.FeedbackCommentFormComponent do
  @moduledoc """
  Expected external assigns:

  ```elixir
  attr :current_user, User, required: true
  attr :feedback_id, :string
  ```

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
        <.textarea_with_actions
          id={@form[:comment].id}
          name={@form[:comment].name}
          value={@form[:comment].value}
          errors={@form[:comment].errors}
          label="Add your comment..."
        >
          <:actions>
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

  # existing comment
  def update(%{comment_id: comment_id} = assigns, socket) do
    comment = Conversation.get_comment!(comment_id)

    form =
      comment
      |> Conversation.change_comment()
      |> to_form()

    socket =
      socket
      |> assign(assigns)
      |> assign(:form, form)

    {:ok, socket}
  end

  # new comment
  def update(assigns, socket) do
    form = empty_form(assigns.current_user.current_profile.id)

    socket =
      socket
      |> assign(assigns)
      |> assign(:form, form)

    {:ok, socket}
  end

  # event handlers

  def handle_event("save", %{"comment" => params}, socket) do
    feedback_id =
      socket.assigns.feedback_id
      |> String.to_integer()

    case Conversation.create_feedback_comment(params, feedback_id) do
      {:ok, _comment} ->
        # create_feedback_comment/2 broadcasts a {:feedback_comment_created, comment} message
        form = empty_form(socket.assigns.current_user.current_profile.id)

        {:noreply, assign(socket, :form, form)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  # helpers

  defp empty_form(profile_id) do
    %Comment{}
    |> Conversation.change_comment(%{profile_id: profile_id})
    |> to_form()
  end
end
