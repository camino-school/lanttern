defmodule LantternWeb.Rubrics.RubricDiffInfoOverlayComponent do
  @moduledoc """
  Renders an overlay with a list of differentiation students linked to the given rubric.

  ### Required attrs

  - `:rubric`
  - `:on_cancel` - `<.modal>` `on_cancel` attr

  """

  use LantternWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.modal id={@id} show={true} on_cancel={@on_cancel}>
        <h5 class="mb-10 font-display font-black text-xl text-ltrn-diff-dark">
          <%= gettext("Differentiation rubrics and students") %>
        </h5>
        <div class="prose prose-sm">
          <p>
            <%= gettext("There are two ways to \"connect\" students and differentiation rubrics:") %>
          </p>
          <ol>
            <li>
              <%= gettext("Assigning a differentiation rubric in a student assessment point entry;") %>
            </li>
            <li>
              <%= gettext(
                "Using the rubric with a differentiation assessment point (curriculum differentiation)."
              ) %>
            </li>
          </ol>
        </div>
        <p>
          <%= gettext("The students currently linked to the selected rubric are listed below.") %>
        </p>
        TBD
      </.modal>
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> stream_students()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_students(socket) do
    # rubric =
    #   socket.assigns.rubric
    #   |> Rubrics.load_rubric_descriptors()

    # assign(socket, :rubric, rubric)
    socket
  end
end
