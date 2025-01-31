defmodule LantternWeb.StudentsRecordsSettingsLive.TagsComponent do
  use LantternWeb, :live_component

  alias Lanttern.StudentsRecords
  alias Lanttern.StudentsRecords.Tag

  import Lanttern.Utils, only: [swap: 3]

  # shared components
  alias LantternWeb.StudentsRecords.StudentRecordTagFormOverlayComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.action_bar class="flex items-center justify-between gap-4 p-4">
        <p class="flex items-center gap-2">
          <.icon name="hero-information-circle-mini" class="text-ltrn-subtle" />
          <%= gettext("Manage student records tags below") %>
        </p>
        <.action
          type="link"
          patch={~p"/students_records/settings/tags?new=true"}
          icon_name="hero-plus-circle-mini"
        >
          <%= gettext("New tag") %>
        </.action>
      </.action_bar>
      <%= if @tags_length == 0 do %>
        <div class="p-10">
          <.empty_state><%= gettext("No student record tags created yet") %></.empty_state>
        </div>
      <% else %>
        <.responsive_container id="student-record-tags" class="p-4">
          <.sortable_card
            :for={{tag, i} <- @tags_with_index}
            id={"student-record-tag-#{tag.id}"}
            is_move_up_disabled={i == 0}
            on_move_up={
              JS.push("swap_tags_position", value: %{"from" => i, "to" => i - 1}, target: @myself)
            }
            is_move_down_disabled={i + 1 == @tags_length}
            on_move_down={
              JS.push("swap_tags_position", value: %{"from" => i, "to" => i + 1}, target: @myself)
            }
            class="mt-4 first:mt-0"
          >
            <div class="flex items-center gap-4 p-6">
              <.badge color_map={tag}>
                <%= tag.name %>
              </.badge>
              <.action
                type="link"
                patch={~p"/students_records/settings/tags?edit=#{tag.id}"}
                theme="subtle"
              >
                <%= gettext("Edit") %>
              </.action>
            </div>
          </.sortable_card>
        </.responsive_container>
      <% end %>
      <.live_component
        :if={@tag}
        module={StudentRecordTagFormOverlayComponent}
        id="student-record-tag-form-overlay"
        tag={@tag}
        title={@tag_overlay_title}
        on_cancel={JS.patch(~p"/students_records/settings/tags")}
        notify_component={@myself}
      />
    </div>
    """
  end

  # lifecycle

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :initialized, false)}
  end

  @impl true
  def update(%{action: {StudentRecordTagFormOverlayComponent, {action, _tag}}}, socket)
      when action in [:created, :updated, :deleted] do
    message =
      case action do
        :created -> gettext("Tag created successfully")
        :updated -> gettext("Tag updated successfully")
        :deleted -> gettext("Tag deleted successfully")
      end

    nav_opts = [
      put_flash: {:info, message},
      push_navigate: [to: ~p"/students_records/settings/tags"]
    ]

    {:ok, delegate_navigation(socket, nav_opts)}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_tag()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> assign_tags_with_index()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp assign_tags_with_index(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id
    tags = StudentsRecords.list_student_record_tags(school_id: school_id)

    socket
    |> assign(:tags_with_index, Enum.with_index(tags))
    |> assign(:tags_length, length(tags))
    |> assign(:tags_ids, Enum.map(tags, &"#{&1.id}"))
  end

  defp assign_tag(%{assigns: %{params: %{"new" => "true"}}} = socket) do
    tag = %Tag{
      school_id: socket.assigns.current_user.current_profile.school_id
    }

    socket
    |> assign(:tag, tag)
    |> assign(:tag_overlay_title, gettext("New tag"))
  end

  defp assign_tag(%{assigns: %{params: %{"edit" => tag_id}}} = socket) do
    if tag_id in socket.assigns.tags_ids do
      tag = StudentsRecords.get_student_record_tag!(tag_id)

      socket
      |> assign(:tag, tag)
      |> assign(:tag_overlay_title, gettext("Edit tag"))
    else
      assign(socket, :tag, nil)
    end
  end

  defp assign_tag(socket), do: assign(socket, :tag, nil)

  # event handlers

  @impl true
  def handle_event("swap_tags_position", %{"from" => i, "to" => j}, socket) do
    sorted_tags =
      socket.assigns.tags_with_index
      |> Enum.map(fn {t, _i} -> t end)
      |> swap(i, j)

    sorted_tags_ids = Enum.map(sorted_tags, & &1.id)

    case StudentsRecords.update_student_record_tags_positions(sorted_tags_ids) do
      :ok ->
        {:noreply, assign(socket, :tags_with_index, Enum.with_index(sorted_tags))}

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, msg)}
    end
  end
end
