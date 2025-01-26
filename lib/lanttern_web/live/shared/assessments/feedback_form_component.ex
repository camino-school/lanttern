defmodule LantternWeb.Assessments.FeedbackFormComponent do
  @moduledoc """
  ### Expected external assigns:

      attr :feedback, Feedback, required: true, doc: "Base feedback structure, with profile, student, and feedback ids"
  """
  use LantternWeb, :live_component

  alias Lanttern.Assessments
  alias Lanttern.Assessments.Feedback

  def render(assigns) do
    ~H"""
    <div>
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
    </div>
    """
  end

  # lifecycle

  def update(%{feedback: %Feedback{} = feedback} = assigns, socket) do
    form =
      feedback
      |> Assessments.change_feedback()
      |> to_form()

    socket =
      socket
      |> assign(assigns)
      |> assign(:form, form)

    {:ok, socket}
  end

  # event handlers

  def handle_event("save", %{"feedback" => params}, socket) do
    case Assessments.create_feedback(params,
           preloads: [:student, profile: :staff_member]
         ) do
      {:ok, feedback} ->
        notify_parent({:created, feedback})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
