defmodule LantternWeb.Quizzes.QuizItemFormComponent do
  @moduledoc """
  Renders a `QuizItem` form

  ### Required attrs

  - `:quiz_item`

  """

  use LantternWeb, :live_component

  alias Lanttern.Quizzes

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.form for={@form} id={@id} phx-target={@myself} phx-change="validate" phx-submit="save">
        <.input
          field={@form[:description]}
          type="textarea"
          label={gettext("Description")}
          class="mb-1"
          phx-debounce="1500"
        />
        <.markdown_supported class="mb-6" />
        <fieldset class="mb-6">
          <legend class="font-bold"><%= gettext("Question type") %></legend>
          <div class="mt-4 flex items-center gap-4">
            <.radio_input
              field={@form[:type]}
              value={:multiple_choice}
              label={gettext("Multiple choice")}
            />
            <.radio_input field={@form[:type]} value={:text} label={gettext("Text")} />
          </div>
          <.error
            :for={msg <- Enum.map(@form[:type].errors, &translate_error(&1))}
            :if={@form.source.action in [:insert, :update]}
          >
            <%= msg %>
          </.error>
        </fieldset>
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
    changeset = Quizzes.change_quiz_item(socket.assigns.quiz_item)
    assign_form(socket, changeset)
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  # event handlers

  @impl true
  def handle_event("validate", %{"quiz_item" => params}, socket) do
    changeset =
      socket.assigns.quiz_item
      |> Quizzes.change_quiz_item(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"quiz_item" => params}, socket) do
    save_quiz_item(socket, socket.assigns.quiz_item.id, params)
  end

  defp save_quiz_item(socket, nil, params) do
    # inject quiz id from assign
    params = Map.put(params, "quiz_id", socket.assigns.quiz_item.quiz_id)

    case Quizzes.create_quiz_item(params) do
      {:ok, quiz_item} ->
        notify(__MODULE__, {:created, quiz_item}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_quiz_item(socket, _id, params) do
    case Quizzes.update_quiz_item(socket.assigns.quiz_item, params) do
      {:ok, quiz_item} ->
        notify(__MODULE__, {:updated, quiz_item}, socket.assigns)
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end
end
