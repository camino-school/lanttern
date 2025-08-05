defmodule LantternWeb.Rubrics.RubricDiffInfoOverlayComponent do
  @moduledoc """
  Renders an overlay with a list of differentiation students linked to the given rubric.

  ### Required attrs

  - `:rubric`
  - `:current_profile`
  - `:on_cancel` - `<.modal>` `on_cancel` attr

  """

  use LantternWeb, :live_component

  alias Lanttern.Rubrics

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-remove={JS.exec("phx-remove", to: "##{@id}")}>
      <.modal id={@id} show={true} on_cancel={@on_cancel}>
        <h5 class="mb-10 font-display font-black text-xl text-ltrn-diff-dark">
          {gettext("Differentiation rubrics and students")}
        </h5>
        <div class="prose prose-sm">
          <p>
            {gettext("There are two ways to \"connect\" students and differentiation rubrics:")}
          </p>
          <ol>
            <li>
              {gettext("Assigning a differentiation rubric in a student assessment point entry;")}
            </li>
            <li>
              {gettext(
                "Using the rubric with a differentiation assessment point (curriculum differentiation)."
              )}
            </li>
          </ol>
        </div>
        <%= if @has_students do %>
          <p class="mt-10 font-bold">
            {gettext("Students currently linked to the selected rubric")}
          </p>
          <div id={"#{@id}-students"} phx-updpate="stream">
            <.profile_picture_with_name
              :for={{dom_id, student} <- @streams.students}
              id={"#{@id}-#{dom_id}"}
              profile_name={student.name}
              picture_url={student.profile_picture_url}
              navigate={~p"/school/students/#{student}"}
              class="mt-6"
            />
          </div>
        <% else %>
          <.empty_state_simple class="mt-10">
            {gettext("No differentiation students linked to this rubric")}
          </.empty_state_simple>
        <% end %>
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
    students =
      Rubrics.list_diff_students_for_rubric(
        socket.assigns.rubric.id,
        socket.assigns.current_profile.school_id,
        load_profile_picture_from_cycle_id: socket.assigns.current_profile.current_school_cycle.id
      )

    socket
    |> stream(:students, students)
    |> assign(:has_students, length(students) > 0)
  end
end
