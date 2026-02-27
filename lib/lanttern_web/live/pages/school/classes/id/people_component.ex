defmodule LantternWeb.ClassLive.PeopleComponent do
  use LantternWeb, :live_component

  alias LantternWeb.ClassLive.{StaffMembersComponent, StudentsComponent}
  import LantternWeb.NavigationComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto">
      <.collapsible_section
        id="staff-section"
        title={gettext("Staff Members")}
        initial_expanded={true}
      >
        <.live_component
          module={StaffMembersComponent}
          id="staff-members-content"
          class={@class}
          current_user={@current_user}
          params={@params}
        />
      </.collapsible_section>

      <.collapsible_section
        id="students-section"
        title={gettext("Students")}
        initial_expanded={true}
      >
        <.live_component
          module={StudentsComponent}
          id="students-content"
          class={@class}
          current_user={@current_user}
          is_school_manager={@is_school_manager}
          params={@params}
        />
      </.collapsible_section>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end
end
