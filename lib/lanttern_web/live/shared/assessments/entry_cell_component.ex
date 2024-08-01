defmodule LantternWeb.Assessments.EntryCellComponent do
  @moduledoc """
  This component renders the assessment point entry info, based on the view type.

  As this component is used in assessment grid views,
  rendering multiple components at the same time, it also handles the
  scales "preload" through `update_many/1`.

  #### Suported views

  - `:edit_teacher` - displays the teacher assessment (editable)
  - `:edit_student` - displays the student assessment (editable)
  - `:view_teacher` - displays the teacher assessment (view only)
  - `:view_student` - displays the student assessment (view only)
  - `:compare` - displays the teacher and student assessments side by side (view only)

  #### Expected external assigns

      attr :entry, AssessmentPointEntry
      attr :view, :string, default: "teacher", doc: "teacher | student | compare"
      attr :class, :any

  """
  alias Lanttern.Grading
  use LantternWeb, :live_component

  # alias Lanttern.Assessments
  alias Lanttern.Assessments.AssessmentPointEntry
  # alias Lanttern.Grading.OrdinalValue
  # alias Lanttern.Grading.Scale

  @impl true
  def render(assigns) do
    ~H"""
    <div class={[@grid_class, @class]}>
      <.entry_view
        :if={@view in ["compare", "teacher"]}
        entry={@entry}
        ov_map={@ov_map}
        ov_style_map={@ov_style_map}
        view="teacher"
      />
      <.entry_view
        :if={@view in ["compare", "student"]}
        entry={@entry}
        ov_map={@ov_map}
        ov_style_map={@ov_style_map}
        view="student"
      />
    </div>
    """
  end

  attr :entry, :any, required: true
  attr :ov_map, :map, required: true
  attr :ov_style_map, :map, required: true
  attr :view, :string, required: true, doc: "teacher | student"

  def entry_view(%{entry: %{scale_type: "ordinal"}} = assigns) do
    key =
      case assigns.view do
        "teacher" -> :ordinal_value_id
        "student" -> :student_ordinal_value_id
      end

    ov_id = Map.get(assigns.entry, key)

    {value, style} =
      case ov_id do
        nil -> {nil, nil}
        ov_id -> {assigns.ov_map[ov_id].name, assigns.ov_style_map[ov_id]}
      end

    assigns =
      assigns
      |> assign(:value, value)
      |> assign(:style, style)

    ~H"""
    <%= if @value do %>
      <div
        class="flex items-center justify-center p-2 rounded-sm font-mono text-sm bg-white"
        style={@style}
      >
        <span class="truncate">
          <%= @value %>
        </span>
      </div>
    <% else %>
      <.empty />
    <% end %>
    """
  end

  def entry_view(%{entry: %{scale_type: "numeric"}} = assigns) do
    key =
      case assigns.view do
        "teacher" -> :score
        "student" -> :student_score
      end

    value = Map.get(assigns.entry, key)

    assigns = assign(assigns, :value, value)

    ~H"""
    <%= if @value do %>
      <div class="flex items-center justify-center p-2 border border-ltrn-light rounded-sm font-mono text-sm bg-white">
        <%= @value %>
      </div>
    <% else %>
      <.empty />
    <% end %>
    """
  end

  def entry_view(assigns) do
    ~H"""
    <.empty />
    """
  end

  def empty(assigns) do
    ~H"""
    <div class="flex items-center justify-center p-2 rounded-sm font-mono text-sm text-ltrn-subtle bg-ltrn-lighter">
      —
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    socket =
      socket
      |> assign(:class, nil)
      |> assign(:grid_class, nil)
      |> assign(:view, "teacher")

    {:ok, socket}
  end

  @impl true
  def update_many(assigns_sockets) do
    scales_ids =
      assigns_sockets
      |> Enum.map(fn {assigns, _socket} ->
        case assigns.entry do
          %AssessmentPointEntry{} = entry -> entry.scale_id
          _ -> nil
        end
      end)
      |> Enum.filter(&(not is_nil(&1)))
      |> Enum.uniq()

    # map format
    # %{
    #   scale_id: %{
    #     ov_map: %{ov_id: ov, ...},
    #     ov_style_map: %{ov_id: style, ...},
    #   },
    #   ...
    # }
    scale_ov_maps =
      Grading.list_scales(
        type: "ordinal",
        ids: scales_ids,
        preloads: :ordinal_values
      )
      |> Enum.map(
        &{
          &1.id,
          build_ov_and_style_maps(&1.ordinal_values)
        }
      )
      |> Enum.into(%{})

    assigns_sockets
    |> Enum.map(&update_single(&1, scale_ov_maps))
  end

  defp build_ov_and_style_maps(ordinal_values) do
    ov_map =
      ordinal_values
      |> Enum.map(&{&1.id, &1})
      |> Enum.into(%{})

    ov_style_map =
      ordinal_values
      |> Enum.map(&{&1.id, "background-color: #{&1.bg_color}; color: #{&1.text_color}"})
      |> Enum.into(%{})

    %{
      ov_map: ov_map,
      ov_style_map: ov_style_map
    }
  end

  defp update_single({assigns, socket}, scale_ov_maps) do
    default = %{ov_map: nil, ov_style_map: nil}

    ov_and_style_maps =
      case assigns.entry do
        %AssessmentPointEntry{} = entry ->
          Map.get(scale_ov_maps, entry.scale_id, default)

        _ ->
          default
      end

    socket
    |> assign(assigns)
    |> assign(ov_and_style_maps)
    |> assign_grid_class()
  end

  defp assign_grid_class(socket) do
    grid_class =
      case socket.assigns.view do
        "compare" -> "grid grid-cols-2 gap-1"
        _ -> nil
      end

    assign(socket, :grid_class, grid_class)
  end
end
