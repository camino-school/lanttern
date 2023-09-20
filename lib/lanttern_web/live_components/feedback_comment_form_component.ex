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
        id={"comment-form-#{@id}"}
        class="flex-1"
        phx-submit="save"
        phx-target={@myself}
      >
        <input type="hidden" name={@form[:profile_id].name} value={@form[:profile_id].value} />
        <div class={[
          "overflow-hidden rounded-sm shadow-sm ring-1 ring-inset ring-ltrn-hairline bg-white",
          "focus-within:ring-2 focus-within:ring-ltrn-primary"
        ]}>
          <label for={@form[:comment].id} class="sr-only">Add your comment</label>
          <textarea
            rows="4"
            name={@form[:comment].name}
            id={@form[:comment].id}
            class="peer block w-full border-0 bg-transparent p-4 placeholder:text-ltrn-subtle focus:ring-0"
            placeholder="Add your comment..."
          ><%= Phoenix.HTML.Form.normalize_value("textarea", @form[:comment].value) %></textarea>
          <div class="flex justify-end w-full p-2 border-t border-ltrn-hairline peer-focus:border-ltrn-primary">
            <.button type="submit">
              Save
            </.button>
          </div>
        </div>
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
        # send(self(), {:comment_created, comment})

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
