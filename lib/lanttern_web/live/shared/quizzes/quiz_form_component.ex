defmodule LantternWeb.Quizzes.QuizFormComponent do
  @moduledoc """
  Renders a `Quiz` form

  ### Required attrs

  - `:quiz`

  """

  use LantternWeb, :live_component

  alias Lanttern.Quizzes

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form for={@form} id={@id} phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input
          field={@form[:title]}
          type="text"
          label={gettext("Title")}
          class="mb-6"
          phx-debounce="1500"
        />
        <.input
          field={@form[:description]}
          type="textarea"
          label={gettext("Description")}
          class="mb-1"
          phx-debounce="1500"
        />
        <.markdown_supported class="mb-6" />
        <.error_block :if={@form.source.action in [:insert, :update]} class="mb-6">
          <%= gettext("Oops, something went wrong! Please check the errors above.") %>
        </.error_block>
        <div class="flex items-center justify-end gap-6">
          <.action type="button" theme="subtle" size="md" phx-click={@on_cancel}>
            <%= gettext("Cancel") %>
          </.action>
          <.action type="submit" theme="primary" size="md" icon_name="hero-check">
            <%= gettext("Save") %>
          </.action>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_form()

    {:ok, socket}
  end

  defp assign_form(socket) do
    changeset = Quizzes.change_quiz(socket.assigns.quiz)
    assign_form(socket, changeset)
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  # event handlers

  @impl true
  def handle_event("validate", %{"quiz" => params}, socket) do
    changeset =
      socket.assigns.quiz
      |> Quizzes.change_quiz(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"quiz" => params}, socket) do
    save_quiz(socket, socket.assigns.quiz.id, params)
  end

  defp save_quiz(socket, nil, params) do
    # inject moment id from assign
    params = Map.put(params, "moment_id", socket.assigns.quiz.moment_id)

    case Quizzes.create_quiz(params) do
      {:ok, quiz} ->
        notify(__MODULE__, {:created, quiz}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_quiz(socket, _id, params) do
    case Quizzes.update_quiz(socket.assigns.quiz, params) do
      {:ok, quiz} ->
        notify(__MODULE__, {:updated, quiz}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end
end
