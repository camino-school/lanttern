defmodule LantternWeb.Rubrics.RubricDescriptorsComponent do
  @moduledoc """
  This component renders rubric descriptors.

  It's a wrapper of `<.rubric_descriptors>`, but handles the
  descriptors loading via `update_many/1`.

  ### Expected external assigns

  - `rubric` - `Rubric`

  ### Optional assigns

  - `class`
  - `highlight_level_for_entry` - `AssessmentPointEntry`

  """
  use LantternWeb, :live_component

  alias Lanttern.Rubrics
  alias Lanttern.Rubrics.Rubric

  import LantternWeb.RubricsComponents, only: [rubric_descriptors: 1]

  @impl true
  def render(assigns) do
    ~H"""
    <div class={@class} id={@id}>
      <.rubric_descriptors rubric={@rubric} highlight_level_for_entry={@highlight_level_for_entry} />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:highlight_level_for_entry, nil)

    {:ok, socket}
  end

  @impl true
  def update_many(assigns_sockets) do
    rubrics_ids =
      assigns_sockets
      |> Enum.map(fn {assigns, _socket} ->
        %Rubric{id: id} = assigns.rubric
        id
      end)
      |> Enum.filter(& &1)
      |> Enum.uniq()

    rubrics_descriptors_map = Rubrics.build_rubrics_descriptors_map(rubrics_ids)

    assigns_sockets
    |> Enum.map(&update_single(&1, rubrics_descriptors_map))
  end

  defp update_single({assigns, socket}, rubrics_descriptors_map) do
    descriptors = Map.get(rubrics_descriptors_map, assigns.rubric.id, [])
    rubric = %{assigns.rubric | descriptors: descriptors}

    socket
    |> assign(assigns)
    |> assign(:rubric, rubric)
  end
end
