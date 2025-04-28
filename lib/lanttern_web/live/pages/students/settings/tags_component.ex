defmodule LantternWeb.StudentsSettingsLive.TagsComponent do
  use LantternWeb, :live_component

  alias Lanttern.StudentTags
  alias Lanttern.StudentTags.Tag

  # shared components
  alias LantternWeb.Students.StudentTagFormOverlayComponent

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.action_bar class="flex items-center justify-between gap-4 p-4">
        <p class="flex items-center gap-2">
          <.icon name="hero-information-circle-mini" class="text-ltrn-subtle" />
          <%= gettext("Manage student tags below") %>
        </p>
        <.action
          type="link"
          patch={~p"/school/students/settings?new=true"}
          icon_name="hero-plus-circle-mini"
        >
          <%= gettext("New tag") %>
        </.action>
      </.action_bar>
      <%= if @has_student_tags do %>
        <.responsive_container
          phx-hook="Sortable"
          id="student-tags"
          class="p-4"
          data-sortable-handle=".sortable-handle"
          phx-update="ignore"
        >
          <.dragable_card
            :for={{dom_id, tag} <- @streams.student_tags}
            id={"sortable-#{dom_id}"}
            class="mt-4 first:mt-0"
          >
            <div class="flex items-center gap-4 p-6">
              <.badge color_map={tag}>
                <%= tag.name %>
              </.badge>
              <.action type="link" patch={~p"/school/students/settings?edit=#{tag.id}"} theme="subtle">
                <%= gettext("Edit") %>
              </.action>
            </div>
          </.dragable_card>
        </.responsive_container>
      <% else %>
        <div class="p-10">
          <.empty_state><%= gettext("No student tags created yet") %></.empty_state>
        </div>
      <% end %>
      <.live_component
        :if={@student_tag}
        module={StudentTagFormOverlayComponent}
        id="student-tag-form-overlay"
        tag={@student_tag}
        title={@student_tag_overlay_title}
        on_cancel={JS.patch(~p"/school/students/settings")}
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
  def update(%{action: {StudentTagFormOverlayComponent, {action, _tag}}}, socket)
      when action in [:created, :updated, :deleted] do
    message =
      case action do
        :created -> gettext("Tag created successfully")
        :updated -> gettext("Tag updated successfully")
        :deleted -> gettext("Tag deleted successfully")
      end

    nav_opts = [
      put_flash: {:info, message},
      push_navigate: [to: ~p"/school/students/settings"]
    ]

    {:ok, delegate_navigation(socket, nav_opts)}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> initialize()
      |> assign_student_tag()

    {:ok, socket}
  end

  defp initialize(%{assigns: %{initialized: false}} = socket) do
    socket
    |> stream_student_tags()
    |> assign(:initialized, true)
  end

  defp initialize(socket), do: socket

  defp stream_student_tags(socket) do
    school_id = socket.assigns.current_user.current_profile.school_id
    student_tags = StudentTags.list_student_tags(school_id: school_id)

    socket
    |> stream(:student_tags, student_tags)
    |> assign(:has_student_tags, length(student_tags) > 0)
    |> assign(:student_tags_ids, Enum.map(student_tags, &"#{&1.id}"))
  end

  defp assign_student_tag(%{assigns: %{params: %{"new" => "true"}}} = socket) do
    student_tag = %Tag{
      school_id: socket.assigns.current_user.current_profile.school_id
    }

    socket
    |> assign(:student_tag, student_tag)
    |> assign(:student_tag_overlay_title, gettext("New student tag"))
  end

  defp assign_student_tag(%{assigns: %{params: %{"edit" => tag_id}}} = socket) do
    if tag_id in socket.assigns.student_tags_ids do
      student_tag = StudentTags.get_student_tag!(tag_id)

      socket
      |> assign(:student_tag, student_tag)
      |> assign(:student_tag_overlay_title, gettext("Edit student tag"))
    else
      assign(socket, :student_tag, nil)
    end
  end

  defp assign_student_tag(socket), do: assign(socket, :student_tag, nil)

  # event handlers

  @impl true
  # view Sortable hook for payload info
  def handle_event("sortable_update", payload, socket) do
    %{
      "oldIndex" => old_index,
      "newIndex" => new_index
    } = payload

    {changed_id, rest} = List.pop_at(socket.assigns.student_tags_ids, old_index)
    student_tags_ids = List.insert_at(rest, new_index, changed_id)

    # the inteface was already updated (optimistic update)
    # just persist the new order
    StudentTags.update_student_tags_positions(student_tags_ids)

    socket =
      socket
      |> assign(:student_tags_ids, student_tags_ids)

    {:noreply, socket}
  end
end
