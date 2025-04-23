defmodule LantternWeb.Schools.StudentProfilePictureWithNameComponent do
  @moduledoc """
  This component renders a student profile picture with name.

  It's a wrapper of `<.profile_picture_with_name>`, but handles the
  student profile picture URL loading via `update_many/1` based on given cycle.

  ### Expected external assigns

  - `student`
  - `cycle_id`

  ### Optional assigns

  - `class`
  - `navigate`
  - `picture_size` (default: "md")
  - `show_tags` (default: `false`) will pass `@student.tags` as `tags` attr to `<.profile_picture_with_name>`

  """
  use LantternWeb, :live_component

  alias Lanttern.StudentsCycleInfo

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class} id={@id}>
      <.profile_picture_with_name
        profile_name={@student.name}
        picture_url={@student.profile_picture_url}
        navigate={@navigate}
        picture_size={@picture_size}
        {if @show_tags, do: %{tags: @student.tags}, else: %{}}
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:picture_size, "md")
      |> assign(:navigate, nil)
      |> assign(:show_tags, false)
      |> assign(:initialized, false)

    {:ok, socket}
  end

  @impl true
  def update_many(assigns_sockets) do
    students_ids =
      assigns_sockets
      |> Enum.map(fn {assigns, _socket} ->
        assigns.student.id
      end)
      |> Enum.filter(& &1)
      |> Enum.uniq()

    # it's expected to be only one cycle_id
    [cycle_id] =
      assigns_sockets
      |> Enum.map(fn {assigns, _socket} ->
        assigns.cycle_id
      end)
      |> Enum.filter(& &1)
      |> Enum.uniq()

    students_profile_picture_url_map =
      StudentsCycleInfo.build_students_cycle_info_profile_picture_url_map(
        cycle_id,
        students_ids
      )

    assigns_sockets
    |> Enum.map(&update_single(&1, students_profile_picture_url_map))
  end

  defp update_single(
         {assigns, %{assigns: %{initialized: false}} = socket},
         students_profile_picture_url_map
       ) do
    student = %{
      assigns.student
      | profile_picture_url: Map.get(students_profile_picture_url_map, assigns.student.id)
    }

    socket
    |> assign(assigns)
    |> assign(:student, student)
    |> assign(:initialized, true)
  end

  defp update_single({_assigns, socket}, _ordinal_values_map), do: socket
end
